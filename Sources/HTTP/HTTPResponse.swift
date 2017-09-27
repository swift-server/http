// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import Dispatch

/// A structure representing the headers for a HTTP response, without the body of the response.
public struct HTTPResponse {
    /// HTTP response version
    public var httpVersion: HTTPVersion
    /// HTTP response status
    public var status: HTTPResponseStatus
    /// HTTP response headers
    public var headers: HTTPHeaders
}

/// HTTPResponseWriter provides functions to create an HTTP response
public protocol HTTPResponseWriter : class {
    /// Writer function to create the headers for an HTTP response
    /// - Parameter status: The status code to include in the HTTP response
    /// - Parameter headers: The HTTP headers to include in the HTTP response
    /// - Parameter completion: Closure that is called when the HTTP headers have been written to the HTTP respose
    func writeHeader(status: HTTPResponseStatus, headers: HTTPHeaders, completion: @escaping (Result) -> Void)

    /// Writer function to write a trailer header as part of the HTTP response
    /// - Parameter trailers: The trailers to write as part of the HTTP response
    /// - Parameter completion: Closure that is called when the trailers has been written to the HTTP response
    /// This is not currently implemented
    func writeTrailer(_ trailers: HTTPHeaders, completion: @escaping (Result) -> Void)

    /// Writer function to write data to the body of the HTTP response
    /// - Parameter data: The data to write as part of the HTTP response
    /// - Parameter completion: Closure that is called when the data has been written to the HTTP response
    func writeBody(_ data: UnsafeHTTPResponseBody, completion: @escaping (Result) -> Void)

    /// Writer function to complete the HTTP response
    /// - Parameter completion: Closure that is called when the HTTP response has been completed
    func done(completion: @escaping (Result) -> Void)

    /// abort: Abort the HTTP response
    func abort()
}

/// Convenience methods for HTTP response writer.
extension HTTPResponseWriter {
    /// Convenience function to write the headers for an HTTP response without a completion handler
    /// - See: `writeHeader(status:headers:completion:)`
    public func writeHeader(status: HTTPResponseStatus, headers: HTTPHeaders) {
        writeHeader(status: status, headers: headers) { _ in }
    }

    /// Convenience function to write a HTTP response with no headers or completion handler
    /// - See: `writeHeader(status:headers:completion:)`
    public func writeHeader(status: HTTPResponseStatus) {
        writeHeader(status: status, headers: [:])
    }

    /// Convenience function to write a trailer header as part of the HTTP response without a completion handler
    /// - See: `writeTrailer(_:completion:)`
    public func writeTrailer(_ trailers: HTTPHeaders) {
        writeTrailer(trailers) { _ in }
    }

    /// Convenience function for writing `data` to the body of the HTTP response without a completion handler.
    /// - See: writeBody(_:completion:)
    public func writeBody(_ data: UnsafeHTTPResponseBody) {
        return writeBody(data) { _ in }
    }

    /// Convenience function to complete the HTTP response without a completion handler.
    /// - See: done(completion:)
    public func done() {
        done { _ in }
    }
}

/// The response status for the HTTP response
/// - See: https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml for more information
public struct HTTPResponseStatus: Equatable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    /// The status code, eg. 200 or 404
    public let code: Int
    /// The reason phrase for the status code
    public let reasonPhrase: String

    /// Creates an HTTP response status
    /// - Parameter code: The status code used for the response status
    /// - Parameter reasonPhrase: The reason phrase to use for the response status
    public init(code: Int, reasonPhrase: String) {
        self.code = code
        self.reasonPhrase = reasonPhrase
    }

    /// Creates an HTTP response status
    /// The reason phrase is added for the status code, or "http_(code)" if the code is not well known
    /// - Parameter code: The status code used for the response status
    public init(code: Int) {
        self.init(code: code, reasonPhrase: HTTPResponseStatus.defaultReasonPhrase(forCode: code))
    }

    /// :nodoc:
    public init(integerLiteral: Int) {
        self.init(code: integerLiteral)
    }

    /* all the codes from http://www.iana.org/assignments/http-status-codes */
    /// 100 Continue
    public static let `continue` = HTTPResponseStatus(code: 100)
    /// 101 Switching Protocols
    public static let switchingProtocols = HTTPResponseStatus(code: 101)
    /// 200 OK
    public static let ok = HTTPResponseStatus(code: 200)
    /// 201 Created
    public static let created = HTTPResponseStatus(code: 201)
    /// 202 Accepted
    public static let accepted = HTTPResponseStatus(code: 202)
    /// 203 Non-Authoritative Information
    public static let nonAuthoritativeInformation = HTTPResponseStatus(code: 203)
    /// 204 No Content
    public static let noContent = HTTPResponseStatus(code: 204)
    /// 205 Reset Content
    public static let resetContent = HTTPResponseStatus(code: 205)
    /// 206 Partial Content
    public static let partialContent = HTTPResponseStatus(code: 206)
    /// 207 Multi-Status
    public static let multiStatus = HTTPResponseStatus(code: 207)
    /// 208 Already Reported
    public static let alreadyReported = HTTPResponseStatus(code: 208)
    /// 226 IM Used
    public static let imUsed = HTTPResponseStatus(code: 226)
    /// 300 Multiple Choices
    public static let multipleChoices = HTTPResponseStatus(code: 300)
    /// 301 Moved Permanently
    public static let movedPermanently = HTTPResponseStatus(code: 301)
    /// 302 Found
    public static let found = HTTPResponseStatus(code: 302)
    /// 303 See Other
    public static let seeOther = HTTPResponseStatus(code: 303)
    /// 304 Not Modified
    public static let notModified = HTTPResponseStatus(code: 304)
    /// 305 Use Proxy
    public static let useProxy = HTTPResponseStatus(code: 305)
    /// 307 Temporary Redirect
    public static let temporaryRedirect = HTTPResponseStatus(code: 307)
    /// 308 Permanent Redirect
    public static let permanentRedirect = HTTPResponseStatus(code: 308)
    /// 400 Bad Request
    public static let badRequest = HTTPResponseStatus(code: 400)
    /// 401 Unauthorized
    public static let unauthorized = HTTPResponseStatus(code: 401)
    /// 402 Payment Required
    public static let paymentRequired = HTTPResponseStatus(code: 402)
    /// 403 Forbidden
    public static let forbidden = HTTPResponseStatus(code: 403)
    /// 404 Not Found
    public static let notFound = HTTPResponseStatus(code: 404)
    /// 405 Method Not Allowed
    public static let methodNotAllowed = HTTPResponseStatus(code: 405)
    /// 406 Not Acceptable
    public static let notAcceptable = HTTPResponseStatus(code: 406)
    /// 407 Proxy Authentication Required
    public static let proxyAuthenticationRequired = HTTPResponseStatus(code: 407)
    /// 408 Request Timeout
    public static let requestTimeout = HTTPResponseStatus(code: 408)
    /// 409 Conflict
    public static let conflict = HTTPResponseStatus(code: 409)
    /// 410 Gone
    public static let gone = HTTPResponseStatus(code: 410)
    /// 411 Length Required
    public static let lengthRequired = HTTPResponseStatus(code: 411)
    /// 412 Precondition Failed
    public static let preconditionFailed = HTTPResponseStatus(code: 412)
    /// 413 Payload Too Large
    public static let payloadTooLarge = HTTPResponseStatus(code: 413)
    /// 414 URI Too Long
    public static let uriTooLong = HTTPResponseStatus(code: 414)
    /// 415 Unsupported Media Type
    public static let unsupportedMediaType = HTTPResponseStatus(code: 415)
    /// 416 Range Not Satisfiable
    public static let rangeNotSatisfiable = HTTPResponseStatus(code: 416)
    /// 417 Expectation Failed
    public static let expectationFailed = HTTPResponseStatus(code: 417)
    /// 421 Misdirected Request
    public static let misdirectedRequest = HTTPResponseStatus(code: 421)
    /// 422 Unprocessable Entity
    public static let unprocessableEntity = HTTPResponseStatus(code: 422)
    /// 423 Locked
    public static let locked = HTTPResponseStatus(code: 423)
    /// 424 Failed Dependency
    public static let failedDependency = HTTPResponseStatus(code: 424)
    /// 426 Upgrade Required
    public static let upgradeRequired = HTTPResponseStatus(code: 426)
    /// 428 Precondition Required
    public static let preconditionRequired = HTTPResponseStatus(code: 428)
    /// 429 Too Many Requests
    public static let tooManyRequests = HTTPResponseStatus(code: 429)
    /// 431 Request Header Fields Too Large
    public static let requestHeaderFieldsTooLarge = HTTPResponseStatus(code: 431)
    /// 451 Unavailable For Legal Reasons
    public static let unavailableForLegalReasons = HTTPResponseStatus(code: 451)
    /// 500 Internal Server Error
    public static let internalServerError = HTTPResponseStatus(code: 500)
    /// 501 Not Implemented
    public static let notImplemented = HTTPResponseStatus(code: 501)
    /// 502 Bad Gateway
    public static let badGateway = HTTPResponseStatus(code: 502)
    /// 503 Service Unavailable
    public static let serviceUnavailable = HTTPResponseStatus(code: 503)
    /// 504 Gateway Timeout
    public static let gatewayTimeout = HTTPResponseStatus(code: 504)
    /// 505 HTTP Version Not Supported
    public static let httpVersionNotSupported = HTTPResponseStatus(code: 505)
    /// 506 Variant Also Negotiates
    public static let variantAlsoNegotiates = HTTPResponseStatus(code: 506)
    /// 507 Insufficient Storage
    public static let insufficientStorage = HTTPResponseStatus(code: 507)
    /// 508 Loop Detected
    public static let loopDetected = HTTPResponseStatus(code: 508)
    /// 510 Not Extended
    public static let notExtended = HTTPResponseStatus(code: 510)
    /// 511 Network Authentication Required
    public static let networkAuthenticationRequired = HTTPResponseStatus(code: 511)

    // swiftlint:disable cyclomatic_complexity switch_case_on_newline
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
            case 207: return "Multi-Status"
            case 208: return "Already Reported"
            case 226: return "IM Used"
            case 300: return "Multiple Choices"
            case 301: return "Moved Permanently"
            case 302: return "Found"
            case 303: return "See Other"
            case 304: return "Not Modified"
            case 305: return "Use Proxy"
            case 307: return "Temporary Redirect"
            case 308: return "Permanent Redirect"
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
            case 421: return "Misdirected Request"
            case 422: return "Unprocessable Entity"
            case 423: return "Locked"
            case 424: return "Failed Dependency"
            case 426: return "Upgrade Required"
            case 428: return "Precondition Required"
            case 429: return "Too Many Requests"
            case 431: return "Request Header Fields Too Large"
            case 451: return "Unavailable For Legal Reasons"
            case 500: return "Internal Server Error"
            case 501: return "Not Implemented"
            case 502: return "Bad Gateway"
            case 503: return "Service Unavailable"
            case 504: return "Gateway Timeout"
            case 505: return "HTTP Version Not Supported"
            case 506: return "Variant Also Negotiates"
            case 507: return "Insufficient Storage"
            case 508: return "Loop Detected"
            case 510: return "Not Extended"
            case 511: return "Network Authentication Required"
            default: return "http_\(code)"
        }
    }

    /// :nodoc:
    public var description: String {
        return "\(code) \(reasonPhrase)"
    }

    /// - The `Class` representing the class of status code for this response status
    public var `class`: Class {
        return Class(code: code)
    }

    /// The class of a `HTTPResponseStatus` code
    /// - See: https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml for more information
    public enum Class {
        /// Informational: the request was received, and is continuing to be processed
        case informational
        /// Success: the action was successfully received, understood, and accepted
        case successful
        /// Redirection: further action must be taken in order to complete the request
        case redirection
        /// Client Error: the request contains bad syntax or cannot be fulfilled
        case clientError
        /// Server Error: the server failed to fulfill an apparently valid request
        case serverError
        /// Invalid: the code does not map to a well known status code class
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

    // [RFC2616, section 4.4]
    var bodyAllowed: Bool {
        switch code {
            case 100..<200: return false
            case 204: return false
            case 304: return false
            default: return true
        }
    }

    var suppressedHeaders: [HTTPHeaders.Name] {
        if self == .notModified {
            return ["Content-Type", "Content-Length", "Transfer-Encoding"]
        } else if !bodyAllowed {
            return ["Content-Length", "Transfer-Encoding"]
        } else {
            return []
        }
    }

    /// :nodoc:
    public static func == (lhs: HTTPResponseStatus, rhs: HTTPResponseStatus) -> Bool {
        return lhs.code == rhs.code
    }
}

/// :nodoc:
public protocol UnsafeHTTPResponseBody {
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

/// :nodoc:
extension UnsafeRawBufferPointer: UnsafeHTTPResponseBody {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        return try body(self)
    }
}

/// :nodoc:
public protocol HTTPResponseBody: UnsafeHTTPResponseBody {}

extension Data: HTTPResponseBody {
    /// :nodoc:
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        return try withUnsafeBytes { try body(UnsafeRawBufferPointer(start: $0, count: count)) }
    }
}

extension DispatchData: HTTPResponseBody {
    /// :nodoc:
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        return try withUnsafeBytes { try body(UnsafeRawBufferPointer(start: $0, count: count)) }
    }
}

extension String: HTTPResponseBody {
    /// :nodoc:
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        return try ContiguousArray(utf8).withUnsafeBytes(body)
    }
}
