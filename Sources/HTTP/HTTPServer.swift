import Dispatch
import Foundation

// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

/// A basic HTTP server. Currently this is implemented using the PoCSocket
/// abstraction, but the intention is to remove this dependency and reimplement
/// the class using transport APIs provided by the Server APIs working group.
public class HTTPServer: CurrentConnectionCounting {

    /// Configuration options for creating HTTPServer
    open class Options {
        /// HTTPServer to be created on a given `port`
        /// Note: For Port=0, the kernel assigns a random port. This will cause HTTPServer.port value
        /// to diverge from HTTPServer.Options.port
        public let port: Int

        ///  Create an instance of HTTPServerOptions
        public init(onPort: Int = 8080) {
            port = onPort
        }
    }
    public let options: Options
    
    /// To process incoming requests
    public let handler: HTTPRequestHandler

    /// Stop the server
    public func stop() {
        server?.close()
    }

    /// The port number the server is listening on
    public var port: Int {
        return options.port
    }

    /// Reference to the server for closing
    private var server: TCPServer?

    /// The number of current connections
    public var connectionCount: Int

    /// Create an instance of the server. This needs to be followed with a call to `start(port:handler:)`
    public init(with newOptions: Options, requestHandler: @escaping HTTPRequestHandler) {
        options = newOptions
        handler = requestHandler
        connectionCount = 0
    }

    /// Start the HTTP server on the given `port` number, using a `HTTPRequestHandler` to process incoming requests.
    public func start() throws {
        let socket = try TCPSocket(isNonBlocking: true, shouldReuseAddress: true)
        var eventLoops: [DispatchQueue] = []
        for i in 1...8 {
            eventLoops.append(.init(label: "org.swift.server.eventLoop.\(i)"))
        }
        let server = TCPServer(socket: socket, eventLoops: eventLoops)
        print("Starting on http://localhost:\(options.port)/")
        try server.start(hostname: "0.0.0.0", port: UInt16(options.port), backlog: 4096) { client in
            self.connectionCount += 1
            client.onClose = {
                self.connectionCount -= 1
            }
            let streamingParser = StreamingParser(handler: self.handler, connectionCounter: self, keepAliveTimeout: 5.0)
            streamingParser.parserConnector = client
            client.start { byteBuffer in
                let data = Data(byteBuffer)
                let numParsed = streamingParser.readStream(data: data)
                guard data.count == numParsed else {
                    /// FIXME: better error
                    fatalError()
                }
            }
        }
        self.server = server
    }
}

extension TCPClient: ParserConnecting {
    func queueSocketWrite(_ from: Data, completion: @escaping (Result) -> Void) {
        write(from)
        completion(.ok)
    }

    func responseBeginning() {}
    func responseComplete() {}

    func responseCompleteCloseWriter() {
        close()
    }

    func closeWriter() {
        close()
    }
}
