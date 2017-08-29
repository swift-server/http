// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import Dispatch

internal class SimpleServerSocket {
    internal var socketfd: Int32 = -1
    
    internal var listeningPort: Int32 = -1
    
    internal private(set) var isListening = false
    
    internal private(set) var isConnected = false

    internal func socketRead(into readBuffer: inout UnsafeMutablePointer<Int8>, maxLength:Int) throws -> Int {
        //let readBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: maxLength)
        readBuffer.initialize(to: 0x0)
        let read = recv(self.socketfd, readBuffer, maxLength, Int32(0))
//        if read > 0 {
//            data.append(readBuffer, length: read)
//        }
        return read
    }
    
    @discardableResult internal func socketWrite(from buffer: UnsafeRawPointer, bufSize: Int) throws -> Int {
        return send(self.socketfd, buffer, Int(bufSize), Int32(0))
    }
    
    internal func shutdownAndClose() {
        //print("Shutting down socket \(self.socketfd)")
        if self.isListening || self.isConnected {
            //print("Shutting down socket")
            _ = shutdown(self.socketfd, Int32(SHUT_RDWR))
            self.isListening = false
        }
        self.isConnected = false
        close(self.socketfd)
    }
        
    internal func acceptClientConnection() throws -> SimpleServerSocket {
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
                print("errno is \(errno)")
            }
            /*
            else {
                print("Accept returned fd \(acceptFD)")
            }
             */
        }
        while acceptFD < 0
        
        retVal.isConnected = true
        retVal.socketfd = acceptFD
        
        return retVal
    }
    
    internal func bindAndListen(on port: Int, maxBacklogSize: Int32 = 10000) throws {
	#if os(Linux)
        self.socketfd = socket(Int32(AF_INET), Int32(SOCK_STREAM.rawValue), Int32(IPPROTO_TCP))
	#else
        self.socketfd = socket(Int32(AF_INET), Int32(SOCK_STREAM), Int32(IPPROTO_TCP))
	#endif
        
        var on: Int32 = 1
        // Allow address reuse
        if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            fatalError()
        }
        
        // Allow port reuse
        if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEPORT, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            fatalError()
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
        
        //print("listenResult is \(listenResult)")

        var addr_in = sockaddr_in()

        listeningPort = withUnsafePointer(to: &addr_in) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketfd, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                //FIXME: handle error
                fatalError()
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
    
    @discardableResult internal func setBlocking(mode: Bool) -> Int32 {
        let flags = fcntl(self.socketfd, F_GETFL)
        if flags < 0 {
            //Failed
            return flags
        }
        
        let newFlags = mode ? flags & ~O_NONBLOCK : flags | O_NONBLOCK
        
        return fcntl(self.socketfd, F_SETFL, newFlags)
            
    }
}
