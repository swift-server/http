//
//  HTTPResponse.swift
//  SwiftServerHttp
//
//  Created by Carl Brown on 4/24/17based on
//    https://lists.swift.org/pipermail/swift-server-dev/Week-of-Mon-20170403/000422.html
//
//

import Foundation
import Dispatch

/// HTTP Response NOT INCLUDING THE BODY
public struct HTTPResponse {
    public var httpVersion : HTTPVersion
    public var status: HTTPResponseStatus
    public var transferEncoding: HTTPTransferEncoding
    public var headers: HTTPHeaders
    
    public init (httpVersion: HTTPVersion,
                 status: HTTPResponseStatus,
        transferEncoding: HTTPTransferEncoding,
        headers: HTTPHeaders) {
        self.httpVersion = httpVersion
        self.status = status
        self.transferEncoding = transferEncoding
        self.headers = headers
    }
}

/// Object that code writes the response and response body to. 
public protocol HTTPResponseWriter : class {
    func writeContinue(headers: HTTPHeaders?) /* to send an HTTP `100 Continue` */
    
    func writeResponse(_ response: HTTPResponse)
    
    func writeTrailer(key: String, value: String)
    
    func writeBody(data: DispatchData, completion: @escaping (Result<POSIXError, ()>) -> Void)
    func writeBody(data: DispatchData) /* convenience */

    func writeBody(data: Data, completion: @escaping (Result<POSIXError, ()>) -> Void)
    func writeBody(data: Data) /* convenience */

    func done() /* convenience */
    func done(completion: @escaping (Result<POSIXError, ()>) -> Void)
    func abort()
}

public enum HTTPTransferEncoding {
    case identity(contentLength: UInt)
    case chunked
}

/// Response status (200 ok, 404 not found, etc)
public enum HTTPResponseStatus: UInt16, RawRepresentable {
    /* The original spec used custom if you want to use a non-standard response code or
     have it available in a (UInt, String) pair from a higher-level web framework. 
     
     Can't do custom if we want rawRepresentable. TODO: Consider making these constants
 */
    //case custom(code: UInt, reasonPhrase: String)
    
    /* all the codes from http://www.iana.org/assignments/http-status-codes */
    case `continue` = 100
    case switchingProtocols = 101
    case processing = 102
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    case multiStatus = 207
    case alreadyReported = 208
    case imUsed = 226
    case multipleChoices = 300
    case movedPermanently = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case temporaryRedirect = 307
    case permanentRedirect = 308
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case payloadTooLarge = 413
    case uriTooLong = 414
    case unsupportedMediaType = 415
    case rangeNotSatisfiable = 416
    case expectationFailed = 417
    case misdirectedRequest = 421
    case unprocessableEntity = 422
    case locked = 423
    case failedDependency = 424
    case upgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests = 429
    case requestHeaderFieldsTooLarge = 431
    case unavailableForLegalReasons = 451
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    case variantAlsoNegotiates = 506
    case insufficientStorage = 507
    case loopDetected = 508
    case notExtended = 510
    case networkAuthenticationRequired = 511
}

extension HTTPResponseStatus {
    public var reasonPhrase: String {
        switch(self) {
//       Can't do custom if we want rawRepresentable. TODO: Consider making these constants
//        case .custom(_, let reasonPhrase):
//            return reasonPhrase
        case .`continue`:
            return "CONTINUE"
        default:
            return String(describing: self)
        }
    }
    
    public var code: UInt16 {
        return self.rawValue
    }
    
    public static func from(code: UInt16) -> HTTPResponseStatus? {
        return HTTPResponseStatus(rawValue: code)
    }

}


