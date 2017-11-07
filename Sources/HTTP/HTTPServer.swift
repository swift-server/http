// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

/// Definition of an HTTP server.
public protocol HTTPServing: class {

    /// Start the HTTP server on the given `port`, using `handler` to process incoming requests
    func resume(port: Int, handler: @escaping HTTPRequestHandler) throws

    /// Stop the server
    func suspend()

    /// The port the server is listening on
    var port: Int { get }

    /// The number of current connections
    var connectionCount: Int { get }
}

/// A basic HTTP server. Currently this is implemented using the PoCSocket
/// abstraction, but the intention is to remove this dependency and reimplement
/// the class using transport APIs provided by the Server APIs working group.
public class HTTPServer: HTTPServing {
    private let server = PoCSocketSimpleServer()

    /// Create an instance of the server. This needs to be followed with a call to `start(port:handler:)`
    public init() {
    }

    /// Start the HTTP server on the given `port` number, using a `HTTPRequestHandler` to process incoming requests.
    public func resume(port: Int = 0, handler: @escaping HTTPRequestHandler) throws {
        try server.resume(port: port, handler: handler)
    }

    /// Stop the server
    public func suspend() {
        server.suspend()
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
