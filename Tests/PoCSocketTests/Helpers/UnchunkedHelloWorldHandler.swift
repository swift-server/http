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
class UnchunkedHelloWorldHandler: HTTPRequestHandling {
    func handle(request: HTTPRequest, response: HTTPResponseWriter ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        let responseString = "Hello, World!"
        response.writeHeader(status: .ok, headers: [.contentLength: "\(responseString.lengthOfBytes(using: .utf8))"])
        response.writeBody(responseString)
        response.done()
        return .discardBody
    }
}
