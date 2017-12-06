// // This source file is part of the Swift.org Server APIs open source project
// //
// // Copyright (c) 2017 Swift Server API project authors
// // Licensed under Apache License v2.0 with Runtime Library Exception
// //
// // See http://swift.org/LICENSE.txt for license information
// //

// import XCTest
// import Dispatch

// @testable import HTTP

// class ServerTests: XCTestCase {
//     func testResponseOK() {
//         let request = HTTPRequest(method: .get, target: "/echo", httpVersion: HTTPVersion(major: 1, minor: 1), headers: ["X-foo": "bar"])
//         let resolver = TestResponseResolver(request: request, requestBody: Data())
//         resolver.resolveHandler(EchoHandler().handle)
//         XCTAssertNotNil(resolver.response)
//         XCTAssertNotNil(resolver.responseBody)
//         XCTAssertEqual(HTTPResponseStatus.ok.code, resolver.response?.status.code ?? 0)
//     }

//     func testEcho() {
//         let testString = "This is a test"
//         let request = HTTPRequest(method: .post, target: "/echo", httpVersion: HTTPVersion(major: 1, minor: 1), headers: ["X-foo": "bar"])
//         let resolver = TestResponseResolver(request: request, requestBody: testString.data(using: .utf8)!)
//         resolver.resolveHandler(EchoHandler().handle)
//         XCTAssertNotNil(resolver.response)
//         XCTAssertNotNil(resolver.responseBody)
//         XCTAssertEqual(HTTPResponseStatus.ok.code, resolver.response?.status.code ?? 0)
//         XCTAssertEqual(testString, resolver.responseBody?.withUnsafeBytes { String(bytes: $0, encoding: .utf8) } ?? "Nil")
//     }

//     func testHello() {
//         let request = HTTPRequest(method: .get, target: "/helloworld", httpVersion: HTTPVersion(major: 1, minor: 1), headers: ["X-foo": "bar"])
//         let resolver = TestResponseResolver(request: request, requestBody: Data())
//         resolver.resolveHandler(HelloWorldHandler().handle)
//         XCTAssertNotNil(resolver.response)
//         XCTAssertNotNil(resolver.responseBody)
//         XCTAssertEqual(HTTPResponseStatus.ok.code, resolver.response?.status.code ?? 0)
//         XCTAssertEqual("Hello, World!", resolver.responseBody?.withUnsafeBytes { String(bytes: $0, encoding: .utf8) } ?? "Nil")
//     }

//     func testSimpleHello() {
//         let request = HTTPRequest(method: .get, target: "/helloworld", httpVersion: HTTPVersion(major: 1, minor: 1), headers: ["X-foo": "bar"])
//         let resolver = TestResponseResolver(request: request, requestBody: Data())
//         let simpleHelloWebApp = SimpleResponseCreator { (_, body) -> SimpleResponseCreator.Response in
//             return SimpleResponseCreator.Response(
//                 status: .ok,
//                 headers: ["X-foo": "bar"],
//                 body: "Hello, World!".data(using: .utf8)!
//             )
//         }
//         resolver.resolveHandler(simpleHelloWebApp.handle)
//         XCTAssertNotNil(resolver.response)
//         XCTAssertNotNil(resolver.responseBody)
//         XCTAssertEqual(HTTPResponseStatus.ok.code, resolver.response?.status.code ?? 0)
//         XCTAssertEqual("Hello, World!", resolver.responseBody?.withUnsafeBytes { String(bytes: $0, encoding: .utf8) } ?? "Nil")
//     }

//     static var allTests = [
//         ("testEcho", testEcho),
//         ("testHello", testHello),
//         ("testSimpleHello", testSimpleHello),
//         ("testResponseOK", testResponseOK),
//     ]
// }
