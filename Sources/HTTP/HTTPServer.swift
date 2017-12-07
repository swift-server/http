//
//  HTTPServer.swift
//  HTTP
//
//  Created by Helge Hess on 22.10.17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import Foundation
import Dispatch
#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

public class HTTPServer {
  
  public enum SocketError : Swift.Error {
    case setupFailed      (Int32)
    case couldNotSetOption(Int32)
    case bindFailed       (Int32)
    case listenFailed     (Int32)
  }
  public enum Error : Swift.Error {
    // TBD: this could be done in a better way
    case socketError(SocketError)
  }
  
  private  var boundAddress   : sockaddr_in? = nil
  
  private  var listenSource   : DispatchSourceRead?
  
  internal let queue =
                 DispatchQueue(label: "de.zeezide.swift.server.http.server")
  private  var connections = [ HTTPConnection ]()
  
  private  var acceptCount       = 0
  private  let handlerBaseQueues : [ DispatchQueue ] = {
    var queues = [ DispatchQueue ]()
    for i in 0..<ProcessInfo.processInfo.processorCount {
      let q = DispatchQueue(label: "de.zeezide.swift.server.http.handler\(i)")
      queues.append(q)
      q.async { _ = 46 + 2 } // warm up threads
    }
    return queues
  }()
  
  public init() {
  }
  deinit {
    stop()
  }
  
  
  /// Start the HTTP server on the given `port` number, using a
  /// `HTTPRequestHandler` to process incoming requests.
  public func start(port: Int? = nil,
                    handler: @escaping HTTPRequestHandler) throws
  {
    // - port as Int=0 vs Int? - Int? is better design
    try start(address: sockaddr_in(port: port), handler: handler)
  }
  
  /// Start the HTTP server on the given `port` number, using a
  /// `HTTPRequestHandler` to process incoming requests.
  func start(address : sockaddr_in,
             backlog : Int = 511,
             handler : @escaping HTTPRequestHandler) throws
  {
    /* setup socket */
    
    let ( fd, address ) = try createSocket(boundTo: address)
    boundAddress = address
    
    /* Setup Listen Source */

    listenSource = DispatchSource.makeReadSource(fileDescriptor: fd,
                                                 queue: queue)
    listenSource?.setEventHandler {
      self.handleListenEvent(on: fd, handler: handler)
    }
    
    listenSource?.resume()
    
    /* Listen */
    
    let rc = listen(fd, Int32(backlog))
    if rc != 0 {
      let error = errno
      listenSource?.cancel()
      listenSource = nil
      close(fd)
      throw Error.socketError(.listenFailed(error))
    }
  }
  
  public func stop() {
    // TBD: argument: `hard: Bool`, similar to DispatchIO
    // TBD: hard stop vs Apache-like 'let requests finish'
    
    if let source = listenSource {
      source.cancel()
      close(Int32(source.handle))
      source.setEventHandler(handler: nil)
      listenSource = nil
    }
    boundAddress = nil
    
    queue.async {
      self.connections.forEach { $0.serverWillStop() }
    }
  }
  
  public var port : Int {
    guard let boundAddress = boundAddress else { return -1 }
    return Int(boundAddress.port)
  }
  
  
  private(set) public var connectionCount : Int32 = 0
  
  
  private func handleListenEvent(on fd   : Int32,
                                 handler : @escaping HTTPRequestHandler)
  {
    // TBD:
    // - what are we doing with accept errors??
    // - do we need a 'shutdown' mode? I don't think so, the accept will just
    //   fail. Unless of course a new socket was setup under the same fd. Hm.
    // TODO:
    // - make generic, like in Noze.io (requires protocol for the addresses)
    repeat {
      var addrlen = socklen_t(MemoryLayout<sockaddr_in>.stride)
      var addr    = sockaddr_in()
      
      let newFD = withUnsafeMutablePointer(to: &addr) {
        return $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
          return accept(fd, $0, &addrlen)
        }
      }
      let error = errno
      
      guard newFD != -1 else {
        if error == EWOULDBLOCK { break }
        // what do we want to do w/ accept errors?
        break
      }
      
      #if os(Linux)
        // No: SO_NOSIGPIPE on Linux, use MSG_NOSIGNAL in send()
      #else
        var val : Int32 = 1
        let rc = setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE,
                            &val, socklen_t(MemoryLayout<Int32>.stride))
        if rc != 0 {
          // let error = errno
          // I guess this is non-fatal. At most we fail at SIGPIPE :->
        }
      #endif
      
      self.handleAcceptedSocket(on: newFD, handler: handler)
    }
    while true // we break when we would block or on error
  }
  
  private func handleAcceptedSocket(on fd   : Int32,
                                    handler : @escaping HTTPRequestHandler)
  {
    if acceptCount == Int.max { acceptCount = 0 } // wow, this is stable code!
    else { acceptCount += 1 }
    
    // Simple round robin.
    let baseQueue = handlerBaseQueues[acceptCount % handlerBaseQueues.count]
    
    // Create a new queue, but share the base queue (and its thread).
    let connectionQueue =
      DispatchQueue(label  : "de.zeezide.swift.server.http.con\(acceptCount)",
                    target : baseQueue)
    
    // Create connection, register and start it.
    let connection = HTTPConnection(fd: fd, queue: connectionQueue,
                                    requestHandler: handler, server: self)
    connections.append(connection)
    #if os(Linux)
      // TODO
    #else
      OSAtomicIncrement32(&connectionCount)
    #endif

    
    connection.resume() // start reading from socket
  }
  
  internal func _connectionIsDone(_ connection: HTTPConnection) {
    queue.async {
      guard let idx = self.connections.index(where: { $0 === connection }) else {
        assert(false, "did not find finished connection: \(connection)")
        return
      }
      
      #if os(Linux)
        // TODO
      #else
        OSAtomicDecrement32(&self.connectionCount)
      #endif
      
      // break retain cycle
      self.connections.remove(at: idx)
    }
  }
  
  private func createSocket<T>(boundTo address: T) throws -> ( Int32, T ) {
    // TODO:  We should constraint T to a protocol adopted by sockaddr_in/in6/un
    //        like in Noze.io.
    // FIXME: This doesn't work right for AF_LOCAL/sockaddr_un
    #if os(Linux)
      let SOCK_STREAM = Glibc.SOCK_STREAM.rawValue
    #endif
    
    let fd    = socket(AF_INET, Int32(SOCK_STREAM), 0)
    var error = errno
    if fd == -1 { throw Error.socketError(.setupFailed(error)) }
    
    var closeSocket = true
    defer { if closeSocket { close(fd) } }
    
    var buf    = Int32(1)
    var rc     = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR,
                            &buf, socklen_t(MemoryLayout<Int32>.stride))
    error = errno
    if rc != 0 { throw Error.socketError(.couldNotSetOption(error)) }
    
    
    // TBD: I think the O_NONBLOCK flag is actually set by GCD when we bind the
    //      listener, is that right?
    let flags = fcntl(fd, F_GETFL)
    error = errno
    if flags < 0 { throw Error.socketError(.couldNotSetOption(error)) }
    
    rc = fcntl(fd, F_SETFL, flags & ~O_NONBLOCK)
    error = errno
    if rc < 0 { throw Error.socketError(.couldNotSetOption(error)) }

    
    /* bind */
    
    var addrlen = socklen_t(MemoryLayout<T>.stride)
    var address = address
    rc = withUnsafePointer(to: &address) {
      return $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        return bind(fd, $0, addrlen)
      }
    }
    error = errno
    if rc != 0 { throw Error.socketError(.bindFailed(error)) }
    
    rc = withUnsafeMutablePointer(to: &address) {
      return $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        return getsockname(fd, $0, &addrlen)
      }
    }
    error = errno
    if rc != 0 { throw Error.socketError(.bindFailed(error)) }

    closeSocket = false
    return ( fd, address )
  }
  
}


// MARK: - Socket utilities

fileprivate extension sockaddr_in {
  init(address: in_addr = in_addr(), port: Int?) {
    self.init()
    if let port = port {
      #if os(Linux)
        sin_port = htons(UInt16(port))
      #else
        sin_port = Int(OSHostByteOrder()) == OSLittleEndian
                   ? _OSSwapInt16(UInt16(port)) : UInt16(port)
      #endif
    }
    else {
      sin_port = 0
    }
    sin_addr = address
  }
  
  var isWildcardPort : Bool { return sin_port == 0 }
  
  var port : Int {
    #if os(Linux)
      return Int(ntohs(sin_port))
    #else
      return Int(Int(OSHostByteOrder()) == OSLittleEndian
             ? sin_port.bigEndian : sin_port)
    #endif
  }

  var asString : String {
    let addr = sin_addr.asString
    return isWildcardPort ? "\(addr):*" : "\(addr):\(port)"
  }
}

fileprivate extension in_addr {
  init() { s_addr = INADDR_ANY }
  
  var asString : String {
    if self.s_addr == INADDR_ANY { return "*.*.*.*" }
    
    let len = Int(INET_ADDRSTRLEN) + 2
    var buf = [CChar](repeating:0, count: len)
    
    var selfCopy = self
    let cs = inet_ntop(AF_INET, &selfCopy, &buf, socklen_t(len))
    return cs != nil ? String(cString: cs!) : ""
  }
}
