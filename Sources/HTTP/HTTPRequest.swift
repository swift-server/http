// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation
import Dispatch

/// HTTP Request NOT INCLUDING THE BODY. This allows for streaming
public struct HTTPRequest {
    public var method: HTTPMethod
    public var target: URL
    public var httpVersion: HTTPVersion
    public var headers: HTTPHeaders
}

/// Method that takes a chunk of request body and is expected to write to the ResponseWriter
public typealias HTTPBodyHandler = (HTTPBodyChunk, inout Bool) -> Void /* the Bool can be set to true when we don't want to process anything further */

/// Indicates whether the body is going to be processed or ignored
public enum HTTPBodyProcessing {
    case discardBody /* if you're not interested in the body */
    case processBody(handler: HTTPBodyHandler)
}

/// Part (or maybe all) of the incoming request body
public enum HTTPBodyChunk {
    case chunk(data: DispatchData, finishedProcessing: () -> Void) /* a new bit of the HTTP request body has arrived, finishedProcessing() must be called when done with that chunk */
    case failed(error: /*HTTPParser*/ Error) /* error while streaming the HTTP request body, eg. connection closed */
    case trailer(key: String, value: String) /* trailer has arrived (this we actually haven't implemented yet) */
    case end /* body and trailers finished */
}

/// HTTP Methods handled by http_parser.[ch] supports
public enum HTTPMethod: RawRepresentable {
    /* be future-proof, http_parser can be upgraded */
    case other(String)
    
    /* everything that http_parser.[ch] supports */
    case DELETE
    case GET
    case HEAD
    case POST
    case PUT
    case CONNECT
    case OPTIONS
    case TRACE
    case COPY
    case LOCK
    case MKCOL
    case MOVE
    case PROPFIND
    case PROPPATCH
    case SEARCH
    case UNLOCK
    case BIND
    case REBIND
    case UNBIND
    case ACL
    case REPORT
    case MKACTIVITY
    case CHECKOUT
    case MERGE
    case MSEARCH
    case NOTIFY
    case SUBSCRIBE
    case UNSUBSCRIBE
    case PATCH
    case PURGE
    case MKCALENDAR
    case LINK
    case UNLINK
  
    public init(rawValue: String) {
        switch rawValue {
            case "DELETE":      self = .DELETE
            case "GET":         self = .GET
            case "HEAD":        self = .HEAD
            case "POST":        self = .POST
            case "PUT":         self = .PUT
            case "CONNECT":     self = .CONNECT
            case "OPTIONS":     self = .OPTIONS
            case "TRACE":       self = .TRACE
            case "COPY":        self = .COPY
            case "LOCK":        self = .LOCK
            case "MKCOL":       self = .MKCOL
            case "MOVE":        self = .MOVE
            case "PROPFIND":    self = .PROPFIND
            case "PROPPATCH":   self = .PROPPATCH
            case "SEARCH":      self = .SEARCH
            case "UNLOCK":      self = .UNLOCK
            case "BIND":        self = .BIND
            case "REBIND":      self = .REBIND
            case "UNBIND":      self = .UNBIND
            case "ACL":         self = .ACL
            case "REPORT":      self = .REPORT
            case "MKACTIVITY":  self = .MKACTIVITY
            case "CHECKOUT":    self = .CHECKOUT
            case "MERGE":       self = .MERGE
            case "MSEARCH":     self = .MSEARCH
            case "NOTIFY":      self = .NOTIFY
            case "SUBSCRIBE":   self = .SUBSCRIBE
            case "UNSUBSCRIBE": self = .UNSUBSCRIBE
            case "PATCH":       self = .PATCH
            case "PURGE":       self = .PURGE
            case "MKCALENDAR":  self = .MKCALENDAR
            case "LINK":        self = .LINK
            case "UNLINK":      self = .UNLINK
            default:            self = .other(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
            case .DELETE:           return "DELETE"
            case .GET:              return "GET"
            case .HEAD:             return "HEAD"
            case .POST:             return "POST"
            case .PUT:              return "PUT"
            case .CONNECT:          return "CONNECT"
            case .OPTIONS:          return "OPTIONS"
            case .TRACE:            return "TRACE"
            case .COPY:             return "COPY"
            case .LOCK:             return "LOCK"
            case .MKCOL:            return "MKCOL"
            case .MOVE:             return "MOVE"
            case .PROPFIND:         return "PROPFIND"
            case .PROPPATCH:        return "PROPPATCH"
            case .SEARCH:           return "SEARCH"
            case .UNLOCK:           return "UNLOCK"
            case .BIND:             return "BIND"
            case .REBIND:           return "REBIND"
            case .UNBIND:           return "UNBIND"
            case .ACL:              return "ACL"
            case .REPORT:           return "REPORT"
            case .MKACTIVITY:       return "MKACTIVITY"
            case .CHECKOUT:         return "CHECKOUT"
            case .MERGE:            return "MERGE"
            case .MSEARCH:          return "MSEARCH"
            case .NOTIFY:           return "NOTIFY"
            case .SUBSCRIBE:        return "SUBSCRIBE"
            case .UNSUBSCRIBE:      return "UNSUBSCRIBE"
            case .PATCH:            return "PATCH"
            case .PURGE:            return "PURGE"
            case .MKCALENDAR:       return "MKCALENDAR"
            case .LINK:             return "LINK"
            case .UNLINK:           return "UNLINK"
            case .other(let value): return value
        }
    }
}
