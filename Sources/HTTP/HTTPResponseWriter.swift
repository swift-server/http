//
//  HTTPResponseWriter.swift
//  HTTP
//
//  Created by Helge Hess on 22.10.17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//
//  Copyright (c) 2017 Swift Server API project authors
//  Licensed under Apache License v2.0 with Runtime Library Exception
//

import Foundation
import Dispatch

/// HTTPResponseWriter provides functions to create an HTTP response
///
/// ## Queueing
///
/// All functions expect to be called on the queue of the request handler (which
/// is passed in as an argument).
/// For example, if you dispatch to a different queue, you need to dispatch back
/// the the handler queue for writes:
///
///     server.start { request, response, queue in
///       backgroundQueue.async {
///         // do expensive processing ...
///         let result = 42
///         // bounce back to the handler queue to write:
///         queue.async {
///           response.write("The answer is: \(result)")
///           response.done()
///         }
///     }
///
public class HTTPResponseWriter : CustomStringConvertible {
  
  public enum Error : Swift.Error {
    case connectionGone // unexpected!
    case encodingError
    case headersWrittenAlready
    case writeFailed(Int32)
    case writerIsDone
  }

  /// The same queue as the `HTTPConnection` queue.
  /// Separate variable because `connection` is an Optional.
  final private let queue : DispatchQueue
    // TODO: maybe the connection should not be an optional
  
  /// The connection owning the writer.
  final private var connection : HTTPConnection?
  // TODO: maybe the connection should not be an optional.
  
  final var channel : DispatchIO? = nil {
    didSet {
      if channel != nil, let buffer = buffer, !buffer.isEmpty {
        let done = self.bufferDone
        self.buffer     = nil
        self.bufferDone = nil
        
        self._write(buffer, completion: done ?? {_ in })
      }
    }
  }

  private var isDone = false
  
  /// The write buffer.
  /// All writes and the done callbacks are merged into a single call. TBD
  private var buffer     : DispatchData? = nil
  
  /// The `done` callbacks of the write buffer.
  /// All writes and the done callbacks are merged into a single call. TBD
  private var bufferDone : ((Result) -> Void)? = nil
  
  /// The HTTP version requested by the client.
  private var requestVersion : HTTPVersion
  
  private var clientRequestedKeepAlive = true
    // TODO: I think we should use the HTTPParser setting for this.
  private var isChunked                = true
  

  internal init(requestVersion : HTTPVersion,
                connection     : HTTPConnection,
                queue          : DispatchQueue)
  {
    self.connection     = connection
    self.queue          = queue
    self.requestVersion = requestVersion
  }
  
  private var headersSent = false
  
  /// Writer function to create the headers for an HTTP response
  ///
  /// Queue: You need to call this on the queue that was passed into the
  ///        handler.
  ///
  /// - Parameter status:     The status code to include in the HTTP response
  /// - Parameter headers:    The HTTP headers to include in the HTTP response
  /// - Parameter completion: Closure that is called when the HTTP headers have
  ///                         been written to the HTTP respose
  public func writeHeader(status: HTTPResponseStatus, headers: HTTPHeaders,
                          completion: @escaping (Result) -> Void)
  {
    guard !self.headersSent else {
      completion(Result.error(Error.headersWrittenAlready))
      return
    }
    guard self.gotDone == nil else {
      completion(.error(Error.writerIsDone))
      return
    }

    // TBD: is it more efficient to add up to a DispatchData or Data?
    var header = "HTTP/1.1 \(status.code) \(status.reasonPhrase)\r\n"
    
    let isContinue = status == .continue
    
    var headers = headers
    if !isContinue {
      // FIXME: This has extra side-effects, don't.
      self.adjustHeaders(status: status, headers: &headers)
    }
    for (key, value) in headers {
      // TODO encode value using [RFC5987]
      header += "\(key): \(value)\r\n"
    }
    header.append("\r\n")
    
    // FIXME headers are US-ASCII, anything else should be encoded using
    // [RFC5987] some lines above
    // TODO use requested encoding if specified
    guard let data = DispatchData.fromString(header) else {
      completion(Result.error(Error.encodingError))
      return
    }
    
    if !isContinue {
      self.headersSent = true
    }
    
    self._write(data, completion: completion)
  }
  
  /// Writer function to write a trailer header as part of the HTTP response
  ///
  /// Queue: You need to call this on the queue that was passed into the
  ///        handler.
  ///
  /// - Parameter trailers: The trailers to write as part of the HTTP response
  /// - Parameter completion: Closure that is called when the trailers has been written to the HTTP response
  /// This is not currently implemented
  public func writeTrailer(_ trailers: HTTPHeaders,
                           completion: @escaping (Result) -> Void)
  {
    // TODO
    // - render trailers into a DispatchData we can pass on
    // - fail when done
  }
  
  /// Writer function to write data to the body of the HTTP response
  ///
  /// Queue: You need to call this on the queue that was passed into the
  ///        handler.
  ///
  /// - Parameter data: The data to write as part of the HTTP response
  /// - Parameter completion: Closure that is called when the data has been written to the HTTP response
  public func writeBody(_ data: DispatchData,
                        completion: @escaping (Result) -> Void)
  {
    guard self.gotDone == nil else {
      completion(.error(Error.writerIsDone))
      return
    }
    
    if !self.headersSent {
      self.writeHeader(status: .ok, headers: HTTPHeaders()) {
        result in
        
        if case .error = result {
          completion(result)
          return
        }
        
        self._write(self.isChunked ? data.withHTTPChunkedFrame : data,
                    completion: completion)
      }
    }
    else {
      self._write(self.isChunked ? data.withHTTPChunkedFrame : data,
                  completion: completion)
    }
  }
  
  /// Writer function to write data to the body of the HTTP response
  ///
  /// Queue: You need to call this on the queue that was passed into the
  ///        handler.
  ///
  /// - Parameter data: The data to write as part of the HTTP response
  /// - Parameter completion: Closure that is called when the data has been written to the HTTP response
  public func writeBody(_ data: UnsafeHTTPResponseBody,
                        completion: @escaping (Result) -> Void)
  {
    // Note: Using this is lame, it requires a copy. Be smart, use DispatchData.
    data.withUnsafeBytes { rbp in
      let data = DispatchData(bytes: rbp)
      writeBody(data, completion: completion)
    }
  }
  
  /// This is set if `done` was called on the writer. It holds the completion
  /// callback for that done function.
  private var gotDone : ((Result) -> Void)? = nil
  
  /// Writer function to complete the HTTP response.
  ///
  /// Queue: You need to call this on the queue that was passed into the
  ///        handler.
  ///
  /// - Parameter completion: Closure that is called when the HTTP response has
  ///                         been completed
  public func done(completion: @escaping ( Result ) -> Void) {
    guard self.gotDone == nil && !isDone else {
      completion(.error(Error.writerIsDone))
      return
    }
    isDone  = true
    gotDone = completion
    
    // send chunkedEnd
    if self.isChunked {
      self._write(DataChunks.chunkedEnd) { result in }
        // this calls reallyDone as part of gotDone
    }
    else if self.pendingWrites == 0 {
      self._reallyDone()
    }
  }
  
  /// All writes have completed
  private func _reallyDone(result: Result = .ok) {
    withExtendedLifetime(self) { // TBD: necessary?
      channel    = nil
      connection?._responseWriterIsDone(self)
      connection = nil // break cycle (TBD: do we really have to?)
      
      if let done = gotDone {
        gotDone = nil
        done(result)
      }
    }
  }
  
  /// abort: Abort the HTTP response
  public func abort() {
    // TODO:
    // - do we really need this? Or is `stop` in the body parser enough? I guess
    //   it is kinda nice
  }
  
  private final var pendingWrites = 0
  
  private func _write(_ data: DispatchData,
                      completion: @escaping (Result) -> Void)
  {
    if let channel = channel {
      pendingWrites += 1
      
      channel.write(offset: 0, data: data, queue: queue) {
        done, data, error in
        
        if done { self.pendingWrites -= 1 }
        
        if error != 0 {
          let result = Result.error(Error.writeFailed(error))
          completion(result)
          self._reallyDone(result: result)
          return
        }
        
        if done {
          completion(.ok)
        }
        
        if self.gotDone != nil && self.pendingWrites == 0 {
          self._reallyDone()
        }
      }
    }
    else { // we are corked. queue writes which don't wait for completion
      // TBD: We could also queue them as individual writes, which may have
      //      some latency advantages, but well.
      if buffer != nil { buffer!.append(data) }
      else { buffer = data }
      
      if let old = bufferDone {
        bufferDone = { result in
          old(result)
          completion(result)
        }
      }
      else { bufferDone = completion }
    }
  }
  
  private func adjustHeaders(status: HTTPResponseStatus,
                             headers: inout HTTPHeaders)
  {
    for header in status.suppressedHeaders {
      headers[header] = nil
    }
    
    if headers[.contentLength] != nil {
      headers[.transferEncoding] = "identity"
    }
    else if requestVersion >= HTTPVersion(major: 1, minor: 1) {
      switch headers[.transferEncoding] {
        case .some("identity"): // identity without content-length
          clientRequestedKeepAlive = false
        case .some("chunked"):
          isChunked = true
        default:
          isChunked = true
          headers[.transferEncoding] = "chunked"
      }
    }
    else {
      // HTTP 1.0 does not support chunked
      clientRequestedKeepAlive = false
      headers[.transferEncoding] = nil
    }
    
    headers[.connection] = clientRequestedKeepAlive ? "Keep-Alive" : "Close"
  }

  
  // MARK: - CustomStringConvertible
  
  public var description : String {
    // requestVersion
    var ms = "<HTTPResponseWriter:"
    
    if connection == nil { ms += " NO-CON" }
    if isDone            { ms += " DONE"   }
    
    if let channel = channel {
      ms += " first[#\(channel.fileDescriptor)]"
    }
    else {
      if let buffer = buffer, !buffer.isEmpty {
        ms += isDone ? " buffered" : " buffering"
        ms += "[#\(buffer.count)]"
      }
      else if !isDone {
        ms += " buffering"
      }
    }
    
    if isChunked                { ms += " chunked"    }
    if clientRequestedKeepAlive { ms += " keep-alive" }

    ms += ">"
    return ms
  }
}


// MARK: - Helpers

fileprivate enum DataChunks {

  static let crlf : DispatchData = {
    let b : [ UInt8 ] = [ 13, 10 ]
    return b.withUnsafeBytes { DispatchData(bytes: $0) }
  }()
  
  static let chunkedEnd : DispatchData = {
    let b : [ UInt8 ] = [ 48 /*0*/, 13, 10, 13, 10 ]
    return b.withUnsafeBytes { DispatchData(bytes: $0) }
  }()
}

fileprivate extension DispatchData {
  
  static func fromString(_ s: String) -> DispatchData? {
    // vs: let utf8 = marker.utf8CString (but included \0)
    guard let data = s.data(using: .utf8) else { return nil }
    return data.withUnsafeBytes { DispatchData(bytes: $0) }
      // TODO: stupid copying, do this better
  }
  
  var withHTTPChunkedFrame : DispatchData {
    let count = self.count
    guard count > 0 else { return self }
    
    var result = count.chunkLenDispatchData // TBD: cache/global common sizes?
    result.append(self)
    result.append(DataChunks.crlf)
    return result
  }
  
}

fileprivate extension FixedWidthInteger {
  
  var chunkLenDispatchData : DispatchData {
    // thanks go to @regexident
    var bigEndian = self.bigEndian
    
    return Swift.withUnsafeBytes(of: &bigEndian) { bp in
      let maxlen = bitWidth / 8 * 2
      let cstr   = UnsafeMutablePointer<UInt8>.allocate(capacity: maxlen + 3)
      var idx    = 0
      
      for byte in bp {
        if idx == 0 && byte == 0 { continue }
        
        func hexFromNibble(_ nibble: UInt8) -> UInt8 {
          let cA   : UInt8 = 65
          let c0   : UInt8 = 48
          let corr : UInt8 = cA - c0 - 10
          let c    = nibble + c0
          let mask : UInt8 = (nibble > 9) ? 0xff : 0x00;
          return c + (mask & corr)
        }
        
        cstr[idx] = hexFromNibble((byte & 0b11110000) >> 4); idx += 1
        cstr[idx] = hexFromNibble((byte & 0b00001111));      idx += 1
      }
      if idx == 0 {
        let c0 : UInt8 = 48
        cstr[idx] = c0; idx += 1
      }
      cstr[idx] = 13; idx += 1
      cstr[idx] = 10; idx += 1
      cstr[idx] = 0 // having a valid cstr in memory is well worth a byte
      
      let bbp = UnsafeRawBufferPointer(start: cstr, count: idx)
      return DispatchData(bytesNoCopy: bbp, deallocator: .free)
    }
  }
}

