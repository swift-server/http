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
public struct HTTPHeaders : Sequence, ExpressibleByDictionaryLiteral {
    public subscript(name: Name) -> String?
    public subscript(valuesFor name: Name) -> [String]

    public struct Literal : ExpressibleByDictionaryLiteral { }
    public mutating func append(_ literal: HTTPHeaders.Literal)
    public mutating func replace(_ literal: HTTPHeaders.Literal)

    public func makeIterator() -> AnyIterator<(name: Name, value: String)>

    public struct Name : Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
        public init(_ name: String)

        // https://www.iana.org/assignments/message-headers/message-headers.xhtml
        // Permanent Message Header Field Names
        public static let aIM
        public static let accept
        public static let acceptAdditions
        public static let acceptCharset
        public static let acceptDatetime
        public static let acceptEncoding
        public static let acceptFeatures
        public static let acceptLanguage
        public static let acceptPatch
        public static let acceptPost
        public static let acceptRanges
        public static let age
        public static let allow
        public static let alpn
        public static let altSvc
        public static let altUsed
        public static let alternates
        public static let applyToRedirectRef
        public static let authenticationControl
        public static let authenticationInfo
        public static let authorization
        public static let cExt
        public static let cMan
        public static let cOpt
        public static let cPEP
        public static let cPEPInfo
        public static let cacheControl
        public static let calDAVTimezones
        public static let close
        public static let connection
        public static let contentBase
        public static let contentDisposition
        public static let contentEncoding
        public static let contentID
        public static let contentLanguage
        public static let contentLength
        public static let contentLocation
        public static let contentMD5
        public static let contentRange
        public static let contentScriptType
        public static let contentStyleType
        public static let contentType
        public static let contentVersion
        public static let cookie
        public static let cookie2
        public static let dasl
        public static let dav
        public static let date
        public static let defaultStyle
        public static let deltaBase
        public static let depth
        public static let derivedFrom
        public static let destination
        public static let differentialID
        public static let digest
        public static let eTag
        public static let expect
        public static let expires
        public static let ext
        public static let forwarded
        public static let from
        public static let getProfile
        public static let hobareg
        public static let host
        public static let http2Settings
        public static let im
        public static let `if`
        public static let ifMatch
        public static let ifModifiedSince
        public static let ifNoneMatch
        public static let ifRange
        public static let ifScheduleTagMatch
        public static let ifUnmodifiedSince
        public static let keepAlive
        public static let label
        public static let lastModified
        public static let link
        public static let location
        public static let lockToken
        public static let man
        public static let maxForwards
        public static let mementoDatetime
        public static let meter
        public static let mimeVersion
        public static let negotiate
        public static let opt
        public static let optionalWWWAuthenticate
        public static let orderingType
        public static let origin
        public static let overwrite
        public static let p3p
        public static let pep
        public static let picsLabel
        public static let pepInfo
        public static let position
        public static let pragma
        public static let prefer
        public static let preferenceApplied
        public static let profileObject
        public static let `protocol`
        public static let protocolInfo
        public static let protocolQuery
        public static let protocolRequest
        public static let proxyAuthenticate
        public static let proxyAuthenticationInfo
        public static let proxyAuthorization
        public static let proxyFeatures
        public static let proxyInstruction
        public static let `public`
        public static let publicKeyPins
        public static let publicKeyPinsReportOnly
        public static let range
        public static let redirectRef
        public static let referer
        public static let retryAfter
        public static let safe
        public static let scheduleReply
        public static let scheduleTag
        public static let secWebSocketAccept
        public static let secWebSocketExtensions
        public static let secWebSocketKey
        public static let secWebSocketProtocol
        public static let secWebSocketVersion
        public static let securityScheme
        public static let server
        public static let setCookie
        public static let setCookie2
        public static let setProfile
        public static let slug
        public static let soapAction
        public static let statusURI
        public static let strictTransportSecurity
        public static let surrogateCapability
        public static let surrogateControl
        public static let tcn
        public static let te
        public static let timeout
        public static let topic
        public static let trailer
        public static let transferEncoding
        public static let ttl
        public static let urgency
        public static let uri
        public static let upgrade
        public static let userAgent
        public static let variantVary
        public static let vary
        public static let via
        public static let wwwAuthenticate
        public static let wantDigest
        public static let warning
        public static let xFrameOptions

        // https://www.iana.org/assignments/message-headers/message-headers.xhtml
        // Provisional Message Header Field Names
        public static let accessControl
        public static let accessControlAllowCredentials
        public static let accessControlAllowHeaders
        public static let accessControlAllowMethods
        public static let accessControlAllowOrigin
        public static let accessControlMaxAge
        public static let accessControlRequestMethod
        public static let accessControlRequestHeaders
        public static let compliance
        public static let contentTransferEncoding
        public static let cost
        public static let ediintFeatures
        public static let messageID
        public static let methodCheck
        public static let methodCheckExpires
        public static let nonCompliance
        public static let optional
        public static let refererRoot
        public static let resolutionHint
        public static let resolverLocation
        public static let subOK
        public static let subst
        public static let title
        public static let uaColor
        public static let uaMedia
        public static let uaPixels
        public static let uaResolution
        public static let uaWindowpixels
        public static let version
        public static let xDeviceAccept
        public static let xDeviceAcceptCharset
        public static let xDeviceAcceptEncoding
        public static let xDeviceAcceptLanguage
        public static let xDeviceUserAgent
    }
}

/// Version number of the HTTP Protocol
public struct HTTPVersion {
    /// Major version component.
    public var major: Int
    /// Minor version component.
    public var minor: Int
    
    public init(major: Int, minor: Int)
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
