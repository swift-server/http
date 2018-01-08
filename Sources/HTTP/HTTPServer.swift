// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import ServerSecurity

/// Definition of an HTTP server.
public protocol HTTPServing: class {

    /// Start the HTTP server on the given `port`, using `handler` to process incoming requests
    func start(port: Int, tls: TLSConfiguration?, handler: @escaping HTTPRequestHandler) throws

    /// Stop the server
    func stop()

    /// The port the server is listening on
    var port: Int { get }

    /// The number of current connections
    var connectionCount: Int { get }
}

/// A basic HTTP server. Currently this is implemented using the PoCSocket
/// abstraction, but the intention is to remove this dependency and reimplement
/// the class using transport APIs provided by the Server APIs working group.
public class HTTPServer {

    /// Configuration options for creating HTTPServer
    open class Options {
        /// HTTPServer to be created on a given `port`
        /// Note: For Port=0, the kernel assigns a random port. This will cause HTTPServer.port value
        /// to diverge from HTTPServer.Options.port
        public let port: Int
        
        public let tlsConfig: TLSConfiguration?

        ///  Create an instance of HTTPServerOptions
        public init(onPort: Int = 0, tlsConf: TLSConfiguration? = nil) {
            port = onPort
            tlsConfig = tlsConf
        }
    }
    public let options: Options
    
    /// To process incoming requests
    public let handler: HTTPRequestHandler

    private let server = PoCSocketSimpleServer()
    
    /// Create an instance of the server. This needs to be followed with a call to `start(port:handler:)`
    public init(with newOptions: Options, requestHandler: @escaping HTTPRequestHandler) {
        options = newOptions
        handler = requestHandler
    }

    /// Start the HTTP server on the given `port` number, using a `HTTPRequestHandler` to process incoming requests.
    public func start() throws {
        try server.start(port: options.port, tls: options.tlsConfig, handler: handler)
    }

    /// Stop the server
    public func stop() {
        server.stop()
    }

    /// The port number the server is listening on
    public var port: Int {
        return server.port
    }

    /// The number of current connections
    public var connectionCount: Int {
        return server.connectionCount
    }
}
