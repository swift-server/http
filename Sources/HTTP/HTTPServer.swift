// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

/// Definition of an HTTP server.
public protocol HTTPServing : class {

    /// Start the HTTP server on the given `port`, using `handler` to process incoming requests
    func start(port: Int, handler: @escaping HTTPRequestHandler) throws

    /// Stop the server
    func stop()

    /// The port the server is listening on
    var port: Int { get }

    /// The number of current connections
    var connectionCount: Int { get }
}

/// A basic HTTP server. Currently this is implemented using the BlueSocket
/// abstraction, but the intention is to remove this dependency and reimplement
/// the class using transport APIs provided by the Server APIs working group.
public class HTTPServer: HTTPServing {
    private let server = BlueSocketSimpleServer()

    public init() {
    }

    public func start(port: Int = 0, handler: @escaping HTTPRequestHandler) throws {
        try server.start(handler: handler)
    }

    public func stop() {
        server.stop()
    }

    public var port: Int {
        return server.port
    }

    public var connectionCount: Int {
        return server.connectionCount
    }
}
