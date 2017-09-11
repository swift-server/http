// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import HTTP

/// Simple `HTTPRequestHandler` that just echoes back whatever input it gets
class EchoHandler: HTTPRequestHandling {
    func handle(request: HTTPRequest, response: HTTPResponseWriter ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        response.write(headers: ["Transfer-Encoding": "chunked", "X-foo": "bar"], status: .ok)
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(let data, let finishedProcessing):
                response.write(body: data) { _ in
                    finishedProcessing()
                }
            case .end:
                response.done()
            default:
                stop = true /* don't call us anymore */
                response.abort()
            }
        }
    }
}
