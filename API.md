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
}

extension HTTPResponseStatus {
    public var reasonPhrase: String { get }
    public var code: UInt16  { get }
    
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
