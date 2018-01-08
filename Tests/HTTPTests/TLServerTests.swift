// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import XCTest
import Dispatch
import ServerSecurity

@testable import HTTP

class TLSServerTests: XCTestCase {
    
    func testOkEndToEndTLSwithCA() {
        let config = createCASignedTLSConfig()
        testOkEndToEndInternal(config: config, selfsigned: false)
    }
    
    func testOkEndToEndTLSwithSelfSigned() {
        let config = createSelfSignedTLSConfig()
        testOkEndToEndInternal(config: config, selfsigned: true)
    }
    
    func testOkEndToEndInternal(config: TLSConfiguration, selfsigned: Bool) {
        let receivedExpectation = self.expectation(description: "Received web response \(#function)")
        let urlStr: String
        let session: URLSession
        
        let server = HTTPServer(with: HTTPServer.Options(onPort: 0, tlsConf: config), requestHandler: OkHandler().handle)
        do {
            try server.start()
            
            if selfsigned {
                #if os(OSX)
                    session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue:OperationQueue.main)
                #else
                    // delegate in URLSession in Linux is not implemented. Using this to compile but it will fail if run on Linux.
                    session = URLSession(configuration: URLSessionConfiguration.default)
                #endif
                urlStr = "localhost"
                
            } else {
                session = URLSession(configuration: URLSessionConfiguration.default)
                urlStr = "ssl.gelareh.xyz"
            }

            let url = URL(string: "https://\(urlStr):\(server.port)/")!
            print("Test \(#function) on port \(server.port)")
            print("url = \(url.absoluteString) ")
            let dataTask = session.dataTask(with: url) { (responseBody, rawResponse, error) in
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                XCTAssertNotNil(responseBody)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                receivedExpectation.fulfill()
            }
            dataTask.resume()
            self.waitForExpectations(timeout: 10) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
            server.stop()
        } catch {
            XCTFail("Error listening on port \(0): \(error). Use server.failed(callback:) to handle")
        }
    }
    
    func testHelloEndToEndTLSwithCA() {
        let config = createCASignedTLSConfig()
        testHelloEndToEndInternal(config: config, selfsigned: false)
    }
    
    func testHelloEndToEndTLSwithSelfSigned() {
        let config = createSelfSignedTLSConfig()
        testHelloEndToEndInternal(config: config, selfsigned: true)
    }
    
    func testHelloEndToEndInternal(config: TLSConfiguration, selfsigned: Bool) {
        
        let receivedExpectation = self.expectation(description: "Received web response \(#function)")
        let urlStr: String
        let session: URLSession
        
        let server = HTTPServer(with: HTTPServer.Options(onPort: 0, tlsConf: config), requestHandler: HelloWorldHandler().handle)
        do {
            try server.start()
            
            if selfsigned {
                #if os(OSX)
                    session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue:OperationQueue.main)
                #else
                    // delegate in URLSession in Linux is not implemented. Using this to compile but it will fail if run on Linux.
                    session = URLSession(configuration: URLSessionConfiguration.default)
                #endif
                urlStr = "localhost"
                
            } else {
                session = URLSession(configuration: URLSessionConfiguration.default)
                urlStr = "ssl.gelareh.xyz"
            }
            
            let url = URL(string: "https://\(urlStr):\(server.port)/helloworld")!
            print("Test \(#function) on port \(server.port)")
            let dataTask = session.dataTask(with: url) { (responseBody, rawResponse, error) in
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                XCTAssertNotNil(responseBody)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                XCTAssertEqual("Hello, World!", String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil")
                receivedExpectation.fulfill()
            }
            dataTask.resume()
            self.waitForExpectations(timeout: 10) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
            server.stop()
        } catch {
            XCTFail("Error listening on port \(0): \(error). Use server.failed(callback:) to handle")
        }
    }
    
    func testSimpleHelloEndToEndTLSwithCA() {
        let config = createCASignedTLSConfig()
        let receivedExpectation = self.expectation(description: "Received web response \(#function)")
        let session: URLSession
        
        let simpleHelloWebApp = SimpleResponseCreator { (_, body) -> SimpleResponseCreator.Response in
            return SimpleResponseCreator.Response(
                status: .ok,
                headers: ["X-foo": "bar"],
                body: "Hello, World!".data(using: .utf8)!
            )
        }
        
        let server = HTTPServer(with: HTTPServer.Options(onPort: 0, tlsConf: config), requestHandler: simpleHelloWebApp.handle)
        do {
            try server.start()
            session = URLSession(configuration: URLSessionConfiguration.default)
            
            let url = URL(string: "https://ssl.gelareh.xyz:\(server.port)/helloworld")!
            print("Test \(#function) on port \(server.port)")
            let dataTask = session.dataTask(with: url) { (responseBody, rawResponse, error) in
                print("\(#function) dataTask returned")
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                XCTAssertNotNil(responseBody)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                let responseString = String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil"
                XCTAssertEqual("Hello, World!", responseString)
                print("\(#function) fulfilling expectation")
                receivedExpectation.fulfill()
            }
            dataTask.resume()
            self.waitForExpectations(timeout: 10) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
            server.stop()
        } catch {
            XCTFail("Error listening on port \(0): \(error). Use server.failed(callback:) to handle")
        }
    }
    
    func testRequestEchoEndToEndTLSwithCA() {
        let config = createCASignedTLSConfig()
        let receivedExpectation = self.expectation(description: "Received web response \(#function)")
        let session: URLSession
        let testString = "This is a test"
        
        let server = HTTPServer(with: HTTPServer.Options(onPort: 0, tlsConf: config), requestHandler: EchoHandler().handle)
        do {
            try server.start()
            session = URLSession(configuration: URLSessionConfiguration.default)
            
            let url = URL(string: "https://ssl.gelareh.xyz:\(server.port)/echo")!
            print("Test \(#function) on port \(server.port)")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = testString.data(using: .utf8)
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            
            let dataTask = session.dataTask(with: request) { (responseBody, rawResponse, error) in
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                XCTAssertNotNil(responseBody)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                XCTAssertEqual(testString, String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil")
                receivedExpectation.fulfill()
            }
            dataTask.resume()
            self.waitForExpectations(timeout: 10) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
            server.stop()
        } catch {
            XCTFail("Error listening on port \(0): \(error). Use server.failed(callback:) to handle")
        }
    }
    
    func testRequestKeepAliveEchoEndToEndTLSwithCA() {
        let config = createCASignedTLSConfig()
        let receivedExpectation1 = self.expectation(description: "Received web response 1: \(#function)")
        let receivedExpectation2 = self.expectation(description: "Received web response 2: \(#function)")
        let receivedExpectation3 = self.expectation(description: "Received web response 3: \(#function)")
        let testString1="This is a test"
        let testString2="This is a test, too"
        let testString3="This is also a test"
        let session: URLSession
        
        let server = HTTPServer(with: HTTPServer.Options(onPort: 0, tlsConf: config), requestHandler: EchoHandler().handle)
        do {
            try server.start()
            session = URLSession(configuration: URLSessionConfiguration.default)
            
            let url = URL(string: "https://ssl.gelareh.xyz:\(server.port)/echo")!
            print("Test \(#function) on port \(server.port)")
            var request1 = URLRequest(url: url)
            request1.httpMethod = "POST"
            request1.httpBody = testString1.data(using: .utf8)
            request1.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            
            let dataTask1 = session.dataTask(with: request1) { (responseBody, rawResponse, error) in
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                let headers = response?.allHeaderFields ?? ["": ""]
                let connectionHeader: String = headers["Connection"] as? String ?? ""
                XCTAssertEqual(connectionHeader, "Keep-Alive", "No Keep-Alive Connection")
                XCTAssertNotNil(responseBody, "No Response Body")
                XCTAssertEqual(server.connectionCount, 1)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                XCTAssertEqual(testString1, String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil")
                var request2 = URLRequest(url: url)
                request2.httpMethod = "POST"
                request2.httpBody = testString2.data(using: .utf8)
                request2.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                let dataTask2 = session.dataTask(with: request2) { (responseBody2, rawResponse2, error2) in
                    let response2 = rawResponse2 as? HTTPURLResponse
                    XCTAssertNil(error2, "\(error2!.localizedDescription)")
                    XCTAssertNotNil(response2)
                    let headers = response2?.allHeaderFields ?? ["": ""]
                    let connectionHeader: String = headers["Connection"] as? String ?? ""
                    XCTAssertEqual(connectionHeader, "Keep-Alive", "No Keep-Alive Connection")
                    XCTAssertEqual(server.connectionCount, 1)
                    XCTAssertNotNil(responseBody2)
                    XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response2?.statusCode ?? 0)
                    XCTAssertEqual(testString2, String(data: responseBody2 ?? Data(), encoding: .utf8) ?? "Nil")
                    var request3 = URLRequest(url: url)
                    request3.httpMethod = "POST"
                    request3.httpBody = testString3.data(using: .utf8)
                    request3.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                    let dataTask3 = session.dataTask(with: request3) { (responseBody, rawResponse, error) in
                        let response = rawResponse as? HTTPURLResponse
                        XCTAssertNil(error, "\(error!.localizedDescription)")
                        XCTAssertNotNil(response)
                        let headers = response?.allHeaderFields ?? ["": ""]
                        let connectionHeader: String = headers["Connection"] as? String ?? ""
                        XCTAssertEqual(connectionHeader, "Keep-Alive", "No Keep-Alive Connection")
                        XCTAssertEqual(server.connectionCount, 1)
                        XCTAssertNotNil(responseBody)
                        XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                        XCTAssertEqual(testString3, String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil")
                        receivedExpectation3.fulfill()
                    }
                    dataTask3.resume()
                    receivedExpectation2.fulfill()
                }
                dataTask2.resume()
                receivedExpectation1.fulfill()
            }
            dataTask1.resume()
            
            self.waitForExpectations(timeout: 10) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
            server.stop()
        } catch {
            XCTFail("Error listening on port \(0): \(error). Use server.failed(callback:) to handle")
        }
    }
    
    func testMultipleRequestWithoutKeepAliveEchoEndToEndTLSwithCA() {
        let config = createCASignedTLSConfig()
        let receivedExpectation1 = self.expectation(description: "Received web response 1: \(#function)")
        let receivedExpectation2 = self.expectation(description: "Received web response 2: \(#function)")
        let receivedExpectation3 = self.expectation(description: "Received web response 3: \(#function)")
        let testString1="This is a test"
        let testString2="This is a test, too"
        let testString3="This is also a test"
        let session: URLSession
        
        let server = HTTPServer(with: HTTPServer.Options(onPort: 0, tlsConf: config), requestHandler: EchoHandler().handle)
        do {
            try server.start()
            session = URLSession(configuration: URLSessionConfiguration.default)
            
            let url1 = URL(string: "https://ssl.gelareh.xyz:\(server.port)/echo")!
            print("Test \(#function) on port \(server.port)")
            var request1 = URLRequest(url: url1)
            request1.httpMethod = "POST"
            request1.httpBody = testString1.data(using: .utf8)
            request1.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            request1.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            
            let dataTask1 = session.dataTask(with: request1) { (responseBody, rawResponse, error) in
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                let headers = response?.allHeaderFields ?? ["": ""]
                let connectionHeader: String = headers["Connection"] as? String ?? ""
                let keepAliveHeader = headers["Connection"]
                XCTAssertEqual(connectionHeader, "Keep-Alive", "No Keep-Alive Connection")
                XCTAssertNotNil(keepAliveHeader)
                XCTAssertNotNil(responseBody, "No Keep-Alive Header")
                XCTAssertEqual(server.connectionCount, 1)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                XCTAssertEqual(testString1, String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil")
                let url2 = URL(string: "https://ssl1.gelareh.xyz:\(server.port)/echo")!
                var request2 = URLRequest(url: url2)
                request2.httpMethod = "POST"
                request2.httpBody = testString2.data(using: .utf8)
                request2.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request2.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
                let dataTask2 = session.dataTask(with: request2) { (responseBody2, rawResponse2, error2) in
                    let response2 = rawResponse2 as? HTTPURLResponse
                    XCTAssertNil(error2, "\(error2!.localizedDescription)")
                    XCTAssertNotNil(response2)
                    let headers = response2?.allHeaderFields ?? ["": ""]
                    let connectionHeader: String = headers["Connection"] as? String ?? ""
                    let keepAliveHeader = headers["Connection"]
                    XCTAssertEqual(connectionHeader, "Keep-Alive", "No Keep-Alive Connection")
                    XCTAssertNotNil(keepAliveHeader, "No Keep-Alive Header")
                    XCTAssertEqual(server.connectionCount, 2)
                    XCTAssertNotNil(responseBody2)
                    XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response2?.statusCode ?? 0)
                    XCTAssertEqual(testString2, String(data: responseBody2 ?? Data(), encoding: .utf8) ?? "Nil")
                    let url3 = URL(string: "https://ssl2.gelareh.xyz:\(server.port)/echo")!
                    var request3 = URLRequest(url: url3)
                    request3.httpMethod = "POST"
                    request3.httpBody = testString3.data(using: .utf8)
                    request3.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                    request3.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
                    let dataTask3 = session.dataTask(with: request3) { (responseBody, rawResponse, error) in
                        let response = rawResponse as? HTTPURLResponse
                        XCTAssertNil(error, "\(error!.localizedDescription)")
                        XCTAssertNotNil(response)
                        let headers = response?.allHeaderFields ?? ["": ""]
                        let connectionHeader: String = headers["Connection"] as? String ?? ""
                        let keepAliveHeader = headers["Connection"]
                        XCTAssertEqual(connectionHeader, "Keep-Alive", "No Keep-Alive Connection")
                        XCTAssertNotNil(keepAliveHeader, "No Keep-Alive Header")
                        XCTAssertEqual(server.connectionCount, 3)
                        XCTAssertNotNil(responseBody)
                        XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                        XCTAssertEqual(testString3, String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil")
                        receivedExpectation3.fulfill()
                    }
                    dataTask3.resume()
                    receivedExpectation2.fulfill()
                }
                dataTask2.resume()
                receivedExpectation1.fulfill()
            }
            dataTask1.resume()
            
            self.waitForExpectations(timeout: 10) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
            server.stop()
        } catch {
            XCTFail("Error listening on port \(0): \(error). Use server.failed(callback:) to handle")
        }
    }
    
    func testRequestLargeEchoEndToEndTLSwithCA() {
        let config = createCASignedTLSConfig()
        let receivedExpectation = self.expectation(description: "Received web response \(#function)")
        let session: URLSession
        
        //Use a small chunk size to make sure that we're testing multiple HTTPBodyHandler calls
        let chunkSize = 1024
        
        // Get a file we know exists
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let testExecutableData: Data
        
        do {
            testExecutableData = try Data(contentsOf: executableURL)
        } catch {
            XCTFail("Could not create Data from contents of \(executableURL)")
            return
        }
        
        var testDataLong = testExecutableData + testExecutableData + testExecutableData + testExecutableData
        let length = testDataLong.count
        let keep = 16385
        let remove = length - keep
        if remove > 0 {
            testDataLong.removeLast(remove)
        }
        
        let testData = Data(testDataLong)
        
        let server = PoCSocketSimpleServer()
        do {
            try server.start(port: 0, maxReadLength: chunkSize, tls: config, handler: EchoHandler().handle)
            session = URLSession(configuration: URLSessionConfiguration.default)
            
            let url = URL(string: "https://ssl.gelareh.xyz:\(server.port)/echo")!
            print("Test \(#function) on port \(server.port)")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = testData
            let dataTask = session.dataTask(with: request) { (responseBody, rawResponse, error) in
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                XCTAssertNotNil(responseBody)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                XCTAssertEqual(testData, responseBody ?? Data())
                receivedExpectation.fulfill()
            }
            dataTask.resume()
            self.waitForExpectations(timeout: 10) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
            server.stop()
        } catch {
            XCTFail("Error listening on port \(0): \(error). Use server.failed(callback:) to handle")
        }
    }
    
    func testRequestLargePostHelloWorldTLSwithCA() {
        let config = createCASignedTLSConfig()
        let receivedExpectation = self.expectation(description: "Received web response \(#function)")
        let session: URLSession
        
        // Use a small chunk size to make sure that we stop after one HTTPBodyHandler call
        let chunkSize = 1024
        
        // Get a file we know exists
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let testExecutableData: Data
        
        do {
            testExecutableData = try Data(contentsOf: executableURL)
        } catch {
            XCTFail("Could not create Data from contents of \(executableURL)")
            return
        }
        
        //Make sure there's data there
        XCTAssertNotNil(testExecutableData)
        
        let executableLength = testExecutableData.count
        
        let server = PoCSocketSimpleServer()
        do {
            let testHandler = AbortAndSendHelloHandler()
            try server.start(port: 0, maxReadLength: chunkSize, tls: config, handler: testHandler.handle)
            session = URLSession(configuration: URLSessionConfiguration.default)
            print("Test \(#function) on port \(server.port)")
            
            let url = URL(string: "https://ssl.gelareh.xyz:\(server.port)/echo")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let uploadTask = session.uploadTask(with: request, fromFile: executableURL) { (responseBody, rawResponse, error) in
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                XCTAssertNotNil(responseBody)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                XCTAssertEqual("Hello, World!", String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil")
                XCTAssertEqual(Int(testHandler.chunkCalledCount), 1)
                XCTAssertLessThan(testHandler.chunkLength, executableLength, "Should have written less than the length of the file")
                if (chunkSize < TLSConstants.maxTLSRecordLength) {
                    XCTAssertLessThanOrEqual(Int(testHandler.chunkLength), TLSConstants.maxTLSRecordLength)
                } else {
                    XCTAssertLessThanOrEqual(Int(testHandler.chunkLength), chunkSize)
                }
                receivedExpectation.fulfill()
            }
            uploadTask.resume()
            self.waitForExpectations(timeout: 10) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
            server.stop()
        } catch {
            XCTFail("Error listening on port \(0): \(error). Use server.failed(callback:) to handle")
        }
    }
    
    private func createSelfSignedTLSConfig() -> TLSConfiguration {
        #if os(Linux)
            let myCAPath = URL(fileURLWithPath: #file).appendingPathComponent("../../Certs/Self-Signed/chain.pem").standardized
            let myCertPath = URL(fileURLWithPath: #file).appendingPathComponent("../../Certs/Self-Signed/cert.pem").standardized
            let myKeyPath = URL(fileURLWithPath: #file).appendingPathComponent("../../Certs/Self-Signed/key.pem").standardized
            let config = TLSConfiguration(withCACertificateFilePath: myCAPath.path, usingCertificateFile: myCertPath.path, withKeyFile: myKeyPath.path, usingSelfSignedCerts: true)
        #else
            let myP12 = URL(fileURLWithPath: #file).appendingPathComponent("../../../Certs/Self-Signed/cert.pfx").standardized
            let myPassword = "sw!ft!sC00l"
            let config = TLSConfiguration(withChainFilePath: myP12.path, withPassword: myPassword, usingSelfSignedCerts: true)
        #endif
        
        return config
    }
    
    private func createCASignedTLSConfig() -> TLSConfiguration {
        #if os(Linux)
            
            let myCAPath = URL(fileURLWithPath: #file).appendingPathComponent("../../../Certs/letsEncryptCA/chain.pem").standardized
            let myCertPath = URL(fileURLWithPath: #file).appendingPathComponent("../../../Certs/letsEncryptCA/cert.pem").standardized
            let myKeyPath = URL(fileURLWithPath: #file).appendingPathComponent("../../../Certs/letsEncryptCA/key.pem").standardized
            let config = TLSConfiguration(withCACertificateFilePath: myCAPath.path, usingCertificateFile: myCertPath.path, withKeyFile: myKeyPath.path, usingSelfSignedCerts: false)
            print("myCAPath is at: \(myCAPath.absoluteString) ")
            print("myCertPath is at: \(myCertPath.absoluteString) ")
            print("myKeyPath is at: \(myKeyPath.absoluteString) ")
            
        #else
            let myP12 = URL(fileURLWithPath: #file).appendingPathComponent("../../../Certs/letsEncryptCA/cert.pfx").standardized
            let myPassword = "password"
            let config = TLSConfiguration(withChainFilePath: myP12.path, withPassword: myPassword, usingSelfSignedCerts: false)
            print("myCertPath is at: \(myP12.absoluteString) ")
            
        #endif
        
        return config
    }
    
    static var allTests = [
        ("testOkEndToEndTLSwithCA", testOkEndToEndTLSwithCA),
        ("testHelloEndToEndTLSwithCA", testHelloEndToEndTLSwithCA),
        ("testSimpleHelloEndToEndTLSwithCA", testSimpleHelloEndToEndTLSwithCA),
        ("testRequestEchoEndToEndTLSwithCA", testRequestEchoEndToEndTLSwithCA),
        ("testRequestKeepAliveEchoEndToEndTLSwithCA", testRequestKeepAliveEchoEndToEndTLSwithCA),
        ("testRequestLargeEchoEndToEndTLSwithCA", testRequestLargeEchoEndToEndTLSwithCA),
        ("testMultipleRequestWithoutKeepAliveEchoEndToEndTLSwithCA", testMultipleRequestWithoutKeepAliveEchoEndToEndTLSwithCA),
        ("testRequestLargePostHelloWorldTLSwithCA", testRequestLargePostHelloWorldTLSwithCA),
        ]
}

#if os(OSX)
    extension TLSServerTests: URLSessionDelegate {
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!) )
        }
    }
#endif



