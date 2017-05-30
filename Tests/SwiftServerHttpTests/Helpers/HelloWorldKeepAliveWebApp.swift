//
//  HelloWorldKeepAliveWebApp.swift
//  SwiftServerHttp
//
//  Created by Carl Brown on 5/12/17.
//
//


import Foundation
import SwiftServerHttp

/// `HelloWorldWebApp` that sets the keep alive header for XCTest purposes
class HelloWorldKeepAliveWebApp: WebAppContaining {
    func serve(req: HTTPRequest, res: HTTPResponseWriter ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        res.writeResponse(HTTPResponse(httpVersion: req.httpVersion,
                                       status: .ok,
                                       transferEncoding: .chunked,
                                       headers: HTTPHeaders([("Connection","Keep-Alive"),("Keep-Alive","timeout=5, max=10")])))
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
