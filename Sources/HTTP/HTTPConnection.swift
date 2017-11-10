//
//  HTTPConnection.swift
//  HTTP
//
//  Created by Helge Hess on 22.10.17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import Foundation
import Dispatch
import CHTTPParser

/// A connection to a single HTTP client.
///
/// The connection owns a queue which is used to synchronize all access to the
/// API. Writers and `finishedProcessing` callbacks alike.
///
/// Back-pressure is supported. That is, until the body processor of a handler
/// marks a chunk as processed, the connection suspends reading more data.
/// Note that some reads might still be in-flight and will be buffered until
/// the connection is resumed again.
///
/// Since HTTP clients can pipeline calls, a connection can run multiple
/// handlers at the same time. To maintain proper response ordering,
/// response-writer objects will be 'corked' until the responses ahead of them
/// are completely written out.
///
internal class HTTPConnection : CustomStringConvertible {

  /// The `HTTPServer` which created the connection. If the connection shuts
  /// down, it will unregister from that server.
  private  let server  : HTTPServer
  
  /// Serialized access to the state of the connection. Everything needs to
  /// happen on this queue. It is the `DispatchQueue.main` for a handler.
  internal let queue   : DispatchQueue

  /// The socket.
  private  let channel : DispatchIO
  
  /// User-level closure responsible for handling any incoming requests. Passed
  /// in from `HTTPServer`. The connection maintains a strong reference to it,
  /// until it is gone.
  private  let requestHandler : HTTPRequestHandler
  
  /// The body handler as returned by the `HTTPRequestHandler`. If the handler
  /// returns `.discard`, this will be nil and all content will be dropped.
  /// At any time, there can only be one `bodyHandler`.
  private  var bodyHandler    : HTTPBodyHandler?
  
  /// The array of active writers. There can be many due to HTTP pipelining.
  /// I.e. a new request can arrive while the previous request is still being
  /// delivered to the client.
  /// HTTP/1 requires strict ordering of responses. That is, the first response
  /// must be fully sent before the next can be sent. To support that, inactive
  /// writers are 'corked' and will be flushed when they are due.
  private var writers = [ HTTPResponseWriter ]()
    // FIXME: make this a linked list
  
  internal init(fd             : Int32,
                queue          : DispatchQueue,
                requestHandler : @escaping HTTPRequestHandler,
                server         : HTTPServer)
  {
    self.server         = server
    self.queue          = queue
    self.requestHandler = requestHandler
    
    self.channel = DispatchIO(type: .stream, fileDescriptor: fd, queue: queue) {
      error in
      close(fd)
    }
    channel.setLimit(lowWater: 1)
    
    wireUpParser()
  }
  
  /// Defines whether the receiving side of the socket is still open.
  /// Note: some content (and EOF) could still be buffered!
  private var isReadSideOpen = true {
    didSet {
      assert(isReadSideOpen == false, "unexpected value set: \(self)")
      if writers.isEmpty { _connectionHasFinished() }
    }
  }
  
  /// Close the receiving side of the channel. Note that we may still have stuff
  /// in the read buffer!
  private func closeReadSide() {
    guard isReadSideOpen else { return }
    isReadSideOpen = false
    shutdown(channel.fileDescriptor, SHUT_RD)
  }
  
  private var isSuspended = true // started in suspended state
  private var isReading   = false
  private var readBuffer  : DispatchData? = nil
  private var bufferedEOF = false
  
  internal func suspend() {
    assert(!isSuspended, "suspending suspended connection")
    if isSuspended { return }

    // Note: The channel itself is not actually suspended, we wait until the
    //       current `read` is through.
    isSuspended = true
  }
  internal func resume() {
    assert(isSuspended, "resuming running connection")
    if !isSuspended { return }
    
    guard isReadSideOpen else { return }
    isSuspended = false
    
    // flush read buffer
    if let readBuffer = readBuffer {
      self.readBuffer = nil
      
      // Note: this can trigger suspend/resume!
      readBuffer.enumerateBytes { bptr, _, shouldStop in
        if !feedParser(bptr) {
          closeReadSide()
          shouldStop = true
        }
      }
    }
    if bufferedEOF {
      bufferedEOF = false
      if !feedParser(nil) { closeReadSide() }
    }
    
    // Careful here. Additional suspend/resume calls may have happened. Or the
    // socket may have been closed.
    if isReadSideOpen {
      maybeReadMore()
    }
  }
  
  /// Feed the parser w/ more data. Pass in nil to signal EOF/shutdown.
  @inline(__always)
  private func feedParser(_ data: UnsafeBufferPointer<UInt8>?) -> Bool {
    var hitParserError = false
    
    if let data = data {
      data.baseAddress?.withMemoryRebound(to: Int8.self, capacity: data.count) {
        let rc = http_parser_execute(&self.httpParser,
                                     &self.httpParserSettings,
                                     $0, data.count)
        guard rc == data.count else { // error
          hitParserError = true
          return
        }
      }
    }
    else {
      let rc = http_parser_execute(&self.httpParser,
                                   &self.httpParserSettings,
                                   nil, 0)
      hitParserError = rc != 0
    }
    return !hitParserError
  }
  
  private let readBufferSize = 4096

  internal func maybeReadMore() {
    assert(isReadSideOpen, "starting, but reading-side is not open?")
    guard !isReading     else { return } // still reading
    guard isReadSideOpen else { return }
    
    isReading = true
    channel.read(offset: 0, length: readBufferSize, queue: queue) {
      // Note: This is retaining the connection! So if we stop, we also need to
      //       stop this read-call! (it should error out if we close the read
      //       side)
      done, data, error in
      
      assert(self.isReading, "read callback called, but not reading anymore?")
      guard self.isReadSideOpen else { return }
      
      if done {
        self.isReading = false
      }
      
      var hitParseError = false
      
      if error == 0, let data = data {
        if done && data.isEmpty { // error = 0, empty data, + done means EOF
          if self.isSuspended {
            self.bufferedEOF = true
          }
          else {
            hitParseError = !self.feedParser(nil)
          }
          self.isReadSideOpen = false
        }
        else if self.isSuspended {
          if self.readBuffer == nil { self.readBuffer = data }
          else { self.readBuffer!.append(data) }
        }
        else {
          data.enumerateBytes { bptr, _, stop in
            if !self.feedParser(bptr) {
              hitParseError = true
              stop = true
            }
          }
        }
      }
      
      if error != 0 || hitParseError {
        self.abortOnError()
      }
      else if done && self.isReadSideOpen && !self.isSuspended {
        // continue reading next block
        self.maybeReadMore()
      }
    }
  }
  
  /// A hard close, makes no sense to continue anything once we got a read
  /// error.
  func abortOnError() {
    closeReadSide()
    channel.close(flags: .stop)
    bodyHandler = nil
    for writer in writers {
      writer.abort()
    }
    writers = []
    
    _connectionHasFinished()
  }
  
  internal func serverWillStop() { // sent by server on server queue
    queue.async { self._serverWillStop() }
  }
  private func _serverWillStop() {
    // TODO: set some flag, teardown
    // Note: the server object won't go away, we have a hard retain on it.
  }
  
  /// Called by the writer if it is done and all queued writes have completed.
  internal func _responseWriterIsDone(_ writer: HTTPResponseWriter) {
    let isFirst = writers.first === writer
    
    guard isFirst else {
      assert(writers.first == nil || writers.first === writer,
             "writer done, but it is not the head writer? \(self) \(writer)")
      return
    }
    
    if let idx = writers.index(where: { $0 === writer }) {
      // break retain cycle
      writers.remove(at: idx)
    }
    else {
      assert(false, "did not find writer which went done: \(self)")
    }
    
    // activate next writer in the pipeline
    if let newFirst = writers.first {
      newFirst.channel = channel
    }

    // Close connection if the read side is down, and no writers need to write
    if writers.isEmpty && !isReadSideOpen { // && keep alive?
      // we are done?
      _connectionHasFinished()
    }
  }
  
  private var didFinish = false
  private func _connectionHasFinished() {
    guard !didFinish else { return }
    didFinish = true
    server._connectionIsDone(self)
  }
  
  
  // MARK: - Parser
  
  // This is inline for speedz. We could separate it out, but that is harder
  // than it looks to get fast. Because you can't mix C closures w/ generics
  // and using a protocol is not exactly fast either.

  @inline(__always)
  private final func headersCompleted(parser: UnsafeMutablePointer<http_parser>) {
    // this is a little lame
    let method  : HTTPMethod
    let version : HTTPVersion
    
    method   = http_method(rawValue: parser.pointee.method).getMethod()
    version  = HTTPVersion(major: Int(parser.pointee.http_major),
                           minor: Int(parser.pointee.http_minor))
    
    #if false // TODO: do the right thing here
      let keepAlive        = http_should_keep_alive(parser) == 1
      let upgradeRequested = parser.pointee.upgrade == 1
    #endif
    
    // create request object
    
    let request  = HTTPRequest(method: method, target: parsedURL ?? "",
                               httpVersion: version, headers: parsedHeaders)
    resetHeaderParseState()
    
    // create response object
    
    let response = HTTPResponseWriter(requestVersion: version,
                                      connection: self, queue: queue)
    if writers.isEmpty { // yay, we are active
      response.channel = channel
    }
    writers.append(response)
    
    // run user-level handler closure
    
    let bh = requestHandler(request, response, queue)
    switch bh {
      case .discardBody:              bodyHandler = nil
      case .processBody(let handler): bodyHandler = handler
    }
  }
  
  /// The body handler set the 'stop' flag.
  private func bodyHandlerRequestedStop() {
    // Note: This is the physical close. We still may have stuff in the
    //       buffer. Drop it. Do NOT resume.
    readBuffer = nil
    closeReadSide() // physical close
  }
  
  /// The number of `finishedProcessing` callbacks we are waiting for.
  private var inFlightBodySends = 0
  
  @inline(__always)
  private final func handleBodyChunk(_ chunk: UnsafeRawBufferPointer) {
    guard let bodyHandler = bodyHandler else { return } // .discard
    
    var wasStopped = false, doneGotCalled = false
    
    let doneCB = { // The done callback MUST run on the handler-queue
      doneGotCalled = true
      guard !wasStopped else { return } // already handled
      
      self.inFlightBodySends -= 1
      if self.inFlightBodySends == 0 { self.resume() }
    }
    
    let data = DispatchData(bytes: chunk)
                 // copies (we kinda need to, for async)
    
    if inFlightBodySends == 0 { self.suspend() } // stop reading from socket
    inFlightBodySends += 1
    
    var shouldStop = false
    bodyHandler(.chunk(data: data, finishedProcessing: doneCB),
                &shouldStop)
    
    if shouldStop {
      self.bodyHandler = nil
      wasStopped = true
      if !doneGotCalled {
        self.inFlightBodySends -= 1
      }
      
      bodyHandlerRequestedStop()
    }
  }
  
  @inline(__always)
  private final func messageCompleted() {
    // The request has been fully parsed (including all body data).
    
    var stop = false
    bodyHandler?(.end, &stop)
    
    // TBD: Do we need to hang on to the body handler until the response is
    //      done? I don't think so. If we want to, retain it in the handler.
    bodyHandler = nil
    
    if stop {
      bodyHandlerRequestedStop()
    }
  }

  
  /// Holds the bytes that come from the CHTTPParser until we have enough of
  /// them to do something with it
  private var parserBuffer = Data()
  
  /// HTTP Parser
  private var httpParser         = http_parser()
  private var httpParserSettings = http_parser_settings()
  
  private var lastCallBack   = LastCallback.none
  private var lastHeaderName : HTTPHeaders.Name?
  private var parsedHeaders  = HTTPHeaders()
  private var parsedURL      : String?
  
  enum LastCallback { case none, field, value, url }
  
  private func resetHeaderParseState() {
    lastCallBack   = .none
    lastHeaderName = nil
    parsedURL      = nil
    parsedHeaders  = HTTPHeaders() // TBD: hm. Maybe do this differently (reuse)
    parserBuffer.removeAll()
  }
  
  private func wireUpParser() {
    // Set up all the callbacks for the CHTTPParser library.
    httpParserSettings.on_message_begin = { parser -> Int32 in
      guard let me = HTTPConnection.getSelf(parser: parser) else { return 0 }
      me.resetHeaderParseState()
      return 0
    }
    httpParserSettings.on_message_complete = { parser -> Int32 in
      guard let me = HTTPConnection.getSelf(parser: parser) else { return 0 }
      me.messageCompleted()
      me.resetHeaderParseState() // should be done already
      return 0
    }
    
    httpParserSettings.on_headers_complete = { parser -> Int32 in
      guard let me = HTTPConnection.getSelf(parser: parser) else { return 0 }
      var dummy : CChar = 0
      _ = me.processDataCB(newState: .none, p: &dummy, len: 0) // finish up
      
      me.headersCompleted(parser: parser!)
      return 0
    }
    
    httpParserSettings.on_header_field = { (parser, chunk, length) -> Int32 in
      guard let me = HTTPConnection.getSelf(parser: parser) else { return 0 }
      return me.processDataCB(newState: .field, p: chunk, len: length)
    }
    
    httpParserSettings.on_header_value = { (parser, chunk, length) -> Int32 in
      guard let me = HTTPConnection.getSelf(parser: parser) else { return 0 }
      return me.processDataCB(newState: .value, p: chunk, len: length)
    }
    
    httpParserSettings.on_body = { (parser, chunk, length) -> Int32 in
      guard let me = HTTPConnection.getSelf(parser: parser) else { return 0 }
      me.handleBodyChunk(UnsafeRawBufferPointer(start: chunk, count: length))
      return 0
    }
    
    httpParserSettings.on_url = { (parser, chunk, length) -> Int32 in
      guard let me = HTTPConnection.getSelf(parser: parser) else { return 0 }
      return me.processDataCB(newState: .url, p: chunk, len: length)
    }
    
    http_parser_init(&httpParser, HTTP_REQUEST)
    self.httpParser.data = Unmanaged.passUnretained(self).toOpaque()
  }
  
  private final func processDataCB(newState s: LastCallback,
                                   p: UnsafePointer<CChar>?, len: size_t)
                     -> Int32
  {
    let newState = s
    if lastCallBack == newState { // continue value
      if let p = p {
        let bp = UnsafeBufferPointer(start: p, count: len)
        parserBuffer.append(bp)
      }
      return 0 // done already. state is the same
    }
    
    switch lastCallBack { // != newState!
      case .url: // finished URL
        if !parserBuffer.isEmpty {
          parsedURL = String(data: parserBuffer, encoding: .utf8)
        }
      
      case .field: // last field was a name
        lastHeaderName = headerNameForData(parserBuffer)
      
      case .value: // last field was a value, now something new
        let value = String(data: parserBuffer, encoding: .utf8)
        #if DEBUG
          assert(lastHeaderName != nil, "header value w/o a name?")
          assert(value          != nil, "header value missing?")
        #endif
        
        // TBD: Uh, oh, why the need to create a literal here??
        if let name = lastHeaderName, let value = value {
          parsedHeaders.append([name: value])
        }
        lastHeaderName = nil
      
      default:
        break
    }
    
    // store new data & state
    parserBuffer.removeAll()
    lastCallBack = newState
    if len > 0, let p = p {
      let bp = UnsafeBufferPointer(start: p, count: len)
      parserBuffer.append(bp)
    }
    return 0
  }
  
  @inline(__always)
  static func getSelf(parser: UnsafeMutablePointer<http_parser>?)
              -> HTTPConnection?
  {
    guard let pointee = parser?.pointee.data else { return nil }
    return Unmanaged<HTTPConnection>
             .fromOpaque(pointee)
             .takeUnretainedValue()
  }
  
  
  // MARK: - CustomStringConvertible
  
  var description : String {
    var ms = "<HTTPConnection:"
    
    ms += " fd=\(channel.fileDescriptor)"
    
    if !isReadSideOpen {
      ms += " read-closed"
    }
    
    if let readBuffer = readBuffer {
      ms += " buffered=#\(readBuffer.count)"
      if bufferedEOF { ms += "/+EOF" }
    }
    else if bufferedEOF {
      ms += " buffered-EOF"
    }
    
    if bodyHandler != nil { ms += " body" }
    
    if writers.isEmpty {
      ms += " no-writers"
    }
    else if writers.count == 1 {
      ms += " writer=\(writers[0])"
    }
    else {
      ms += " headwriter=\(writers[0]) of #\(writers.count)"
    }
    
    ms += ">"
    return ms
  }
}


// MARK: - Static Strings

@inline(__always)
fileprivate func headerNameForData(_ data: Data) -> HTTPHeaders.Name? {
  guard !data.isEmpty else { return nil }
  // TODO: reuse header values by matching the data via memcmp(), maybe first
  //       switch on length, compare c0
  guard let s = String(data: data, encoding: .utf8) else { return nil }
  return HTTPHeaders.Name(s)
}

fileprivate extension http_method {
  
  @inline(__always)
  func getMethod() -> HTTPMethod {
    // We have this, so that we can use static strings most of the time!
    switch self {
      case HTTP_DELETE:      return HTTPMethod.delete
      case HTTP_GET:         return HTTPMethod.get
      case HTTP_HEAD:        return HTTPMethod.head
      case HTTP_POST:        return HTTPMethod.post
      case HTTP_PUT:         return HTTPMethod.put
      /* pathological */
      case HTTP_CONNECT:     return HTTPMethod.connect
      case HTTP_OPTIONS:     return HTTPMethod.options
      case HTTP_TRACE:       return HTTPMethod.trace
      /* WebDAV */
      case HTTP_COPY:        return HTTPMethod.copy
      case HTTP_LOCK:        return HTTPMethod.lock
      case HTTP_MKCOL:       return HTTPMethod.mkcol
      case HTTP_MOVE:        return HTTPMethod.move
      case HTTP_PROPFIND:    return HTTPMethod.propfind
      case HTTP_PROPPATCH:   return HTTPMethod.proppatch
      case HTTP_SEARCH:      return HTTPMethod.search
      case HTTP_UNLOCK:      return HTTPMethod.unlock
      case HTTP_BIND:        return HTTPMethod.bind
      case HTTP_REBIND:      return HTTPMethod.rebind
      case HTTP_UNBIND:      return HTTPMethod.unbind
      case HTTP_ACL:         return HTTPMethod.acl
      /* subversion */
      case HTTP_REPORT:      return HTTPMethod.report
      case HTTP_MKACTIVITY:  return HTTPMethod.mkactivity
      case HTTP_CHECKOUT:    return HTTPMethod.checkout
      case HTTP_MERGE:       return HTTPMethod.merge
      /* upnp */
      case HTTP_MSEARCH:     return HTTPMethod.msearch
      case HTTP_NOTIFY:      return HTTPMethod.notify
      case HTTP_SUBSCRIBE:   return HTTPMethod.subscribe
      case HTTP_UNSUBSCRIBE: return HTTPMethod.unsubscribe
      /* RFC-5789 */
      case HTTP_PATCH:       return HTTPMethod.patch
      case HTTP_PURGE:       return HTTPMethod.purge
      /* CalDAV */ // - Helge was here
      case HTTP_MKCALENDAR:  return HTTPMethod.mkcalendar
      /* RFC-2068, section 19.6.1.2 */
      case HTTP_LINK:        return HTTPMethod.link
      case HTTP_UNLINK:      return HTTPMethod.unlink
      
      default:
        // TBD: - should return nil instead?
        return HTTPMethod(String(cString: http_method_str(self)))
    }
  }
}
