// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

/*
 
 This file isn't part of the API per se, but it's the easiest way to get started- just supply a completion block.
 It's also really handy for building up `WebApp`s to use when writing tests.
 
 */

import Foundation
import HTTP

/// Simple block-based wrapper to create a `WebApp`. Normally used during XCTests
public class SimpleResponseCreator: WebAppContaining {
    
    typealias SimpleHandlerBlock = (_ req: HTTP.Request, _ body: Data) -> (reponse: HTTP.Response, responseBody: Data)
    let completionHandler: SimpleHandlerBlock
    
    public init(completionHandler:@escaping (_ req: HTTP.Request, _ body: Data) -> (reponse: HTTP.Response, responseBody: Data)) {
        self.completionHandler = completionHandler
    }
    
    var buffer = Data()
    
    public func serve(req: HTTP.Request, res: HTTP.ResponseWriter ) -> HTTP.BodyProcessing {
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(let data, let finishedProcessing):
                if (data.count > 0) {
                    self.buffer.append(Data(data))
                }
                finishedProcessing()
            case .end:
                let (response, body) = self.completionHandler(req, self.buffer)
                res.writeResponse(HTTP.Response(httpVersion: response.httpVersion,
                status: response.status,
                transferEncoding: .chunked,
                headers: response.headers))
                res.writeBody(data: body) { _ in
                        res.done()
                }
            default:
                stop = true /* don't call us anymore */
                res.abort()
            }
        }
    }
}
