// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import XCTest

@testable import HTTP

class HeadersTests: XCTestCase {
    func testHeaders() {
        var headers = HTTPHeaders()
        let initialCount = headers.makeIterator().reduce(0) { (last, element) -> Int in return last + 1 }
        XCTAssertEqual(0, initialCount)

        headers.append(newHeader: ("Test-Header","Test Value"))
        let nextCount = headers.makeIterator().reduce(0) { (last, element) -> Int in return last + 1 }
        XCTAssertEqual(1, nextCount)

        let testHeaderValueArray = headers["test-header"]
        XCTAssertNotNil(testHeaderValueArray)
        XCTAssertEqual(1,testHeaderValueArray.count)
        XCTAssertEqual("Test Value",testHeaderValueArray.first ?? "Not Found")

        headers.append(newHeader: ("Test-header","Test Value 2"))
        let testHeaderValueArray2 = headers["test-header"]
        XCTAssertNotNil(testHeaderValueArray2)
        XCTAssertEqual(2,testHeaderValueArray2.count)
        XCTAssertEqual("Test Value",testHeaderValueArray2.first ?? "Not Found")
        let testHeaderValueArray2Remainder = testHeaderValueArray2.dropFirst()
        XCTAssertEqual("Test Value 2",testHeaderValueArray2Remainder.first ?? "Not Found")

        //This should overwrites, since the subscript is documented to use lowercase keys
        headers["TEST-HEADER"]=["Test Value 3"]
        let testHeaderValueArray3 = headers["test-header"]
        XCTAssertNotNil(testHeaderValueArray3)
        XCTAssertEqual(1,testHeaderValueArray3.count)

        //Overwrite
        headers["TEST-HEADER"]=["Test Value 4a","Test Value 4b"]
        let testHeaderValueArray4 = headers["test-header"]
        XCTAssertNotNil(testHeaderValueArray4)
        XCTAssertEqual(2,testHeaderValueArray4.count)
        XCTAssertEqual("Test Value 4a",testHeaderValueArray4.first ?? "Not Found")
        let testHeaderValueArray4Remainder = testHeaderValueArray4.dropFirst()
        XCTAssertEqual("Test Value 4b",testHeaderValueArray4Remainder.first ?? "Not Found")
    }
    
    static var allTests = [
        ("testHeaders", testHeaders),
    ]
}
