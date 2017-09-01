// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import Dispatch

public enum SimpleServerSocketError: Error {
    case SocketOSError(errno: Int32)
    case InvalidSocketError
    case InvalidReadLengthError
    case InvalidWriteLengthError
    case InvalidBufferError
}

/// Simple Wrapper around the `socket(2)` functions we need for Proof of Concept testing
///  Intentionally a thin layer over `recv(2)`/`send(2)` so uses the same argument types.
internal class SimpleServerSocket {
    
    /// hold the file descriptor for the socket supplied by the OS. `-1` is invalid socket
    internal var socketfd: Int32 = -1
    
    /// The TCP port the server is actually listening on. Set after system call completes
    internal var listeningPort: Int32 = -1
    
    /// Track state between `listen(2)` and `shutdown(2)`
    internal private(set) var isListening = false
    
    /// Track state between `accept(2)/bind(2)` and `close(2)`
    internal private(set) var isConnected = false

    /// Call recv(2) with buffer allocated by our caller and return the output
    ///
    /// - Parameters:
    ///   - readBuffer: Buffer to read into. Note this needs to be `inout` because we're modfying it and we want Swift4+'s ownership checks to make sure no one else is at the same time
    ///   - maxLength: Max length that can be read. Buffer *must* be at least this big!!!
    /// - Returns: Number of bytes read or -1 on failure as per `recv(2)`
    /// - Throws: SimpleServerSocketError if sanity checks fail
    internal func socketRead(into readBuffer: inout UnsafeMutablePointer<Int8>, maxLength:Int) throws -> Int {
        if maxLength <= 0 || maxLength > Int32.max {
            throw SimpleServerSocketError.InvalidReadLengthError
        }
        if socketfd <= 0 {
            throw SimpleServerSocketError.InvalidSocketError
        }

        //Make sure no one passed a nil pointer to us
        let readBufferPointer: UnsafeMutablePointer<Int8>! = readBuffer
        if readBufferPointer == nil {
            throw SimpleServerSocketError.InvalidBufferError
        }
        
        //Make sure data isn't re-used
        readBuffer.initialize(to: 0x0, count: maxLength)
        
        let read = recv(self.socketfd, readBuffer, maxLength, Int32(0))
        //Leave this as a local variable to facilitate Setting a Watchpoint in lldb
        return read
    }
    
    /// Pass buffer passed into to us into send(2).
    ///
    /// - Parameters:
    ///   - buffer: buffer containing data to write.
    ///   - bufSize: number of bytes to write. Buffer must be this long
    /// - Returns: number of bytes written or -1. See `send(2)`
    /// - Throws: SimpleServerSocketError if sanity checks fail
    @discardableResult internal func socketWrite(from buffer: UnsafeRawPointer, bufSize: Int) throws -> Int {
        if socketfd <= 0 {
            throw SimpleServerSocketError.InvalidSocketError
        }
        if bufSize < 0 || bufSize > Int32.max {
            throw SimpleServerSocketError.InvalidWriteLengthError
        }
        
        //Make sure we weren't handed a nil buffer
        let writeBufferPointer: UnsafeRawPointer! = buffer
        if writeBufferPointer == nil {
            throw SimpleServerSocketError.InvalidBufferError
        }

        return send(self.socketfd, buffer, Int(bufSize), Int32(0))
        //Leave this as a local variable to facilitate Setting a Watchpoint in lldb
       //return sent
    }
    
    /// Calls `shutdown(2)` and `close(2)` on a socket
    internal func shutdownAndClose() {
        if socketfd < 1 {
            //Nothing to do. Maybe it was closed already
            return
        }
        //print("Shutting down socket \(self.socketfd)")
        if self.isListening || self.isConnected {
            //print("Shutting down socket")
            _ = shutdown(self.socketfd, Int32(SHUT_RDWR))
            self.isListening = false
        }
        self.isConnected = false
        close(self.socketfd)
    }
        
    /// Thin wrapper around `accept(2)`
    ///
    /// - Returns: SimpleServerSocket object for newly connected socket
    /// - Throws: SimpleServerSocketError if sanity checks
    internal func acceptClientConnection() throws -> SimpleServerSocket {
        if socketfd <= 0 || !isListening {
            throw SimpleServerSocketError.InvalidSocketError
        }

        let retVal = SimpleServerSocket()
        
        var acceptFD: Int32 = -1
        repeat {
            var acceptAddr = sockaddr_in()
            var addrSize = socklen_t(MemoryLayout<sockaddr_in>.size)
            
            acceptFD = withUnsafeMutablePointer(to: &acceptAddr) { pointer in
                return accept(self.socketfd, UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: sockaddr.self), &addrSize)
            }
            if acceptFD < 0 && errno != EINTR {
                //fail
                print("Could not accept on socket \(socketfd). Error is \(errno). Will retry.")
            }
        }
        while acceptFD < 0
        
        retVal.isConnected = true
        retVal.socketfd = acceptFD
        
        return retVal
    }
    
    internal func bindAndListen(on port: Int, maxBacklogSize: Int32 = 10000) throws {
        #if os(Linux)
            socketfd = socket(Int32(AF_INET), Int32(SOCK_STREAM.rawValue), Int32(IPPROTO_TCP))
        #else
            socketfd = socket(Int32(AF_INET), Int32(SOCK_STREAM), Int32(IPPROTO_TCP))
        #endif
        
        if socketfd <= 0 {
            throw SimpleServerSocketError.InvalidSocketError
        }
        
        var on: Int32 = 1
        // Allow address reuse
        if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            throw SimpleServerSocketError.SocketOSError(errno: errno)
        }
        
        // Allow port reuse
        if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEPORT, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            throw SimpleServerSocketError.SocketOSError(errno: errno)
        }

        #if os(Linux)
            var addr = sockaddr_in(
                sin_family: sa_family_t(AF_INET),
                sin_port: UInt16(port),
                sin_addr: in_addr(s_addr: in_addr_t(0)),
                sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
        #else
            var addr = sockaddr_in(
                sin_len: UInt8(MemoryLayout<sockaddr_in>.stride),
                sin_family: UInt8(AF_INET),
                sin_port: UInt16(port),
                sin_addr: in_addr(s_addr: in_addr_t(0)),
                sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
        #endif
        
        let _ = withUnsafePointer(to: &addr) {
            bind(self.socketfd, UnsafePointer<sockaddr>(OpaquePointer($0)), socklen_t(MemoryLayout<sockaddr_in>.size))
        }

        //print("bindResult is \(bindResult)")
        
        let _ = listen(self.socketfd, maxBacklogSize)
        
        isListening = true
        
        //print("listenResult is \(listenResult)")

        var addr_in = sockaddr_in()

        listeningPort = try withUnsafePointer(to: &addr_in) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketfd, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SimpleServerSocketError.SocketOSError(errno: errno)
            }
            #if os(Linux)
                return Int32(ntohs(addr_in.sin_port))
            #else
                return Int32(Int(OSHostByteOrder()) != OSLittleEndian ? addr_in.sin_port.littleEndian : addr_in.sin_port.bigEndian)
            #endif
        }
        
        //print("listeningPort is \(listeningPort)")
    }
    
    internal func isOpen() -> Bool {
        return isListening || isConnected
    }
    
    @discardableResult internal func setBlocking(mode: Bool) throws -> Int32 {
        let flags = fcntl(self.socketfd, F_GETFL)
        if flags < 0 {
            //Failed
            throw SimpleServerSocketError.SocketOSError(errno: errno)
        }
        
        let newFlags = mode ? flags & ~O_NONBLOCK : flags | O_NONBLOCK
        
        let result = fcntl(self.socketfd, F_SETFL, newFlags)
        if result < 0 {
            //Failed
            throw SimpleServerSocketError.SocketOSError(errno: errno)
        }
        return result
    }
}
