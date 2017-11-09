// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import CHTTPParser
import Foundation
import Dispatch

/// Class that wraps the CHTTPParser and calls the `HTTPRequestHandler` to get the response
/// :nodoc:
public class StreamingParser: HTTPResponseWriter {

    let handle: HTTPRequestHandler

    /// Time to leave socket open waiting for next request to start
    public let keepAliveTimeout: TimeInterval

    /// Flag to track if the client wants to send consecutive requests on the same TCP connection
    var clientRequestedKeepAlive = false

    /// Tracks when socket should be closed. Needs to have a lock, since it's updated often
    private let _keepAliveUntilLock = DispatchSemaphore(value: 1)
    private var _keepAliveUntil: TimeInterval?
    public var keepAliveUntil: TimeInterval? {
        get {
            _keepAliveUntilLock.wait()
            defer {
                 _keepAliveUntilLock.signal()
            }
            return _keepAliveUntil
        }
        set {
            _keepAliveUntilLock.wait()
            defer {
                _keepAliveUntilLock.signal()
            }
            _keepAliveUntil = newValue
        }
    }

    /// Optional delegate that can tell us how many connections are in-flight.
    public weak var connectionCounter: CurrentConnectionCounting?

    /// Holds the bytes that come from the CHTTPParser until we have enough of them to do something with it
    var parserBuffer: Data?

    /// HTTP Parser
    var httpParser = http_parser()
    var httpParserSettings = http_parser_settings()

    /// Block that takes a chunk from the HTTPParser as input and writes to a Response as a result
    var httpBodyProcessingCallback: HTTPBodyProcessing?

    //Note: we want this to be strong so it holds onto the connector until it's explicitly cleared
    /// Protocol that we use to send data (and status info) back to the Network layer
    public var parserConnector: ParserConnecting?

    ///Flag to track whether our handler has told us not to call it anymore
    private let _shouldStopProcessingBodyLock = DispatchSemaphore(value: 1)
    private var _shouldStopProcessingBody: Bool = false
    private var shouldStopProcessingBody: Bool {
        get {
            _shouldStopProcessingBodyLock.wait()
            defer {
                _shouldStopProcessingBodyLock.signal()
            }
            return _shouldStopProcessingBody
        }
        set {
            _shouldStopProcessingBodyLock.wait()
            defer {
                _shouldStopProcessingBodyLock.signal()
            }
            _shouldStopProcessingBody = newValue
        }
    }

    var lastCallBack = CallbackRecord.idle
    var lastHeaderName: String?
    var parsedHeaders = HTTPHeaders()
    var parsedHTTPMethod: HTTPMethod?
    var parsedHTTPVersion: HTTPVersion?
    var parsedURL: String?

    /// Is the currently parsed request an upgrade request?
    public private(set) var upgradeRequested = false

    /// Class that wraps the CHTTPParser and calls the `HTTPRequestHandler` to get the response
    ///
    /// - Parameter handler: function that is used to create the response
    public init(handler: @escaping HTTPRequestHandler, connectionCounter: CurrentConnectionCounting? = nil, keepAliveTimeout: Double = 5.0) {
        self.handle = handler
        self.connectionCounter = connectionCounter
        self.keepAliveTimeout = keepAliveTimeout

        //Set up all the callbacks for the CHTTPParser library
        httpParserSettings.on_message_begin = { parser -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return Int32(0)
            }
            return listener.messageBegan()
        }

        httpParserSettings.on_message_complete = { parser -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return 0
            }
            return listener.messageCompleted()
        }

        httpParserSettings.on_headers_complete = { parser -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return 0
            }
            let methodId = parser?.pointee.method
            let methodName = String(validatingUTF8: http_method_str(http_method(rawValue: methodId ?? 0))) ?? "GET"
            let major = Int(parser?.pointee.http_major ?? 0)
            let minor = Int(parser?.pointee.http_minor ?? 0)

            //This needs to be set here and not messageCompleted if it's going to work here
            let keepAlive = http_should_keep_alive(parser) == 1
            let upgradeRequested = parser?.pointee.upgrade == 1

            return listener.headersCompleted(methodName: methodName,
                                             majorVersion: major,
                                             minorVersion: minor,
                                             keepAlive: keepAlive,
                                             upgrade: upgradeRequested)
        }

        httpParserSettings.on_header_field = { (parser, chunk, length) -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return 0
            }
            return listener.headerFieldReceived(data: chunk, length: length)
        }

        httpParserSettings.on_header_value = { (parser, chunk, length) -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return 0
            }
            return listener.headerValueReceived(data: chunk, length: length)
        }

        httpParserSettings.on_body = { (parser, chunk, length) -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return 0
            }
            return listener.bodyReceived(data: chunk, length: length)
        }

        httpParserSettings.on_url = { (parser, chunk, length) -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return 0
            }
            return listener.urlReceived(data: chunk, length: length)
        }

        http_parser_init(&httpParser, HTTP_REQUEST)

        self.httpParser.data = Unmanaged.passUnretained(self).toOpaque()
    }

    /// Read a stream from the network, pass it to the parser and return number of bytes consumed
    ///
    /// - Parameter data: data coming from network
    /// - Returns: number of bytes that we sent to the parser
    public func readStream(data: Data) -> Int {
        return data.withUnsafeBytes { (ptr) -> Int in
            return http_parser_execute(&self.httpParser, &self.httpParserSettings, ptr, data.count)
        }
    }

    /// States to track where we are in parsing the HTTP Stream from the client
    enum CallbackRecord {
        case idle, messageBegan, messageCompleted, headersCompleted, headerFieldReceived, headerValueReceived, bodyReceived, urlReceived
    }

    /// Process change of state as we get more and more parser callbacks
    ///
    /// - Parameter currentCallBack: state we are entering, as specified by the CHTTPParser
    /// - Returns: Whether or not the state actually changed
    @discardableResult
    func processCurrentCallback(_ currentCallBack: CallbackRecord) -> Bool {
        if lastCallBack == currentCallBack {
            return false
        }
        switch lastCallBack {
        case .headerFieldReceived:
            if let parserBuffer = self.parserBuffer {
                self.lastHeaderName = String(data: parserBuffer, encoding: .utf8)
                self.parserBuffer = nil
            } else {
                print("Missing parserBuffer after \(lastCallBack)")
            }
        case .headerValueReceived:
            if let parserBuffer = self.parserBuffer,
               let lastHeaderName = self.lastHeaderName,
               let headerValue = String(data: parserBuffer, encoding: .utf8) {
                self.parsedHeaders.append([HTTPHeaders.Name(lastHeaderName): headerValue])
                self.lastHeaderName = nil
                self.parserBuffer = nil
            } else {
                print("Missing parserBuffer after \(lastCallBack)")
            }
        case .headersCompleted:
            self.parserBuffer = nil

            if !upgradeRequested {
                self.httpBodyProcessingCallback = self.handle(self.createRequest(), self)
            }
        case .urlReceived:
            if let parserBuffer = self.parserBuffer {
                //Under heaptrack, this may appear to leak via _CFGetTSDCreateIfNeeded, 
                //  apparently, that's because it triggers thread metadata to be created
                self.parsedURL = String(data: parserBuffer, encoding: .utf8)
                self.parserBuffer = nil
            } else {
                print("Missing parserBuffer after \(lastCallBack)")
            }
        case .idle:
            break
        case .messageBegan:
            break
        case .messageCompleted:
            break
        case .bodyReceived:
            break
        }
        lastCallBack = currentCallBack
        return true
    }

    func messageBegan() -> Int32 {
        processCurrentCallback(.messageBegan)
        self.parserConnector?.responseBeginning()
        return 0
    }

    func messageCompleted() -> Int32 {
        let didChangeState = processCurrentCallback(.messageCompleted)
        if let chunkHandler = self.httpBodyProcessingCallback, didChangeState {
            var dummy = false //We're sending `.end`, which means processing is stopping anyway, so the bool here is pointless
            switch chunkHandler {
            case .processBody(let handler):
                handler(.end, &dummy)
            case .discardBody:
                done()
            }
        }
        return 0
    }

    func headersCompleted(methodName: String,
                          majorVersion: Int,
                          minorVersion: Int,
                          keepAlive: Bool,
                          upgrade: Bool) -> Int32 {
        processCurrentCallback(.headersCompleted)
        self.parsedHTTPMethod = HTTPMethod(methodName)
        self.parsedHTTPVersion = HTTPVersion(major: majorVersion, minor: minorVersion)

        //This needs to be set here and not messageCompleted if it's going to work here
        self.clientRequestedKeepAlive = keepAlive
        self.keepAliveUntil = Date(timeIntervalSinceNow: keepAliveTimeout).timeIntervalSinceReferenceDate
        self.upgradeRequested = upgrade
        return 0
    }

    func headerFieldReceived(data: UnsafePointer<Int8>?, length: Int) -> Int32 {
        processCurrentCallback(.headerFieldReceived)
        guard let data = data else { return 0 }
        data.withMemoryRebound(to: UInt8.self, capacity: length) { (ptr) -> Void in
            if var parserBuffer = parserBuffer {
                parserBuffer.append(ptr, count: length)
            } else {
                parserBuffer = Data(bytes: data, count: length)
            }
        }
        return 0
    }

    func headerValueReceived(data: UnsafePointer<Int8>?, length: Int) -> Int32 {
        processCurrentCallback(.headerValueReceived)
        guard let data = data else { return 0 }
        data.withMemoryRebound(to: UInt8.self, capacity: length) { (ptr) -> Void in
            if var parserBuffer = parserBuffer {
                parserBuffer.append(ptr, count: length)
            } else {
                parserBuffer = Data(bytes: data, count: length)
            }
        }
        return 0
    }

    func bodyReceived(data: UnsafePointer<Int8>?, length: Int) -> Int32 {
        processCurrentCallback(.bodyReceived)
        guard let data = data else { return 0 }
        if shouldStopProcessingBody {
            return 0
        }
        data.withMemoryRebound(to: UInt8.self, capacity: length) { (ptr) -> Void in
            #if swift(>=4.0)
                let buff = UnsafeRawBufferPointer(start: ptr, count: length)
            #else
                let buff = UnsafeBufferPointer<UInt8>(start: ptr, count: length)
            #endif
            let chunk = DispatchData(bytes: buff)
            if let chunkHandler = self.httpBodyProcessingCallback {
                switch chunkHandler {
                    case .processBody(let handler):
                        //OK, this sucks.  We can't access the value of the `inout` inside this block
                        //  due to exclusivity. Which means that if we were to pass a local variable, we'd
                        //  have to put a semaphore or something up here to wait for the block to be done before
                        //  we could get its value and pass that on to the instance variable. So instead, we're
                        //  just passing in a pointer to the internal ivar. But that ivar can't be modified in
                        //  more than one place, so we have to put a semaphore around it to prevent that.
                        _shouldStopProcessingBodyLock.wait()
                        handler(.chunk(data: chunk, finishedProcessing: { self._shouldStopProcessingBodyLock.signal() }), &_shouldStopProcessingBody)
                    case .discardBody:
                        break
                }
            }
        }
        return 0
    }

    func urlReceived(data: UnsafePointer<Int8>?, length: Int) -> Int32 {
        processCurrentCallback(.urlReceived)
        guard let data = data else { return 0 }
        data.withMemoryRebound(to: UInt8.self, capacity: length) { (ptr) -> Void in
            if var parserBuffer = parserBuffer {
                parserBuffer.append(ptr, count: length)
            } else {
                parserBuffer = Data(bytes: data, count: length)
            }
        }
        return 0
    }

    static func getSelf(parser: UnsafeMutablePointer<http_parser>?) -> StreamingParser? {
        guard let pointee = parser?.pointee.data else { return nil }
        return Unmanaged<StreamingParser>.fromOpaque(pointee).takeUnretainedValue()
    }

    var headersWritten = false
    var isChunked = false

    /// Create a `HTTPRequest` struct from the parsed information 
    public func createRequest() -> HTTPRequest {
        return HTTPRequest(method: parsedHTTPMethod!,
                           target: parsedURL!,
                           httpVersion: parsedHTTPVersion!,
                           headers: parsedHeaders)
    }

    public func writeHeader(status: HTTPResponseStatus, headers: HTTPHeaders, completion: @escaping (Result) -> Void) {

        guard !headersWritten else {
            return
        }

        var header = "HTTP/1.1 \(status.code) \(status.reasonPhrase)\r\n"

        let isContinue = status == .continue

        var headers = headers
        if !isContinue {
            adjustHeaders(status: status, headers: &headers)
        }

        for (key, value) in headers {
            // TODO encode value using [RFC5987]
            header += "\(key): \(value)\r\n"
        }
        header.append("\r\n")

        // FIXME headers are US-ASCII, anything else should be encoded using [RFC5987] some lines above
        // TODO use requested encoding if specified
        if let data = header.data(using: .utf8) {
            self.parserConnector?.queueSocketWrite(data, completion: completion)
            if !isContinue {
                headersWritten = true
            }
        } else {
            //TODO handle encoding error
        }
    }

    func adjustHeaders(status: HTTPResponseStatus, headers: inout HTTPHeaders) {
        for header in status.suppressedHeaders {
            headers[header] = nil
        }

        if headers[.contentLength] != nil {
            headers[.transferEncoding] = "identity"
        } else if parsedHTTPVersion! >= HTTPVersion(major: 1, minor: 1) {
            switch headers[.transferEncoding] {
                case .some("identity"): // identity without content-length
                    clientRequestedKeepAlive = false
                case .some("chunked"):
                    isChunked = true
                default:
                    isChunked = true
                    headers[.transferEncoding] = "chunked"
            }
        } else {
            // HTTP 1.0 does not support chunked
            clientRequestedKeepAlive = false
            headers[.transferEncoding] = nil
        }

        if clientRequestedKeepAlive {
            headers[.connection] = "Keep-Alive"
        } else {
            headers[.connection] = "Close"
        }
    }

    public func writeTrailer(_ trailers: HTTPHeaders, completion: @escaping (Result) -> Void) {
        fatalError("Not implemented")
    }

    public func writeBody(_ data: UnsafeHTTPResponseBody, completion: @escaping (Result) -> Void) {
        guard headersWritten else {
            //TODO error or default headers?
            return
        }

        guard data.withUnsafeBytes({ $0.count > 0 }) else {
            completion(.ok)
            return
        }

        let dataToWrite: Data
        if isChunked {
            dataToWrite = data.withUnsafeBytes {
                let chunkStart = (String($0.count, radix: 16) + "\r\n").data(using: .utf8)!
                var dataToWrite = chunkStart
                dataToWrite.append(UnsafeBufferPointer(start: $0.baseAddress?.assumingMemoryBound(to: UInt8.self), count: $0.count))
                let chunkEnd = "\r\n".data(using: .utf8)!
                dataToWrite.append(chunkEnd)
                return dataToWrite
            }
        } else if let data = data as? Data {
            dataToWrite = data
        } else {
            dataToWrite = data.withUnsafeBytes { Data($0) }
        }

        self.parserConnector?.queueSocketWrite(dataToWrite, completion: completion)
    }

    public func done(completion: @escaping (Result) -> Void) {
        if isChunked {
            let chunkTerminate = "0\r\n\r\n".data(using: .utf8)!
            self.parserConnector?.queueSocketWrite(chunkTerminate, completion: completion)
        }

        self.parsedHTTPMethod = nil
        self.parsedURL = nil
        self.parsedHeaders = HTTPHeaders()
        self.lastHeaderName = nil
        self.parserBuffer = nil
        self.parsedHTTPMethod = nil
        self.parsedHTTPVersion = nil
        self.lastCallBack = .idle
        self.headersWritten = false
        self.httpBodyProcessingCallback = nil
        self.upgradeRequested = false
        self.shouldStopProcessingBody = false

        //Note: This used to be passed into the completion block that `Result` used to have
        //  But since that block was removed, we're calling it directly
        if self.clientRequestedKeepAlive {
            self.keepAliveUntil = Date(timeIntervalSinceNow: keepAliveTimeout).timeIntervalSinceReferenceDate
            self.parserConnector?.responseComplete()
        } else {
            self.parserConnector?.responseCompleteCloseWriter()
        }
        completion(.ok)
    }

    public func abort() {
        fatalError("abort called, not sure what to do with it")
    }

    deinit {
        httpParser.data = nil
    }

}

/// Protocol implemented by the thing that sits in between us and the network layer
/// :nodoc:
public protocol ParserConnecting: class {
    /// Send data to the network do be written to the client
    func queueSocketWrite(_ from: Data, completion: @escaping (Result) -> Void)

    /// Let the network know that a response has started to avoid closing a connection during a slow write
    func responseBeginning()

    /// Let the network know that a response is complete, so it can be closed after timeout
    func responseComplete()

    /// Let the network know that a response is complete and we're ready to close the connection
    func responseCompleteCloseWriter()

    /// Used to let the network know we're ready to close the connection
    func closeWriter()
}

/// Delegate that can tell us how many connections are in-flight so we can set the Keep-Alive header
///  to the correct number of available connections
/// :nodoc:
public protocol CurrentConnectionCounting: class {
    /// Current number of active connections
    var connectionCount: Int { get }
}
