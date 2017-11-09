// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import Dispatch
import HTTP

/// Acts as a fake/mock `HTTPServer` so we can write XCTests without having to worry about Sockets and such
class TestResponseResolver: HTTPResponseWriter {
    let request: HTTPRequest
    let requestBody: DispatchData

    var response: (status: HTTPResponseStatus, headers: HTTPHeaders)?
    var responseBody: HTTPResponseBody?

    ///Flag to track whether our handler has told us not to call it anymore
    private let _shouldStopProcessingBodyLock = DispatchSemaphore(value: 1)
    private var _shouldStopProcessingBody: Bool = false
    private var shouldStopProcessingBody: Bool {
        get {
            _shouldStopProcessingBodyLock.wait()
            defer {
                _shouldStopProcessingBodyLock.signal()
            }
            return _shouldStopProcessingBody
        }
        set {
            _shouldStopProcessingBodyLock.wait()
            defer {
                _shouldStopProcessingBodyLock.signal()
            }
            _shouldStopProcessingBody = newValue
        }
    }

    init(request: HTTPRequest, requestBody: Data) {
        self.request = request
        self.requestBody = requestBody.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> DispatchData in
            #if swift(>=4.0)
                return DispatchData(bytes: UnsafeRawBufferPointer(start: ptr, count: requestBody.count))
            #else
                return DispatchData(bytes: UnsafeBufferPointer<UInt8>(start: ptr, count: requestBody.count))
            #endif
        }
    }

    func resolveHandler(_ handler: HTTPRequestHandler) {
        let chunkHandler = handler(request, self)
        if shouldStopProcessingBody {
            return
        }
        switch chunkHandler {
            case .processBody(let handler):
                _shouldStopProcessingBodyLock.wait()
                handler(.chunk(data: self.requestBody, finishedProcessing: { self._shouldStopProcessingBodyLock.signal() }), &_shouldStopProcessingBody)
                var dummy = false
                handler(.end, &dummy)
            case .discardBody:
                break
        }
    }

    func writeHeader(status: HTTPResponseStatus, headers: HTTPHeaders, completion: @escaping (Result) -> Void) {
        self.response = (status: status, headers: headers)
        completion(.ok)
    }

    func writeTrailer(_ trailers: HTTPHeaders, completion: @escaping (Result) -> Void) {
        fatalError("Not implemented")
    }

    func writeBody(_ data: UnsafeHTTPResponseBody, completion: @escaping (Result) -> Void) {
        if let data = data as? HTTPResponseBody {
            self.responseBody = data
        } else {
            self.responseBody = data.withUnsafeBytes { Data($0) }
        }
        completion(.ok)
    }

    func done(completion: @escaping (Result) -> Void) {
        completion(.ok)
    }
    func done() /* convenience */ {
        done { _ in
        }
    }

    func abort() {
        fatalError("abort called, not sure what to do with it")
    }
}
