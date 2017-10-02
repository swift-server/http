// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Dispatch
import Foundation

/// A structure representing the headers from a HTTP request, without the body of the request.
public struct HTTPRequest {
    /// HTTP request method.
    public var method: HTTPMethod
    /// HTTP request URI, eg. "/foo/bar?buz=qux"
    public var target: String
    /// HTTP request version
    public var httpVersion: HTTPVersion
    /// HTTP request headers
    public var headers: HTTPHeaders
}

/// Method that takes a chunk of request body and is expected to write to the `HTTPResponseWriter`
/// - Parameter HTTPBodyChunk: `HTTPBodyChunk` representing some or all of the incoming request body
/// - Parameter Bool: A boolean flag that can be set to true in order to prevent further processing
public typealias HTTPBodyHandler = (HTTPBodyChunk, inout Bool) -> Void

/// Indicates whether the body is going to be processed or ignored
public enum HTTPBodyProcessing {
    /// Used to discard the body data associated with the incoming HTTP request
    case discardBody
    /// Used to process the body data associated with the imcoming HTTP request using a `HTTPBodyHandler`
    case processBody(handler: HTTPBodyHandler)
}

/// Part or all of the incoming request body
public enum HTTPBodyChunk {
    /// A new chunk of the incoming HTTP reqest body data has arrived. `finishedProcessing()` must be called when
    /// that chunk has been processed.
    case chunk(data: DispatchData, finishedProcessing: () -> Void)
    /// An error has occurred whilst streaming the incoming HTTP request data, eg. the connection closed
    case failed(error: Error)
    /// A trailer header has arrived during the processing of the incoming HTTP request data.
    /// This is currently unimplemented.
    case trailer(key: String, value: String)
    /// The stream of incoming HTTP request data has completed.
    case end
}
