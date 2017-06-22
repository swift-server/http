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
    func writeBody(data: Data, completion: @escaping (Result<POSIXError, ()>) -> Void)
    func done(completion: @escaping (Result<POSIXError, ()>) -> Void)
    func abort()
}

/// Convenience methods for HTTP response writer.
extension HTTPResponseWriter {
    /// A convenience method for writing the supplied
    /// `DispatchData` to the body of the HTTP response without
    /// needing to supply a completion closure.
    ///
    /// - see: writeBody(data:completion:)
    public func writeBody(data: DispatchData) {
        return writeBody(data: data) { _ in }
    }

    /// A convenience method for writing the supplied
    /// `Data` to the body of the HTTP response without
    /// needing to supply a completion closure.
    ///
    /// - see: writeBody(data:completion:)
    public func writeBody(data: Data) {
        return writeBody(data: data) { _ in }
    }

    /// A convenience method for signalling that the
    /// HTTP response is complete without needing to supply
    /// a completion closure.
    ///
    /// - see: done(completion:)
    public func done() {
        done { _ in }
    }
}

public enum HTTPTransferEncoding {
    case identity(contentLength: UInt)
    case chunked
}

/// Response status (200 ok, 404 not found, etc)
public struct HTTPResponseStatus: Equatable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    public let code: Int
    public let reasonPhrase: String

    public init(code: Int, reasonPhrase: String) {
        self.code = code
        self.reasonPhrase = reasonPhrase
    }

    public init(code: Int) {
        self.init(code: code, reasonPhrase: HTTPResponseStatus.defaultReasonPhrase(forCode: code))
    }

    public init(integerLiteral: Int) {
        self.init(code: integerLiteral)
    }
    
    /* all the codes from http://www.iana.org/assignments/http-status-codes */
    public static let `continue` = HTTPResponseStatus(code: 100)
    public static let switchingProtocols = HTTPResponseStatus(code: 101)
    public static let ok = HTTPResponseStatus(code: 200)
    public static let created = HTTPResponseStatus(code: 201)
    public static let accepted = HTTPResponseStatus(code: 202)
    public static let nonAuthoritativeInformation = HTTPResponseStatus(code: 203)
    public static let noContent = HTTPResponseStatus(code: 204)
    public static let resetContent = HTTPResponseStatus(code: 205)
    public static let partialContent = HTTPResponseStatus(code: 206)
    public static let multiStatus = HTTPResponseStatus(code: 207)
    public static let alreadyReported = HTTPResponseStatus(code: 208)
    public static let imUsed = HTTPResponseStatus(code: 226)
    public static let multipleChoices = HTTPResponseStatus(code: 300)
    public static let movedPermanently = HTTPResponseStatus(code: 301)
    public static let found = HTTPResponseStatus(code: 302)
    public static let seeOther = HTTPResponseStatus(code: 303)
    public static let notModified = HTTPResponseStatus(code: 304)
    public static let useProxy = HTTPResponseStatus(code: 305)
    public static let temporaryRedirect = HTTPResponseStatus(code: 307)
    public static let permanentRedirect = HTTPResponseStatus(code: 308)
    public static let badRequest = HTTPResponseStatus(code: 400)
    public static let unauthorized = HTTPResponseStatus(code: 401)
    public static let paymentRequired = HTTPResponseStatus(code: 402)
    public static let forbidden = HTTPResponseStatus(code: 403)
    public static let notFound = HTTPResponseStatus(code: 404)
    public static let methodNotAllowed = HTTPResponseStatus(code: 405)
    public static let notAcceptable = HTTPResponseStatus(code: 406)
    public static let proxyAuthenticationRequired = HTTPResponseStatus(code: 407)
    public static let requestTimeout = HTTPResponseStatus(code: 408)
    public static let conflict = HTTPResponseStatus(code: 409)
    public static let gone = HTTPResponseStatus(code: 410)
    public static let lengthRequired = HTTPResponseStatus(code: 411)
    public static let preconditionFailed = HTTPResponseStatus(code: 412)
    public static let payloadTooLarge = HTTPResponseStatus(code: 413)
    public static let uriTooLong = HTTPResponseStatus(code: 414)
    public static let unsupportedMediaType = HTTPResponseStatus(code: 415)
    public static let rangeNotSatisfiable = HTTPResponseStatus(code: 416)
    public static let expectationFailed = HTTPResponseStatus(code: 417)
    public static let misdirectedRequest = HTTPResponseStatus(code: 421)
    public static let unprocessableEntity = HTTPResponseStatus(code: 422)
    public static let locked = HTTPResponseStatus(code: 423)
    public static let failedDependency = HTTPResponseStatus(code: 424)
    public static let upgradeRequired = HTTPResponseStatus(code: 426)
    public static let preconditionRequired = HTTPResponseStatus(code: 428)
    public static let tooManyRequests = HTTPResponseStatus(code: 429)
    public static let requestHeaderFieldsTooLarge = HTTPResponseStatus(code: 431)
    public static let unavailableForLegalReasons = HTTPResponseStatus(code: 451)
    public static let internalServerError = HTTPResponseStatus(code: 500)
    public static let notImplemented = HTTPResponseStatus(code: 501)
    public static let badGateway = HTTPResponseStatus(code: 502)
    public static let serviceUnavailable = HTTPResponseStatus(code: 503)
    public static let gatewayTimeout = HTTPResponseStatus(code: 504)
    public static let httpVersionNotSupported = HTTPResponseStatus(code: 505)
    public static let variantAlsoNegotiates = HTTPResponseStatus(code: 506)
    public static let insufficientStorage = HTTPResponseStatus(code: 507)
    public static let loopDetected = HTTPResponseStatus(code: 508)
    public static let notExtended = HTTPResponseStatus(code: 510)
    public static let networkAuthenticationRequired = HTTPResponseStatus(code: 511)

    static func defaultReasonPhrase(forCode code: Int) -> String {
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
        return Class(code: code)
    }

    public enum Class {
        case informational
        case successful
        case redirection
        case clientError
        case serverError
        case invalidStatus

        init(code: Int) {
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
