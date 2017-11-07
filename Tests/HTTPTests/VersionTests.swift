// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import XCTest

@testable import HTTP

class VersionTests: XCTestCase {
    let version10 = HTTPVersion.v1_0
    let version11 = HTTPVersion.v1_1
    let version20 = HTTPVersion(major: 2, minor: 0)

    func testEquals() {
        XCTAssertEqual(version10, version10)
        XCTAssertEqual(version11, version11)

        XCTAssertNotEqual(version10, version11)
        XCTAssertNotEqual(version11, version10)
        XCTAssertNotEqual(version20, version10)
        XCTAssertNotEqual(version20, version11)
    }
    
    func testInvalidVersionIsNil() {
        XCTAssertNil(version20)
    }

    func testGreater() {
        XCTAssertGreaterThan(version11, version10)

        XCTAssertGreaterThanOrEqual(version10, version10)
        XCTAssertGreaterThanOrEqual(version11, version11)

        XCTAssertFalse(version10 > version11)

        XCTAssertFalse(version10 >= version11)
    }

    func testLess() {
        XCTAssertLessThan(version10, version11)

        XCTAssertLessThanOrEqual(version10, version10)
        XCTAssertLessThanOrEqual(version11, version11)

        XCTAssertFalse(version11 < version10)

        XCTAssertFalse(version11 <= version10)
    }

    func testHashValue() {
        XCTAssertEqual(version10.hashValue, HTTPVersion.v1_0.hashValue)
        XCTAssertEqual(version11.hashValue, HTTPVersion.v1_1.hashValue)

        XCTAssertNotEqual(version10.hashValue, HTTPVersion.v1_1.hashValue)
        XCTAssertNotEqual(version11.hashValue, HTTPVersion.v1_0.hashValue)
    }

    func testDescription() {
        XCTAssertEqual(version10.description, "HTTP/1.0")
        XCTAssertEqual(version11.description, "HTTP/1.1")
    }

    static var allTests = [
        ("testEquals", testEquals),
        ("testGreater", testGreater),
        ("testLess", testLess),
        ("testHashValue", testHashValue),
        ("testDescription", testDescription)
        ]
}
