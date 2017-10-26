```
/// HTTP Request NOT INCLUDING THE BODY. This allows for streaming
public struct HTTPRequest {
    public var method : HTTPMethod
    public var target : String /* e.g. "/foo/bar?buz=qux" */
    public var httpVersion : HTTPVersion
    public var headers : HTTPHeaders
}

/// Object that code writes the response and response body to. 
public protocol HTTPResponseWriter : class {
    func writeHeader(status: HTTPResponseStatus, headers: HTTPHeaders, completion: @escaping (Result) -> Void)
    func writeTrailer(_ trailers: HTTPHeaders, completion: @escaping (Result) -> Void)
    func writeBody(_ data: UnsafeHTTPResponseBody, completion: @escaping (Result) -> Void)
    func done(completion: @escaping (Result) -> Void)
    func abort()
}

/// Convenience methods for HTTP response writer.
extension HTTPResponseWriter {
    public func writeHeader(status: HTTPResponseStatus, headers: HTTPHeaders)
    public func writeHeader(status: HTTPResponseStatus)
    public func writeTrailer(_ trailers: HTTPHeaders)
    public func writeBody(_ data: UnsafeHTTPResponseBody)
    public func done()
}

public protocol UnsafeHTTPResponseBody {
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

extension UnsafeRawBufferPointer : UnsafeHTTPResponseBody {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

public protocol HTTPResponseBody : UnsafeHTTPResponseBody {}

extension Data : HTTPResponseBody {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

extension DispatchData : HTTPResponseBody {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

extension String : HTTPResponseBody {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
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
public struct HTTPResponseStatus: Equatable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    public let code: Int
    public let reasonPhrase: String

    public init(code: Int, reasonPhrase: String)
    public init(code: Int)
    
    /* all the codes from http://www.iana.org/assignments/http-status-codes */
    public static let `continue`
    public static let switchingProtocols
    public static let ok
    public static let created
    public static let accepted
    public static let nonAuthoritativeInformation
    public static let noContent
    public static let resetContent
    public static let partialContent
    public static let multiStatus
    public static let alreadyReported
    public static let imUsed
    public static let multipleChoices
    public static let movedPermanently
    public static let found
    public static let seeOther
    public static let notModified
    public static let useProxy
    public static let temporaryRedirect
    public static let permanentRedirect
    public static let badRequest
    public static let unauthorized
    public static let paymentRequired
    public static let forbidden
    public static let notFound
    public static let methodNotAllowed
    public static let notAcceptable
    public static let proxyAuthenticationRequired
    public static let requestTimeout
    public static let conflict
    public static let gone
    public static let lengthRequired
    public static let preconditionFailed
    public static let payloadTooLarge
    public static let uriTooLong
    public static let unsupportedMediaType
    public static let rangeNotSatisfiable
    public static let expectationFailed
    public static let misdirectedRequest
    public static let unprocessableEntity
    public static let locked
    public static let failedDependency
    public static let upgradeRequired
    public static let preconditionRequired
    public static let tooManyRequests
    public static let requestHeaderFieldsTooLarge
    public static let unavailableForLegalReasons
    public static let internalServerError
    public static let notImplemented
    public static let badGateway
    public static let serviceUnavailable
    public static let gatewayTimeout
    public static let httpVersionNotSupported
    public static let variantAlsoNegotiates
    public static let insufficientStorage
    public static let loopDetected
    public static let notExtended
    public static let networkAuthenticationRequired

    public var `class`: Class

    public enum Class {
        case informational
        case successful
        case redirection
        case clientError
        case serverError
        case invalidStatus
    }
}

/// HTTP Methods handled by http_parser.[ch] supports
public struct HTTPMethod : Hashable, CustomStringConvertible, ExpressibleByIntegerLiteral {

    public let method: String

    public init(_ method: String)

    /* Constants for everything that http_parser.[ch] supports */
    public static let delete
    public static let get
    public static let head
    public static let post
    public static let put
    public static let connect
    public static let options
    public static let trace
    public static let copy
    public static let lock
    public static let mkcol
    public static let move
    public static let propfind
    public static let proppatch
    public static let search
    public static let unlock
    public static let bind
    public static let rebind
    public static let unbind
    public static let acl
    public static let report
    public static let mkactivity
    public static let checkout
    public static let merge
    public static let msearch
    public static let notify
    public static let subscribe
    public static let unsubscribe
    public static let patch
    public static let purge
    public static let mkcalendar
    public static let link
    public static let unlink
}
```
