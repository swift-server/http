// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import HTTP

/// Simple `HTTPRequestHandler` that prints "Hello, World" as per K&R
class HelloWorldHandler: HTTPRequestHandling {
    func handle(request: HTTPRequest, response: HTTPResponseWriter ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        response.write(headers: [.transferEncoding: "chunked", "X-foo": "bar"], status: .ok)
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(_, let finishedProcessing):
                finishedProcessing()
            case .end:
                response.write(body: "Hello, World!")
                response.done()
            default:
                stop = true /* don't call us anymore */
                response.abort()
            }
        }
    }
}
