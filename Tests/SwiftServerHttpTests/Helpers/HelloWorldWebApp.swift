//
//  HelloWorldWebApp.swift
//  SwiftServerHttp
//
//  Created by Carl Brown on 4/27/17.
//
//

import Foundation
import SwiftServerHttp

/// Simple `WebApp` that prints "Hello, World" as per K&R
class HelloWorldWebApp: WebAppContaining {
    func serve(req: HTTPRequest, res: HTTPResponseWriter ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        res.writeResponse(HTTPResponse(httpVersion: req.httpVersion,
                                       status: .ok,
                                       transferEncoding: .chunked,
                                       headers: HTTPHeaders([("X-foo", "bar")])))
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(_, let finishedProcessing):
                finishedProcessing()
            case .end:
                res.writeBody(data: "Hello, World!".data(using: .utf8)!) { _ in }
                res.done()
            default:
                stop = true /* don't call us anymore */
                res.abort()
            }
        }
    }
}
