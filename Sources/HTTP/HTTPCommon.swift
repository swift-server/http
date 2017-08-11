// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation

/// Typealias for a closure that handles an incoming HTTP request
/// - Parameter req: the incoming HTTP request.
/// - Parameter res: a writer providing functions to create an HTTP reponse to the request.
/// - Returns HTTPBodyProcessing: a enum that either discards the request data, or provides a closure to process it.
public typealias WebApp = (HTTPRequest, HTTPResponseWriter) -> HTTPBodyProcessing

/// Class protocol containing the WebApp that responds to the incoming HTTP requests.
/// The following is an example of a WebApp that returns the request as a response:
/// ```swift
///    class EchoWebApp: WebAppContaining {
///        func serve(req: HTTPRequest, res: HTTPResponseWriter ) -> HTTPBodyProcessing {
///            res.writeHeader(status: .ok, headers: [:])
///            return .processBody { (chunk, stop) in
///                switch chunk {
///                case .chunk(let data, let finishedProcessing):
///                    res.writeBody(data) { _ in
///                        finishedProcessing()
///                    }
///                case .end:
///                    res.done()
///                default:
///                    stop = true
///                    res.abort()
///                }
///            }
///        }
///    }
/// ```
public protocol WebAppContaining: class {
    /// serve: function called when a new HTTP request is received by the HTTP server.
    /// - Parameter req: the incoming HTTP request.
    /// - Parameter res: an writer providing functions to create an HTTP reponse to the request.
    /// - Returns HTTPBodyProcessing: a enum that either discards the request data, or provides a closure to process it.
    func serve(req: HTTPRequest, res: HTTPResponseWriter ) -> HTTPBodyProcessing
}

/// The result returned as part of a completion handler
public enum Result {
    /// The action was successful
    case ok
    /// An error occurred during the processing of the action
    case error(Error)
}
