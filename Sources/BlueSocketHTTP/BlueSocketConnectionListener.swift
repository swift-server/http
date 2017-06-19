// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import HTTP

import Socket

#if os(Linux)
    import Signals
    import Dispatch
#endif


/// The Interface between the StreamingParser class and IBM's BlueSocket wrapper around socket(2).
/// You hopefully should be able to replace this with any network library/engine.
public class BlueSocketConnectionListener: ParserConnecting {
    var socket: Socket?
    
    ///ivar for the thing that manages the CHTTP Parser
    var parser: StreamingParser?
    
    ///Save the socket file descriptor so we can loook at it for debugging purposes
    var socketFD: Int32
    
    /// Queues for managing access to the socket without blocking the world
    weak var socketReaderQueue: DispatchQueue?
    weak var socketWriterQueue: DispatchQueue?
    
    ///Event handler for reading from the socket
    private var readerSource: DispatchSourceRead?
    
    ///Flag to track whether we're in the middle of a response or not (with lock)
    private let _responseCompletedLock = DispatchSemaphore(value: 1)
    private var _responseCompleted: Bool = false
    var responseCompleted: Bool {
        get {
            _responseCompletedLock.wait()
            defer {
                _responseCompletedLock.signal()
            }
            return _responseCompleted
        }
        set {
            _responseCompletedLock.wait()
            defer {
                _responseCompletedLock.signal()
            }
            _responseCompleted = newValue
        }
    }
    
    ///Flag to track whether we've received a socket error or not (with lock)
    private let _errorOccurredLock = DispatchSemaphore(value: 1)
    private var _errorOccurred: Bool = false
    var errorOccurred: Bool {
        get {
            _errorOccurredLock.wait()
            defer {
                _errorOccurredLock.signal()
            }
            return _errorOccurred
        }
        set {
            _errorOccurredLock.wait()
            defer {
                _errorOccurredLock.signal()
            }
            _errorOccurred = newValue
        }
    }
    
    
    /// initializer
    ///
    /// - Parameters:
    ///   - socket: Socket object from BlueSocket library wrapping a socket(2)
    ///   - parser: Manager of the CHTTPParser library
    public init(socket: Socket, parser: StreamingParser, readQueue: DispatchQueue, writeQueue: DispatchQueue) {
        self.socket = socket
        socketFD = socket.socketfd
        socketReaderQueue = readQueue
        socketWriterQueue = writeQueue
        self.parser = parser
        parser.parserConnector = self
    }
    
    
    /// Check if socket is still open. Used to decide whether it should be closed/pruned after timeout
    public var isOpen: Bool {
        guard let socket = self.socket else {
            return false
        }
        return (socket.isActive || socket.isConnected)
    }
    
    
    /// Close the socket and free up memory unless we're in the middle of a request
    func close() {
        if !self.responseCompleted && !self.errorOccurred {
            return
        }
        if (self.socket?.socketfd ?? -1) > 0 {
            self.socket?.close()
        }
        
        //In a perfect world, we wouldn't have to clean this all up explicitly,
        // but KDE/heaptrack informs us we're in far from a perfect world

        if !(self.readerSource?.isCancelled ?? true) {
            self.readerSource?.cancel()
        }
        self.readerSource?.setEventHandler(handler: nil)
        self.readerSource?.setCancelHandler(handler: nil)
        
        self.readerSource = nil
        self.socket = nil
        self.parser?.parserConnector = nil //allows for memory to be reclaimed
        self.parser = nil
        self.socketReaderQueue = nil
        self.socketWriterQueue = nil
    }
    
    
    /// Called by the parser to let us know that it's done with this socket
    public func closeWriter() {
        self.socketWriterQueue?.async { [weak self] in
            if (self?.readerSource?.isCancelled ?? true) {
                self?.close()
            }
        }
    }
    
    /// Check if the socket is idle, and if so, call close()
    func closeIfIdleSocket() {
        let now = Date().timeIntervalSinceReferenceDate
        if let keepAliveUntil = parser?.keepAliveUntil, now >= keepAliveUntil {
            print("Closing idle socket \(socketFD)")
            close()
        }
    }
    
    
    /// Called by the parser to let us know that a response has started being created
    public func responseBeginning() {
        self.socketWriterQueue?.async { [weak self] in
            self?.responseCompleted = false
        }
    }
    
    
    /// Called by the parser to let us know that a response is complete, and we can close after timeout
    public func responseComplete() {
        self.socketWriterQueue?.async { [weak self] in
            self?.responseCompleted = true
            if (self?.readerSource?.isCancelled ?? true) {
                self?.close()
            }
        }
    }
    
    
    /// Starts reading from the socket and feeding that data to the parser
    public func process() {
        do {
            try! socket?.setBlocking(mode: true)
            
            let tempReaderSource = DispatchSource.makeReadSource(fileDescriptor: socket?.socketfd ?? -1,
                                                             queue: socketReaderQueue)
            
            tempReaderSource.setEventHandler { [weak self] in
                
                guard let strongSelf = self else {
                    return
                }
                guard strongSelf.socket?.socketfd ?? -1 > 0 else {
                    self?.readerSource?.cancel()
                    return
                }
                
                var length = 1 //initial value
                do {
                    repeat {
                        if strongSelf.socket?.socketfd ?? -1 > 0 {
                            let readBuffer:NSMutableData = NSMutableData()
                            length = try strongSelf.socket?.read(into: readBuffer) ?? -1
                            if length > 0 {
                                self?.responseCompleted = false
                            }
                            let data = Data(bytes:readBuffer.bytes.assumingMemoryBound(to: Int8.self), count:readBuffer.length)
                            
                            let numberParsed = strongSelf.parser?.readStream(data:data) ?? 0
                            
                            if numberParsed != data.count {
                                print("Error: wrong number of bytes consumed by parser (\(numberParsed) instead of \(data.count)")
                            }
                        } else {
                            print("bad socket FD while reading")
                            length = -1
                        }
                        
                    } while length > 0
                } catch {
                    print("ReaderSource Event Error: \(error)")
                    self?.readerSource?.cancel()
                    self?.errorOccurred = true
                    self?.close()
                }
                if (length == 0) {
                    self?.readerSource?.cancel()
                }
                if (length < 0) {
                    self?.errorOccurred = true
                    self?.readerSource?.cancel()
                    self?.close()
                }
            }
            
            tempReaderSource.setCancelHandler { [ weak self] in
                self?.close() //close if we can
            }
            
            self.readerSource = tempReaderSource
            self.readerSource?.resume()
        }
    }
    
    
    /// Called by the parser to give us data to send back out of the socket
    ///
    /// - Parameter bytes: Data object to be queued to be written to the socket
    public func queueSocketWrite(_ bytes: Data) {
        self.socketWriterQueue?.async { [ weak self ] in
            self?.write(bytes)
        }
    }
    
    
    /// Write data to a socket. Should be called in an `async` block on the `socketWriterQueue`
    ///
    /// - Parameter data: data to be written
    public func write(_ data:Data) {
        do {
            var written: Int = 0
            var offset = 0
            
            while written < data.count && !errorOccurred {
                try data.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) in
                    let result = try socket?.write(from: ptr + offset, bufSize:
                        data.count - offset) ?? -1
                    if (result < 0) {
                        print("Recived broken write socket indication")
                        errorOccurred = true
                    } else {
                        written += result
                    }
                }
                offset = data.count - written
            }
            if (errorOccurred) {
                close()
                return
            }
        } catch {
            print("Recived write socket error: \(error)")
            errorOccurred = true
            close()
        }
    }
}
