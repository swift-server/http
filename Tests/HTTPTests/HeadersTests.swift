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
        var headers: HTTPHeaders = [
            .accept: "text/html",
            "Accept": "application/xhtml+xml",
            "Accept": "application/xml;q=0.9",
            "accept": "image/webp",
            .accept: "*/*;q=0.8",
            "Accept-Language": "ru-RU,ru;q=0.8",
            .acceptLanguage: "en-US;q=0.6",
            "accept-language": "en;q=0.4",
            "Content-Length": "200",
            "Set-Cookie": "test1=0; expires=Tue, 21 Jun 2016 16:26:50 GMT; path=/; domain=.my.mail.ru",
            "Set-Cookie": "test2=0; expires=Tue, 21 Jun 2016 16:26:50 GMT; path=/; domain=.my.mail.ru",
        ]

        XCTAssertEqual(headers["Content-Length"], "200")
        XCTAssertEqual(headers["content-length"], "200")
        XCTAssertEqual(headers[.contentLength], "200")
        XCTAssertEqual(headers[.accept], "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
        XCTAssertEqual(headers[.acceptLanguage], "ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4")
        XCTAssertEqual(headers[.setCookie], "test1=0; expires=Tue, 21 Jun 2016 16:26:50 GMT; path=/; domain=.my.mail.ru")

        XCTAssertEqual(headers[valuesFor: "Content-Length"], ["200"])
        XCTAssertEqual(headers[valuesFor: "content-length"], ["200"])
        XCTAssertEqual(headers[valuesFor: .contentLength], ["200"])
        XCTAssertEqual(headers[valuesFor: .accept], ["text/html", "application/xhtml+xml", "application/xml;q=0.9", "image/webp", "*/*;q=0.8"])
        XCTAssertEqual(headers[valuesFor: .setCookie], [
            "test1=0; expires=Tue, 21 Jun 2016 16:26:50 GMT; path=/; domain=.my.mail.ru",
            "test2=0; expires=Tue, 21 Jun 2016 16:26:50 GMT; path=/; domain=.my.mail.ru",
        ])

        headers = HTTPHeaders()
        let initialCount = headers.makeIterator().reduce(0) { (last, _) -> Int in return last + 1 }
        XCTAssertEqual(0, initialCount)

        headers.append(["Test-Header": "Test Value"])
        let nextCount = headers.makeIterator().reduce(0) { (last, _) -> Int in return last + 1 }
        XCTAssertEqual(1, nextCount)

        let testHeaderValueArray = headers[valuesFor: "test-header"]
        XCTAssertNotNil(testHeaderValueArray)
        XCTAssertEqual(1, testHeaderValueArray.count)
        XCTAssertEqual("Test Value", testHeaderValueArray.first ?? "Not Found")

        headers.append(["Test-header": "Test Value 2"])
        let testHeaderValueArray2 = headers[valuesFor: "test-header"]
        XCTAssertNotNil(testHeaderValueArray2)
        XCTAssertEqual(2, testHeaderValueArray2.count)
        XCTAssertEqual("Test Value", testHeaderValueArray2.first ?? "Not Found")
        let testHeaderValueArray2Remainder = testHeaderValueArray2.dropFirst()
        XCTAssertEqual("Test Value 2", testHeaderValueArray2Remainder.first ?? "Not Found")

        //This should overwrites, since the subscript is documented to use lowercase keys
        headers[valuesFor: "TEST-HEADER"]=["Test Value 3"]
        let testHeaderValueArray3 = headers[valuesFor: "test-header"]
        XCTAssertNotNil(testHeaderValueArray3)
        XCTAssertEqual(1, testHeaderValueArray3.count)

        //Overwrite
        headers[valuesFor: "TEST-HEADER"]=["Test Value 4a", "Test Value 4b"]
        let testHeaderValueArray4 = headers[valuesFor: "test-header"]
        XCTAssertNotNil(testHeaderValueArray4)
        XCTAssertEqual(2, testHeaderValueArray4.count)
        XCTAssertEqual("Test Value 4a", testHeaderValueArray4.first ?? "Not Found")
        let testHeaderValueArray4Remainder = testHeaderValueArray4.dropFirst()
        XCTAssertEqual("Test Value 4b", testHeaderValueArray4Remainder.first ?? "Not Found")
    }

    static var allTests = [
        ("testHeaders", testHeaders),
    ]
}
