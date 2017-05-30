//
//  SimpleResponseCreator.swift
//  SwiftServerHttp
//
//  Created by Carl Brown on 5/1/17.
//
//

/*
 
 This file isn't part of the API per se, but it's the easiest way to get started- just supply a completion block.
 It's also really handy for building up `WebApp`s to use when writing tests.
 
 */

import Foundation

/// Simple block-based wrapper to create a `WebApp`. Normally used during XCTests
public class SimpleResponseCreator: WebAppContaining {
    
    typealias SimpleHandlerBlock = (_ req: HTTPRequest, _ body: Data) -> (reponse: HTTPResponse, responseBody: Data)
    let completionHandler: SimpleHandlerBlock
    
    public init(completionHandler:@escaping (_ req: HTTPRequest, _ body: Data) -> (reponse: HTTPResponse, responseBody: Data)) {
        self.completionHandler = completionHandler
    }
    
    var buffer = Data()
    
    public func serve(req: HTTPRequest, res: HTTPResponseWriter ) -> HTTPBodyProcessing {
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(let data, let finishedProcessing):
                if (data.count > 0) {
                    self.buffer.append(Data(data))
                }
                finishedProcessing()
            case .end:
                let (response, body) = self.completionHandler(req, self.buffer)
                res.writeResponse(HTTPResponse(httpVersion: response.httpVersion,
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
