// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Dispatch
import HTTP

/// `HelloWorldRequestHandler` that sets the keep alive header for XCTest purposes
class HelloWorldKeepAliveHandler: HTTPRequestHandling {
    func handle(request: HTTPRequest, response: HTTPResponseWriter, queue: DispatchQueue? ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        response.writeHeader(status: .ok, headers: [
            "Transfer-Encoding": "chunked",
            "Connection": "Keep-Alive",
            "Keep-Alive": "timeout=5, max=10",
        ])
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(_, let finishedProcessing):
                finishedProcessing()
            case .end:
                response.writeBody("Hello, World!")
                response.done()
            default:
                stop = true /* don't call us anymore */
                response.abort()
            }
        }
    }
}
