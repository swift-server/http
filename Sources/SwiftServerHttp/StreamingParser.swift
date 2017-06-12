// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import Dispatch

import CHttpParser


/// Class that wraps the CHTTPParser and calls the `WebApp` to get the response
public class StreamingParser: HTTPResponseWriter {

    let webapp : WebApp
    
    /// Time to leave socket open waiting for next request to start
    public static let keepAliveTimeout: TimeInterval = 5
    
    /// Flag to track if the client wants to send multiple requests on the same TCP connection
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

    /// Theoretical limit of how many open requests we can have. Used in Keep-Alive Header
    let maxRequests = 100
    
    /// Optional delegate that can tell us how many connections are in-flight so we can set the Keep-Alive header
    ///  to the correct number of available connections. If not present, the client will not be limited in number of 
    ///  connections that can be made simultaneously
    public weak var connectionCounter: CurrentConnectionCounting?

    /// Holds the bytes that come from the CHTTPParser until we have enough of them to do something with it
    var parserBuffer: Data?

    ///HTTP Parser
    var httpParser = http_parser()
    var httpParserSettings = http_parser_settings()
    
    /// Block that takes a chunk from the HTTPParser as input and writes to a Response as a result
    var httpBodyProcessingCallback: HTTPBodyProcessing?
    
    //Note: we want this to be strong so it holds onto the connector until it's explicitly cleared
    /// Protocol that we use to send data (and status info) back to the Network layer
    public var parserConnector: ParserConnecting?
    
    var lastCallBack = CallbackRecord.idle
    var lastHeaderName: String?
    var parsedHeaders = HTTPHeaders()
    var parsedHTTPMethod: HTTPMethod?
    var parsedHTTPVersion: HTTPVersion?
    var parsedURL: String?

    /// Is the currently parsed request an upgrade request?
    public private(set) var upgradeRequested = false
    
    /// Class that wraps the CHTTPParser and calls the `WebApp` to get the response
    ///
    /// - Parameter webapp: function that is used to create the response
    public init(webapp: @escaping WebApp, connectionCounter: CurrentConnectionCounting? = nil) {
        self.webapp = webapp
        self.connectionCounter = connectionCounter
        
        //Set up all the callbacks for the CHTTPParser library
        httpParserSettings.on_message_begin = {
            parser -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return Int32(0)
            }
            return listener.messageBegan()
        }
        
        httpParserSettings.on_message_complete = {
            parser -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return Int32(0)
            }
            return listener.messageCompleted()
        }
        
        httpParserSettings.on_headers_complete = {
            parser -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return Int32(0)
            }
            return listener.headersCompleted()
        }
        
        httpParserSettings.on_header_field = {
            (parser, chunk, length) -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return Int32(0)
            }
            return listener.headerFieldReceived(data: chunk, length: length)
        }
        
        httpParserSettings.on_header_value = {
            (parser, chunk, length) -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return Int32(0)
            }
            return listener.headerValueReceived(data: chunk, length: length)
        }
        
        httpParserSettings.on_body = {
            (parser, chunk, length) -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return Int32(0)
            }
            return listener.bodyReceived(data: chunk, length: length)
        }
        
        httpParserSettings.on_url = {
            (parser, chunk, length) -> Int32 in
            guard let listener = StreamingParser.getSelf(parser: parser) else {
                return Int32(0)
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
    public func readStream(data:Data) -> Int {
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
    func processCurrentCallback(_ currentCallBack:CallbackRecord) -> Bool {
        if lastCallBack == currentCallBack {
            return false
        }
        switch lastCallBack {
        case .headerFieldReceived:
            if let parserBuffer = self.parserBuffer {
                self.lastHeaderName = String(data: parserBuffer, encoding: .utf8)
                self.parserBuffer=nil
            } else {
                print("Missing parserBuffer after \(lastCallBack)")
            }
        case .headerValueReceived:
            if let parserBuffer = self.parserBuffer, let lastHeaderName = self.lastHeaderName, let headerValue = String(data:parserBuffer, encoding: .utf8) {
                self.parsedHeaders.append(newHeader: (lastHeaderName, headerValue))
                self.lastHeaderName = nil
                self.parserBuffer=nil
            } else {
                print("Missing parserBuffer after \(lastCallBack)")
            }
        case .headersCompleted:
            let methodId = self.httpParser.method
            if let methodName = http_method_str(http_method(rawValue: methodId)) {
                self.parsedHTTPMethod = HTTPMethod(rawValue: String(validatingUTF8: methodName) ?? "GET")
            }
            self.parsedHTTPVersion = (Int(self.httpParser.http_major), Int(self.httpParser.http_minor))
            
            self.parserBuffer=nil
            
            if !upgradeRequested {
                self.httpBodyProcessingCallback = self.webapp(self.createRequest(), self)
            }
        case .urlReceived:
            if let parserBuffer = self.parserBuffer {
                //Under heaptrack, this may appear to leak via _CFGetTSDCreateIfNeeded, 
                //  apparently, that's because it triggers thread metadata to be created
                self.parsedURL = String(data:parserBuffer, encoding: .utf8)
                self.parserBuffer=nil
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
            var stop=false
            switch chunkHandler {
            case .processBody(let handler):
                handler(.end, &stop)
            case .discardBody:
                break
            }
        }
        return 0
    }
    
    func headersCompleted() -> Int32 {
        processCurrentCallback(.headersCompleted)
        //This needs to be set here and not messageCompleted if it's going to work here
        self.clientRequestedKeepAlive = (http_should_keep_alive(&httpParser) == 1)
        self.keepAliveUntil = Date(timeIntervalSinceNow: StreamingParser.keepAliveTimeout).timeIntervalSinceReferenceDate
        upgradeRequested = get_upgrade_value(&self.httpParser) == 1
        return 0
    }
    
    func headerFieldReceived(data: UnsafePointer<Int8>?, length: Int) -> Int32 {
        processCurrentCallback(.headerFieldReceived)
        guard let data = data else { return 0 }
        data.withMemoryRebound(to: UInt8.self, capacity: length) { (ptr) -> Void in
            self.parserBuffer == nil ? self.parserBuffer = Data(bytes:data, count:length) : self.parserBuffer?.append(ptr, count:length)
        }
        return 0
    }
    
    func headerValueReceived(data: UnsafePointer<Int8>?, length: Int) -> Int32 {
        processCurrentCallback(.headerValueReceived)
        guard let data = data else { return 0 }
        data.withMemoryRebound(to: UInt8.self, capacity: length) { (ptr) -> Void in
            self.parserBuffer == nil ? self.parserBuffer = Data(bytes:data, count:length) : self.parserBuffer?.append(ptr, count:length)
        }
        return 0
    }
    
    func bodyReceived(data: UnsafePointer<Int8>?, length: Int) -> Int32 {
        processCurrentCallback(.bodyReceived)
        guard let data = data else { return 0 }
        data.withMemoryRebound(to: UInt8.self, capacity: length) { (ptr) -> Void in
            let buff = UnsafeBufferPointer<UInt8>(start: ptr, count: length)
            let chunk = DispatchData(bytes:buff)
            if let chunkHandler = self.httpBodyProcessingCallback {
                var stop=false
                var finished=false
                while !stop && !finished {
                    switch chunkHandler {
                    case .processBody(let handler):
                        handler(.chunk(data: chunk, finishedProcessing: {
                            finished=true
                        }), &stop)
                    case .discardBody:
                        finished=true
                    }
                }
            }
        }
        return 0
    }
    
    func urlReceived(data: UnsafePointer<Int8>?, length: Int) -> Int32 {
        processCurrentCallback(.urlReceived)
        guard let data = data else { return 0 }
        data.withMemoryRebound(to: UInt8.self, capacity: length) { (ptr) -> Void in
            self.parserBuffer == nil ? self.parserBuffer = Data(bytes:data, count:length) : self.parserBuffer?.append(ptr, count:length)
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
        return HTTPRequest(method: parsedHTTPMethod!, target: parsedURL!, httpVersion: parsedHTTPVersion!, headers: parsedHeaders)
    }
    
    public func writeContinue(headers: HTTPHeaders?) /* to send an HTTP `100 Continue` */ {
        var status = "HTTP/1.1 \(HTTPResponseStatus.continue.code) \(HTTPResponseStatus.continue.reasonPhrase)\r\n"
        if let headers = headers {
            for (key, value) in headers.makeIterator() {
                status += "\(key): \(value)\r\n"
            }
        }
        status += "\r\n"
        
        // TODO use requested encoding if specified
        if let data = status.data(using: .utf8) {
            self.parserConnector?.queueSocketWrite(data)
        } else {
            //TODO handle encoding error
        }
    }
    
    public func writeResponse(_ response: HTTPResponse) {
        guard !headersWritten else {
            return
        }
        
        var headers = "HTTP/1.1 \(response.status.code) \(response.status.reasonPhrase)\r\n"
        
        switch(response.transferEncoding) {
        case .chunked:
            headers += "Transfer-Encoding: chunked\r\n"
            isChunked = true
        case .identity(let contentLength):
            headers += "Content-Length: \(contentLength)\r\n"
        }
        
        for (key, value) in response.headers.makeIterator() {
            headers += "\(key): \(value)\r\n"
        }
        
        let availableConnections = maxRequests - (self.connectionCounter?.connectionCount ?? 0)
        
        if  clientRequestedKeepAlive && (availableConnections > 0) {
            headers.append("Connection: Keep-Alive\r\n")
            headers.append("Keep-Alive: timeout=\(Int(StreamingParser.keepAliveTimeout)), max=\(availableConnections)\r\n")
        }
        else {
            headers.append("Connection: Close\r\n")
        }
        headers.append("\r\n")
        
        // TODO use requested encoding if specified
        if let data = headers.data(using: .utf8) {
            self.parserConnector?.queueSocketWrite(data)
            headersWritten = true
        } else {
            //TODO handle encoding error
        }
    }
    
    public func writeTrailer(key: String, value: String) {
        fatalError("Not implemented")
    }
    
    public func writeBody(data: DispatchData, completion: @escaping (Result<POSIXError, ()>) -> Void) {
        writeBody(data: Data(data), completion: completion)
    }
    
    
    public func writeBody(data: DispatchData) /* convenience */ {
        writeBody(data: data) { _ in
            
        }
    }
    
    public func writeBody(data: Data, completion: @escaping (Result<POSIXError, ()>) -> Void) {
        guard headersWritten else {
            //TODO error or default headers?
            return
        }
        
        guard data.count > 0 else {
            // TODO fix Result
            completion(Result(completion: ()))
            return
        }
        
        var dataToWrite: Data!
        if isChunked {
            let chunkStart = (String(data.count, radix: 16) + "\r\n").data(using: .utf8)!
            dataToWrite = Data(chunkStart)
            dataToWrite.append(data)
            let chunkEnd = "\r\n".data(using: .utf8)!
            dataToWrite.append(chunkEnd)
        } else {
            dataToWrite = data
        }
        
        self.parserConnector?.queueSocketWrite(dataToWrite)
        
        completion(Result(completion: ()))
    }
    
    public func writeBody(data: Data) /* convenience */ {
        writeBody(data: data) { _ in
            
        }
    }
    
    public func done(completion: @escaping (Result<POSIXError, ()>) -> Void) {
        if isChunked {
            let chunkTerminate = "0\r\n\r\n".data(using: .utf8)!
            self.parserConnector?.queueSocketWrite(chunkTerminate)
        }
        
        self.parsedHTTPMethod = nil
        self.parsedURL=nil
        self.parsedHeaders = HTTPHeaders()
        self.lastHeaderName = nil
        self.parserBuffer = nil
        self.parsedHTTPMethod = nil
        self.parsedHTTPVersion = nil
        self.lastCallBack = .idle
        self.headersWritten = false
        self.httpBodyProcessingCallback = nil
        self.upgradeRequested = false
        
        let closeAfter = {
            if self.clientRequestedKeepAlive {
                self.keepAliveUntil = Date(timeIntervalSinceNow:StreamingParser.keepAliveTimeout).timeIntervalSinceReferenceDate
                self.parserConnector?.responseComplete()
            } else {
                self.parserConnector?.closeWriter()
            }
        }
        
        completion(Result(completion: closeAfter()))
    }
    
    public func done() /* convenience */ {
        done() { _ in
        }
    }
    
    public func abort() {
        fatalError("abort called, not sure what to do with it")
    }
    
    deinit {
        httpParser.data = nil
    }

}

/// Protocol implemented by the thing that sits in between us and the network layer
public protocol ParserConnecting: class {
    
    /// Send data to the network do be written to the client
    func queueSocketWrite(_ from: Data) -> Void
    
    /// Let the network know that a response has started to avoid closing a connection during a slow write
    func responseBeginning() -> Void
    
    /// Let the network know that a response is complete, so it can be closed after timeout
    func responseComplete() -> Void
    
    /// Used to let the network know we're ready to close the connection
    func closeWriter() -> Void
}

/// Delegate that can tell us how many connections are in-flight so we can set the Keep-Alive header
///  to the correct number of available connections
public protocol CurrentConnectionCounting: class {
    /// Current number of active connections
    var connectionCount: Int { get }
}
