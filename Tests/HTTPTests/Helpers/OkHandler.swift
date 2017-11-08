// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Dispatch
import HTTP

/// Simple `HTTPRequestHandler` that returns 200: OK without a body
class OkHandler: HTTPRequestHandling {
    func handle(request: HTTPRequest, response: HTTPResponseWriter, queue: DispatchQueue? ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        response.writeHeader(status: .ok, headers: ["Transfer-Encoding": "chunked", "X-foo": "bar"])
        return .discardBody
    }
}
