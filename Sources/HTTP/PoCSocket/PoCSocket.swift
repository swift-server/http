// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import Dispatch
import ServerSecurity

///:nodoc:
public enum PoCSocketError: Error {
    case SocketOSError(errno: Int32)
    case InvalidSocketError
    case InvalidReadLengthError
    case InvalidWriteLengthError
    case InvalidBufferError
}

/// Simple Wrapper around the `socket(2)` functions we need for Proof of Concept testing
///  Intentionally a thin layer over `recv(2)`/`send(2)` so uses the same argument types.
///  Note that no method names here are the same as any system call names.
///  This is because we expect the caller might need functionality we haven't implemented here.
internal class PoCSocket: ConnectionDelegate  {
    
    /// hold the file descriptor for the socket supplied by the OS. `-1` is invalid socket
    internal var socketfd: Int32 = -1

    /// The TCP port the server is actually listening on. Set after system call completes
    internal var listeningPort: Int32 = -1

    /// Track state between `listen(2)` and `shutdown(2)`
    private let _isListeningLock = DispatchSemaphore(value: 1)
    private var _isListening: Bool = false
    internal private(set) var isListening: Bool {
        get {
            _isListeningLock.wait()
            defer {
                _isListeningLock.signal()
            }
            return _isListening
        }
        set {
            _isListeningLock.wait()
            defer {
                _isListeningLock.signal()
            }
            _isListening = newValue
        }
    }

    /// Track state between `accept(2)/bind(2)` and `close(2)`
    private let _isConnectedLock = DispatchSemaphore(value: 1)
    private var _isConnected: Bool = false
    internal private(set) var isConnected: Bool {
        get {
            _isConnectedLock.wait()
            defer {
                _isConnectedLock.signal()
            }
            return _isConnected
        }
        set {
            _isConnectedLock.wait()
            defer {
                _isConnectedLock.signal()
            }
            _isConnected = newValue
        }
    }

    /// track whether a shutdown is in progress so we can suppress error messages
    private let _isShuttingDownLock = DispatchSemaphore(value: 1)
    private var _isShuttingDown: Bool = false
    private var isShuttingDown: Bool {
        get {
            _isShuttingDownLock.wait()
            defer {
                _isShuttingDownLock.signal()
            }
            return _isShuttingDown
        }
        set {
            _isShuttingDownLock.wait()
            defer {
                _isShuttingDownLock.signal()
            }
            _isShuttingDown = newValue
        }
    }

    /// Delegate that provides the TLS implementation
    public var TLSdelegate: TLSServiceDelegate? = nil
    /// Return the file descriptor as a connection endpoint for ConnectionDelegate.
    public var endpoint: ConnectionType {
        get {
            return ConnectionType.socket(self.socketfd)
        }
    }

    /// track whether a the socket has already been closed.
    private let _hasClosedLock = DispatchSemaphore(value: 1)
    private var _hasClosed: Bool = false
    private var hasClosed: Bool {
        get {
            _hasClosedLock.wait()
            defer {
                _hasClosedLock.signal()
            }
            return _hasClosed
        }
        set {
            _hasClosedLock.wait()
            defer {
                _hasClosedLock.signal()
            }
            _hasClosed = newValue
        }
    }

    /// Call recv(2) with buffer allocated by our caller and return the output
    ///
    /// - Parameters:
    ///   - readBuffer: Buffer to read into. Note this needs to be `inout` because we're modfying it and we want Swift4+'s ownership checks to make sure no one else is at the same time
    ///   - maxLength: Max length that can be read. Buffer *must* be at least this big!!!
    /// - Returns: Number of bytes read or -1 on failure as per `recv(2)`
    /// - Throws: PoCSocketError if sanity checks fail
    internal func socketRead(into readBuffer: inout UnsafeMutablePointer<Int8>, maxLength: Int) throws -> Int {
        if maxLength <= 0 || maxLength > Int(Int32.max) {
            throw PoCSocketError.InvalidReadLengthError
        }
        if socketfd <= 0 {
            throw PoCSocketError.InvalidSocketError
        }

        //Make sure no one passed a nil pointer to us
        let readBufferPointer: UnsafeMutablePointer<Int8>! = readBuffer
        if readBufferPointer == nil {
            throw PoCSocketError.InvalidBufferError
        }

        //Make sure data isn't re-used
        readBuffer.initialize(to: 0x0, count: maxLength)
        
        let read: Int
        if let tls = self.TLSdelegate {
            // HTTPS
            read = try tls.willReceive(into: readBuffer, bufSize: maxLength)
        } else {
            // HTTP
            read = recv(self.socketfd, readBuffer, maxLength, Int32(0))
        }
        //Leave this as a local variable to facilitate Setting a Watchpoint in lldb
        return read
    }

    /// Pass buffer passed into to us into send(2).
    ///
    /// - Parameters:
    ///   - buffer: buffer containing data to write.
    ///   - bufSize: number of bytes to write. Buffer must be this long
    /// - Returns: number of bytes written or -1. See `send(2)`
    /// - Throws: PoCSocketError if sanity checks fail
    @discardableResult internal func socketWrite(from buffer: UnsafeRawPointer, bufSize: Int) throws -> Int {
        if socketfd <= 0 {
            throw PoCSocketError.InvalidSocketError
        }
        if bufSize < 0 || bufSize > Int(Int32.max) {
            throw PoCSocketError.InvalidWriteLengthError
        }

        // Make sure we weren't handed a nil buffer
        let writeBufferPointer: UnsafeRawPointer! = buffer
        if writeBufferPointer == nil {
            throw PoCSocketError.InvalidBufferError
        }

        let sent: Int
        if let tls = self.TLSdelegate {
            // HTTPS
            sent = try tls.willSend(buffer: buffer, bufSize: Int(bufSize))
        } else {
            // HTTP
            sent = send(self.socketfd, buffer, Int(bufSize), Int32(0))
        }
        //Leave this as a local variable to facilitate Setting a Watchpoint in lldb
        return sent
    }

    /// Calls `shutdown(2)` and `close(2)` on a socket
    internal func shutdownAndClose() {
        self.isShuttingDown = true
        if let tls = self.TLSdelegate {
            tls.willDestroy()
        }
        if socketfd < 1 {
            //Nothing to do. Maybe it was closed already
            return
        }
        if hasClosed {
            //Nothing to do. It was closed already
            return
        }
        if self.isListening || self.isConnected {
            _ = shutdown(self.socketfd, Int32(SHUT_RDWR))
            self.isListening = false
        }
        self.isConnected = false
        close(self.socketfd)
        self.hasClosed = true
    }

    /// Thin wrapper around `accept(2)`
    ///
    /// - Returns: PoCSocket object for newly connected socket or nil if we've been told to shutdown
    /// - Throws: PoCSocketError on sanity check fails or if accept fails after several retries
    internal func acceptClientConnection() throws -> PoCSocket? {
        if socketfd <= 0 || !isListening {
            throw PoCSocketError.InvalidSocketError
        }

        let retVal = PoCSocket()

        var maxRetryCount = 100

        var acceptFD: Int32 = -1
        repeat {
            var acceptAddr = sockaddr_in()
            var addrSize = socklen_t(MemoryLayout<sockaddr_in>.size)

            acceptFD = withUnsafeMutablePointer(to: &acceptAddr) { pointer in
                return accept(self.socketfd, UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: sockaddr.self), &addrSize)
            }
            if acceptFD < 0 && errno != EINTR {
                //fail
                if (isShuttingDown) {
                    return nil
                }
                maxRetryCount = maxRetryCount - 1
                print("Could not accept on socket \(socketfd). Error is \(errno). Will retry.")
            }
        }
        while acceptFD < 0 && maxRetryCount > 0

        if acceptFD < 0 {
            throw PoCSocketError.SocketOSError(errno: errno)
        }

        retVal.isConnected = true
        retVal.socketfd = acceptFD
        
        // TLS delegate does post accept handling and verification
        if let tls = self.TLSdelegate {
            try tls.didAccept(connection: retVal)
        }
        
        return retVal
    }

    /// call `bind(2)` and `listen(2)`
    ///
    /// - Parameters:
    ///   - port: `sin_port` value, see `bind(2)`
    ///   - maxBacklogSize: backlog argument to `listen(2)`
    /// - Throws: PoCSocketError
    internal func bindAndListen(on port: Int = 0, maxBacklogSize: Int32 = 100) throws {
        #if os(Linux)
            socketfd = socket(Int32(AF_INET), Int32(SOCK_STREAM.rawValue), Int32(IPPROTO_TCP))
        #else
            socketfd = socket(Int32(AF_INET), Int32(SOCK_STREAM), Int32(IPPROTO_TCP))
        #endif

        if socketfd <= 0 {
            throw PoCSocketError.InvalidSocketError
        
        }
        // Initialize delegate
        if let tls = self.TLSdelegate {
            try tls.didCreateServer()
        }

        var on: Int32 = 1
        // Allow address reuse
        if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            throw PoCSocketError.SocketOSError(errno: errno)
        }

        // Allow port reuse
        if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEPORT, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            throw PoCSocketError.SocketOSError(errno: errno)
        }

        #if os(Linux)
            var addr = sockaddr_in(
                sin_family: sa_family_t(AF_INET),
                sin_port: htons(UInt16(port)),
                sin_addr: in_addr(s_addr: in_addr_t(0)),
                sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        #else
            var addr = sockaddr_in(
                sin_len: UInt8(MemoryLayout<sockaddr_in>.stride),
                sin_family: UInt8(AF_INET),
                sin_port: (Int(OSHostByteOrder()) != OSLittleEndian ? UInt16(port) : _OSSwapInt16(UInt16(port))),
                sin_addr: in_addr(s_addr: in_addr_t(0)),
                sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        #endif

        _ = withUnsafePointer(to: &addr) {
            bind(self.socketfd, UnsafePointer<sockaddr>(OpaquePointer($0)), socklen_t(MemoryLayout<sockaddr_in>.size))
        }

        _ = listen(self.socketfd, maxBacklogSize)

        isListening = true

        var addr_in = sockaddr_in()

        listeningPort = try withUnsafePointer(to: &addr_in) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketfd, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw PoCSocketError.SocketOSError(errno: errno)
            }
            #if os(Linux)
                return Int32(ntohs(addr_in.sin_port))
            #else
                return Int32(Int(OSHostByteOrder()) != OSLittleEndian ? addr_in.sin_port.littleEndian : addr_in.sin_port.bigEndian)
            #endif
        }
        
        //print("listeningPort is \(listeningPort)")
    }

    /// Check to see if socket is being used
    ///
    /// - Returns: whether socket is listening or connected
    internal func isOpen() -> Bool {
        return isListening || isConnected
    }

    /// Sets the socket to Blocking or non-blocking mode.
    ///
    /// - Parameter mode: true for blocking, false for nonBlocking
    /// - Returns: `fcntl(2)` flags
    /// - Throws: PoCSocketError if `fcntl` fails
    @discardableResult internal func setBlocking(mode: Bool) throws -> Int32 {
        let flags = fcntl(self.socketfd, F_GETFL)
        if flags < 0 {
            //Failed
            throw PoCSocketError.SocketOSError(errno: errno)
        }

        let newFlags = mode ? flags & ~O_NONBLOCK : flags | O_NONBLOCK

        let result = fcntl(self.socketfd, F_SETFL, newFlags)
        if result < 0 {
            //Failed
            throw PoCSocketError.SocketOSError(errno: errno)
        }
        return result
    }
}
