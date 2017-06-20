// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import Dispatch

/// HTTP Response NOT INCLUDING THE BODY
public struct HTTPResponse {
    public var httpVersion: HTTPVersion
    public var status: HTTPResponseStatus
    public var transferEncoding: HTTPTransferEncoding
    public var headers: HTTPHeaders
    
    public init (httpVersion: HTTPVersion, status: HTTPResponseStatus, transferEncoding: HTTPTransferEncoding, headers: HTTPHeaders) {
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
public struct HTTPResponseStatus: Equatable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    public let code: Int
    public let reasonPhrase: String

    public init(_ code: Int, _ reasonPhrase: String) {
        self.code = code
        self.reasonPhrase = reasonPhrase
    }

    public init(_ code: Int) {
        self.init(code, HTTPResponseStatus.defaultReasonPhrase(code))
    }

    public init(integerLiteral: Int) {
        self.init(integerLiteral)
    }
    
    /* all the codes from http://www.iana.org/assignments/http-status-codes */
    public static let `continue` = HTTPResponseStatus(100)
    public static let switchingProtocols = HTTPResponseStatus(101)
    public static let ok = HTTPResponseStatus(200)
    public static let created = HTTPResponseStatus(201)
    public static let accepted = HTTPResponseStatus(202)
    public static let nonAuthoritativeInformation = HTTPResponseStatus(203)
    public static let noContent = HTTPResponseStatus(204)
    public static let resetContent = HTTPResponseStatus(205)
    public static let partialContent = HTTPResponseStatus(206)
    public static let multiStatus = HTTPResponseStatus(207)
    public static let alreadyReported = HTTPResponseStatus(208)
    public static let imUsed = HTTPResponseStatus(226)
    public static let multipleChoices = HTTPResponseStatus(300)
    public static let movedPermanently = HTTPResponseStatus(301)
    public static let found = HTTPResponseStatus(302)
    public static let seeOther = HTTPResponseStatus(303)
    public static let notModified = HTTPResponseStatus(304)
    public static let useProxy = HTTPResponseStatus(305)
    public static let temporaryRedirect = HTTPResponseStatus(307)
    public static let permanentRedirect = HTTPResponseStatus(308)
    public static let badRequest = HTTPResponseStatus(400)
    public static let unauthorized = HTTPResponseStatus(401)
    public static let paymentRequired = HTTPResponseStatus(402)
    public static let forbidden = HTTPResponseStatus(403)
    public static let notFound = HTTPResponseStatus(404)
    public static let methodNotAllowed = HTTPResponseStatus(405)
    public static let notAcceptable = HTTPResponseStatus(406)
    public static let proxyAuthenticationRequired = HTTPResponseStatus(407)
    public static let requestTimeout = HTTPResponseStatus(408)
    public static let conflict = HTTPResponseStatus(409)
    public static let gone = HTTPResponseStatus(410)
    public static let lengthRequired = HTTPResponseStatus(411)
    public static let preconditionFailed = HTTPResponseStatus(412)
    public static let payloadTooLarge = HTTPResponseStatus(413)
    public static let uriTooLong = HTTPResponseStatus(414)
    public static let unsupportedMediaType = HTTPResponseStatus(415)
    public static let rangeNotSatisfiable = HTTPResponseStatus(416)
    public static let expectationFailed = HTTPResponseStatus(417)
    public static let misdirectedRequest = HTTPResponseStatus(421)
    public static let unprocessableEntity = HTTPResponseStatus(422)
    public static let locked = HTTPResponseStatus(423)
    public static let failedDependency = HTTPResponseStatus(424)
    public static let upgradeRequired = HTTPResponseStatus(426)
    public static let preconditionRequired = HTTPResponseStatus(428)
    public static let tooManyRequests = HTTPResponseStatus(429)
    public static let requestHeaderFieldsTooLarge = HTTPResponseStatus(431)
    public static let unavailableForLegalReasons = HTTPResponseStatus(451)
    public static let internalServerError = HTTPResponseStatus(500)
    public static let notImplemented = HTTPResponseStatus(501)
    public static let badGateway = HTTPResponseStatus(502)
    public static let serviceUnavailable = HTTPResponseStatus(503)
    public static let gatewayTimeout = HTTPResponseStatus(504)
    public static let httpVersionNotSupported = HTTPResponseStatus(505)
    public static let variantAlsoNegotiates = HTTPResponseStatus(506)
    public static let insufficientStorage = HTTPResponseStatus(507)
    public static let loopDetected = HTTPResponseStatus(508)
    public static let notExtended = HTTPResponseStatus(510)
    public static let networkAuthenticationRequired = HTTPResponseStatus(511)

    static func defaultReasonPhrase(_ code: Int) -> String {
        switch code {
            case 100: return "Continue"
            case 101: return "Switching Protocols"
            case 200: return "OK"
            case 201: return "Created"
            case 202: return "Accepted"
            case 203: return "Non-Authoritative Information"
            case 204: return "No Content"
            case 205: return "Reset Content"
            case 206: return "Partial Content"
            case 300: return "Multiple Choices"
            case 301: return "Moved Permanently"
            case 302: return "Found"
            case 303: return "See Other"
            case 304: return "Not Modified"
            case 305: return "Use Proxy"
            case 307: return "Temporary Redirect"
            case 400: return "Bad Request"
            case 401: return "Unauthorized"
            case 402: return "Payment Required"
            case 403: return "Forbidden"
            case 404: return "Not Found"
            case 405: return "Method Not Allowed"
            case 406: return "Not Acceptable"
            case 407: return "Proxy Authentication Required"
            case 408: return "Request Timeout"
            case 409: return "Conflict"
            case 410: return "Gone"
            case 411: return "Length Required"
            case 412: return "Precondition Failed"
            case 413: return "Payload Too Large"
            case 414: return "URI Too Long"
            case 415: return "Unsupported Media Type"
            case 416: return "Range Not Satisfiable"
            case 417: return "Expectation Failed"
            case 426: return "Upgrade Required"
            case 500: return "Internal Server Error"
            case 501: return "Not Implemented"
            case 502: return "Bad Gateway"
            case 503: return "Service Unavailable"
            case 504: return "Gateway Timeout"
            case 505: return "HTTP Version Not Supported"
            default: return "http_\(code)"
        }
    }

    public var description: String {
        return "\(code) \(reasonPhrase)"
    }

    public var `class`: Class {
        return Class(code)
    }

    public enum Class {
        case informational
        case successful
        case redirection
        case clientError
        case serverError
        case invalidStatus

        init(_ code: Int) {
            switch code {
                case 100..<200: self = .informational
                case 200..<300: self = .successful
                case 300..<400: self = .redirection
                case 400..<500: self = .clientError
                case 500..<600: self = .serverError
                default: self = .invalidStatus
            }
        }
    }

    public static func ==(lhs: HTTPResponseStatus, rhs: HTTPResponseStatus) -> Bool {
        return lhs.code == rhs.code
    }
}
