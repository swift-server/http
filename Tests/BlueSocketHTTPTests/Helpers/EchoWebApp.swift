// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import HTTP


/// Simple `WebApp` that just echoes back whatever input it gets
class EchoWebApp: WebAppContaining {
    func serve(req: HTTP.Request, res: HTTP.ResponseWriter ) -> HTTP.BodyProcessing {
        //Assume the router gave us the right request - at least for now
        res.writeResponse(HTTP.Response(httpVersion: req.httpVersion,
                                       status: .ok,
                                       transferEncoding: .chunked,
                                       headers: HTTP.Headers([("X-foo", "bar")])))
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(let data, let finishedProcessing):
                res.writeBody(data: data) { _ in
                    finishedProcessing()
                }
            case .end:
                res.done()
            default:
                stop = true /* don't call us anymore */
                res.abort()
            }
        }
    }
}
