// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

/*
 This file isn't part of the API per se, but it's the easiest way to get started - just supply a completion block.
 It's also really handy for building up `HTTPRequestHandler`s to use when writing tests.
 */

import Foundation
import HTTP

/// Simple block-based wrapper to create a `HTTPRequestHandler`. Normally used during XCTests
public class SimpleResponseCreator: HTTPRequestHandling {

    public struct Response {
        public let status: HTTPResponseStatus
        public let headers: HTTPHeaders
        public let body: Data
    }

    typealias SimpleHandlerBlock = (_ req: HTTPRequest, _ body: Data) -> Response
    let completionHandler: SimpleHandlerBlock

    public init(completionHandler:@escaping (_ req: HTTPRequest, _ body: Data) -> Response) {
        self.completionHandler = completionHandler
    }

    var buffer = Data()

    public func handle(request: HTTPRequest, response: HTTPResponseWriter, queue: DispatchQueue? ) -> HTTPBodyProcessing {
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(let data, let finishedProcessing):
                if data.count > 0 {
                    self.buffer.append(Data(data))
                }
                finishedProcessing()
            case .end:
                let responseResult = self.completionHandler(request, self.buffer)
                var headers = responseResult.headers
                headers.replace([.transferEncoding: "chunked"])
                response.writeHeader(status: responseResult.status, headers: headers)
                response.writeBody(responseResult.body) { _ in
                        response.done()
                }
            default:
                stop = true /* don't call us anymore */
                response.abort()
            }
        }
    }
}
