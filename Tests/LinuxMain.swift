// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import XCTest
@testable import HTTPTests

XCTMain([
    // HTTPTests
    testCase(VersionTests.allTests),
    testCase(HeadersTests.allTests),
    testCase(ResponseTests.allTests),
    testCase(ServerTests.allTests),
    testCase(TLSServerTests.allTests),
])
