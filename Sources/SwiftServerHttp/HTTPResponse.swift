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
public enum HTTPResponseStatus: RawRepresentable, Equatable {
    /* be future-proof, new status codes can appear */
    case other(statusCode: UInt16, reasonPhrase: String)
    
    /* all the codes from http://www.iana.org/assignments/http-status-codes */
    case `continue`
    case switchingProtocols
    case processing
    case ok
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent
    case multiStatus
    case alreadyReported
    case imUsed
    case multipleChoices
    case movedPermanently
    case found
    case seeOther
    case notModified
    case useProxy
    case temporaryRedirect
    case permanentRedirect
    case badRequest
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case proxyAuthenticationRequired
    case requestTimeout
    case conflict
    case gone
    case lengthRequired
    case preconditionFailed
    case payloadTooLarge
    case uriTooLong
    case unsupportedMediaType
    case rangeNotSatisfiable
    case expectationFailed
    case misdirectedRequest
    case unprocessableEntity
    case locked
    case failedDependency
    case upgradeRequired
    case preconditionRequired
    case tooManyRequests
    case requestHeaderFieldsTooLarge
    case unavailableForLegalReasons
    case internalServerError
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    case variantAlsoNegotiates
    case insufficientStorage
    case loopDetected
    case notExtended
    case networkAuthenticationRequired

    public init(rawValue: UInt16) {
        switch rawValue {
            case 100: self = .continue
            case 101: self = .switchingProtocols
            case 102: self = .processing
            case 200: self = .ok
            case 201: self = .created
            case 202: self = .accepted
            case 203: self = .nonAuthoritativeInformation
            case 204: self = .noContent
            case 205: self = .resetContent
            case 206: self = .partialContent
            case 207: self = .multiStatus
            case 208: self = .alreadyReported
            case 226: self = .imUsed
            case 300: self = .multipleChoices
            case 301: self = .movedPermanently
            case 302: self = .found
            case 303: self = .seeOther
            case 304: self = .notModified
            case 305: self = .useProxy
            case 307: self = .temporaryRedirect
            case 308: self = .permanentRedirect
            case 400: self = .badRequest
            case 401: self = .unauthorized
            case 402: self = .paymentRequired
            case 403: self = .forbidden
            case 404: self = .notFound
            case 405: self = .methodNotAllowed
            case 406: self = .notAcceptable
            case 407: self = .proxyAuthenticationRequired
            case 408: self = .requestTimeout
            case 409: self = .conflict
            case 410: self = .gone
            case 411: self = .lengthRequired
            case 412: self = .preconditionFailed
            case 413: self = .payloadTooLarge
            case 414: self = .uriTooLong
            case 415: self = .unsupportedMediaType
            case 416: self = .rangeNotSatisfiable
            case 417: self = .expectationFailed
            case 421: self = .misdirectedRequest
            case 422: self = .unprocessableEntity
            case 423: self = .locked
            case 424: self = .failedDependency
            case 426: self = .upgradeRequired
            case 428: self = .preconditionRequired
            case 429: self = .tooManyRequests
            case 431: self = .requestHeaderFieldsTooLarge
            case 451: self = .unavailableForLegalReasons
            case 500: self = .internalServerError
            case 501: self = .notImplemented
            case 502: self = .badGateway
            case 503: self = .serviceUnavailable
            case 504: self = .gatewayTimeout
            case 505: self = .httpVersionNotSupported
            case 506: self = .variantAlsoNegotiates
            case 507: self = .insufficientStorage
            case 508: self = .loopDetected
            case 510: self = .notExtended
            case 511: self = .networkAuthenticationRequired
            default:  self = .other(statusCode: rawValue, reasonPhrase: "http_\(rawValue)")
        }
    }
    public var rawValue: UInt16 {
        switch self {
            case .continue:                      return 100
            case .switchingProtocols:            return 101
            case .processing:                    return 102
            case .ok:                            return 200
            case .created:                       return 201
            case .accepted:                      return 202
            case .nonAuthoritativeInformation:   return 203
            case .noContent:                     return 204
            case .resetContent:                  return 205
            case .partialContent:                return 206
            case .multiStatus:                   return 207
            case .alreadyReported:               return 208
            case .imUsed:                        return 226
            case .multipleChoices:               return 300
            case .movedPermanently:              return 301
            case .found:                         return 302
            case .seeOther:                      return 303
            case .notModified:                   return 304
            case .useProxy:                      return 305
            case .temporaryRedirect:             return 307
            case .permanentRedirect:             return 308
            case .badRequest:                    return 400
            case .unauthorized:                  return 401
            case .paymentRequired:               return 402
            case .forbidden:                     return 403
            case .notFound:                      return 404
            case .methodNotAllowed:              return 405
            case .notAcceptable:                 return 406
            case .proxyAuthenticationRequired:   return 407
            case .requestTimeout:                return 408
            case .conflict:                      return 409
            case .gone:                          return 410
            case .lengthRequired:                return 411
            case .preconditionFailed:            return 412
            case .payloadTooLarge:               return 413
            case .uriTooLong:                    return 414
            case .unsupportedMediaType:          return 415
            case .rangeNotSatisfiable:           return 416
            case .expectationFailed:             return 417
            case .misdirectedRequest:            return 421
            case .unprocessableEntity:           return 422
            case .locked:                        return 423
            case .failedDependency:              return 424
            case .upgradeRequired:               return 426
            case .preconditionRequired:          return 428
            case .tooManyRequests:               return 429
            case .requestHeaderFieldsTooLarge:   return 431
            case .unavailableForLegalReasons:    return 451
            case .internalServerError:           return 500
            case .notImplemented:                return 501
            case .badGateway:                    return 502
            case .serviceUnavailable:            return 503
            case .gatewayTimeout:                return 504
            case .httpVersionNotSupported:       return 505
            case .variantAlsoNegotiates:         return 506
            case .insufficientStorage:           return 507
            case .loopDetected:                  return 508
            case .notExtended:                   return 510
            case .networkAuthenticationRequired: return 511
            case .other(let code, _):            return code
        }
    }
  
    public static func ==(lhs: HTTPResponseStatus, rhs: HTTPResponseStatus)
                       -> Bool
    {
        return lhs.rawValue == rhs.rawValue
    }
}

extension HTTPResponseStatus {
    public var reasonPhrase: String {
        switch(self) {
            case .other(_, let reasonPhrase): return reasonPhrase
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


