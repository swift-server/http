```
/// HTTP Request NOT INCLUDING THE BODY. This allows for streaming
public struct HTTPRequest {
    public var method : HTTPMethod
    public var target : String /* e.g. "/foo/bar?buz=qux" */
    public var httpVersion : HTTPVersion
    public var headers : HTTPHeaders
}

/// HTTP Response NOT INCLUDING THE BODY
public struct HTTPResponse {
    public var httpVersion : HTTPVersion
    public var status: HTTPResponseStatus
    public var transferEncoding: HTTPTransferEncoding
    public var headers: HTTPHeaders
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

/// Headers structure.
public struct HTTPHeaders {
    var storage: [String:[String]]     /* lower cased keys */
    var original: [(String, String)]   /* original casing */
    let description: String
    
    public subscript(key: String) -> [String]
    func makeIterator() -> IndexingIterator<Array<(String, String)>>
    
    public init(_ headers: [(String, String)] = [])
}

/// Version number of the HTTP Protocol
public typealias HTTPVersion = (Int, Int)

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
    
    public var code: UInt16 
    
    public static func from(code: UInt16) -> HTTPResponseStatus?

}

/// HTTP Methods handled by http_parser.[ch] supports
public enum HTTPMethod : RawRepresentable {
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
}
```
