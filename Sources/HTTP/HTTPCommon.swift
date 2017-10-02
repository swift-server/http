// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation

/// Typealias for a closure that handles an incoming HTTP request
/// The following is an example of an echo `HTTPRequestHandler` that returns the request it receives as a response:
/// ```swift
///    func echo(request: HTTPRequest, response: HTTPResponseWriter ) -> HTTPBodyProcessing {
///        response.writeHeader(status: .ok)
///        return .processBody { (chunk, stop) in
///            switch chunk {
///            case .chunk(let data, let finishedProcessing):
///                response.writeBody(data) { _ in
///                    finishedProcessing()
///                }
///            case .end:
///                response.done()
///            default:
///                stop = true
///                response.abort()
///            }
///        }
///    }
/// ```
/// This then needs to be registered with the server using `HTTPServer.start(port:handler:)`
/// - Parameter req: the incoming HTTP request.
/// - Parameter res: a writer providing functions to create an HTTP reponse to the request.
/// - Returns HTTPBodyProcessing: a enum that either discards the request data, or provides a closure to process it.
public typealias HTTPRequestHandler = (HTTPRequest, HTTPResponseWriter) -> HTTPBodyProcessing

/// Class protocol containing a `handle()` function that implements `HTTPRequestHandler` to respond to incoming HTTP requests.
/// - See: `HTTPRequestHandler` for more information
public protocol HTTPRequestHandling: class {
    /// handle: function that implements `HTTPRequestHandler` and is called when a new HTTP request is received by the HTTP server.
    /// - Parameter request: the incoming HTTP request.
    /// - Parameter response: a writer providing functions to create an HTTP response to the request.
    /// - Returns HTTPBodyProcessing: a enum that either discards the request data, or provides a closure to process it.
    /// - See: `HTTPRequestHandler` for more information
    func handle(request: HTTPRequest, response: HTTPResponseWriter) -> HTTPBodyProcessing
}

/// The result returned as part of a completion handler
public enum Result {
    /// The action was successful
    case ok
    /// An error occurred during the processing of the action
    case error(Error)
}
