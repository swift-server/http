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
    let version10 = HTTPVersion(major: 1, minor: 0)
    let version11 = HTTPVersion(major: 1, minor: 1)
    let version20 = HTTPVersion(major: 2, minor: 0)

    func testEquals() {
        XCTAssertEqual(version10, version10)
        XCTAssertEqual(version11, version11)
        XCTAssertEqual(version20, version20)

        XCTAssertNotEqual(version10, version11)
        XCTAssertNotEqual(version11, version10)
        XCTAssertNotEqual(version20, version10)
        XCTAssertNotEqual(version20, version11)
    }

    func testGreater() {
        XCTAssertGreaterThan(version11, version10)
        XCTAssertGreaterThan(version20, version10)
        XCTAssertGreaterThan(version20, version11)

        XCTAssertGreaterThanOrEqual(version10, version10)
        XCTAssertGreaterThanOrEqual(version11, version11)
        XCTAssertGreaterThanOrEqual(version20, version20)

        XCTAssertFalse(version10 > version11)
        XCTAssertFalse(version10 > version20)
        XCTAssertFalse(version11 > version20)

        XCTAssertFalse(version10 >= version11)
        XCTAssertFalse(version10 >= version20)
        XCTAssertFalse(version11 >= version20)
    }

    func testLess() {
        XCTAssertLessThan(version10, version11)
        XCTAssertLessThan(version10, version20)
        XCTAssertLessThan(version11, version20)

        XCTAssertLessThanOrEqual(version10, version10)
        XCTAssertLessThanOrEqual(version11, version11)
        XCTAssertLessThanOrEqual(version20, version20)

        XCTAssertFalse(version11 < version10)
        XCTAssertFalse(version20 < version10)
        XCTAssertFalse(version20 < version11)

        XCTAssertFalse(version11 <= version10)
        XCTAssertFalse(version20 <= version10)
        XCTAssertFalse(version20 <= version11)
    }

    func testHashValue() {
        XCTAssertEqual(version10.hashValue, HTTPVersion(major: 1, minor: 0).hashValue)
        XCTAssertEqual(version11.hashValue, HTTPVersion(major: 1, minor: 1).hashValue)
        XCTAssertEqual(version20.hashValue, HTTPVersion(major: 2, minor: 0).hashValue)

        XCTAssertNotEqual(version10.hashValue, HTTPVersion(major: 1, minor: 1).hashValue)
        XCTAssertNotEqual(version11.hashValue, HTTPVersion(major: 1, minor: 0).hashValue)
        XCTAssertNotEqual(version20.hashValue, HTTPVersion(major: 1, minor: 0).hashValue)
        XCTAssertNotEqual(version20.hashValue, HTTPVersion(major: 1, minor: 1).hashValue)
    }

    func testDescription() {
        XCTAssertEqual(version10.description, "HTTP/1.0")
        XCTAssertEqual(version11.description, "HTTP/1.1")
        XCTAssertEqual(version20.description, "HTTP/2.0")
    }

    static var allTests = [
        ("testEquals", testEquals),
        ("testGreater", testGreater),
        ("testLess", testLess),
        ("testHashValue", testHashValue),
        ("testDescription", testDescription)
        ]
}
