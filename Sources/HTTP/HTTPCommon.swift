// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation

/// Takes in a Request and an object to write to, and returns a function that handles reading the request body
public typealias WebApp = (HTTPRequest, HTTPResponseWriter) -> HTTPBodyProcessing

/// Class protocol containing the WebApp func. Using a class protocol to allow weak references for ARC
public protocol WebAppContaining: class {
    /// WebApp method
    func serve(req: HTTPRequest, res: HTTPResponseWriter ) -> HTTPBodyProcessing
}

public enum Result {
    case ok
    case error(Error)
}
