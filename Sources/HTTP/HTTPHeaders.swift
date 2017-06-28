/// Headers structure.
public struct HTTPHeaders {
    var original: [(name: Name, value: String)]?
    var storage: [Name: [String]] {
        didSet { original = nil }
    }

    public subscript(name: Name) -> String? {
        get {
            guard let value = storage[name] else { return nil }
            switch name {
                case Name.setCookie: // Exception, see note in [RFC7230, section 3.2.2]
                    return value.isEmpty ? nil : value[0]
                default:
                    return value.joined(separator: ",")
            }
        }
        set {
            storage[name] = newValue.map { [$0] }
        }
    }

    public subscript(valuesFor name: Name) -> [String] {
        get { return storage[name] ?? [] }
        set { storage[name] = newValue.isEmpty ? nil : newValue }
    }
}

extension HTTPHeaders : ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral: (Name, String)...) {
        storage = [:]
        for (name, value) in dictionaryLiteral {
#if swift(>=4.0)
            storage[name, default: []].append(value)
#else
            if storage[name] == nil {
                storage[name] = [value]
            } else {
                storage[name]!.append(value)
            }
#endif
        }
        original = dictionaryLiteral
    }
}

extension HTTPHeaders {
    // Used instead of HTTPHeaders to save CPU on dictionary construction
    public struct Literal : ExpressibleByDictionaryLiteral {
        let fields: [(name: Name, value: String)]

        public init(dictionaryLiteral: (Name, String)...) {
            fields = dictionaryLiteral
        }
    }

    public mutating func append(_ literal: HTTPHeaders.Literal) {
        for (name, value) in literal.fields {
#if swift(>=4.0)
            storage[name, default: []].append(value)
#else
            if storage[name] == nil {
                storage[name] = [value]
            } else {
                storage[name]!.append(value)
            }
#endif
        }
    }

    public mutating func replace(_ literal: HTTPHeaders.Literal) {
        for (name, _) in literal.fields {
            storage[name] = []
        }
        for (name, value) in literal.fields {
            storage[name]!.append(value)
        }
    }
}

extension HTTPHeaders : Sequence {
    public func makeIterator() -> AnyIterator<(name: Name, value: String)> {
        if let original = original {
            return AnyIterator(original.makeIterator())
        } else {
            return AnyIterator(StorageIterator(storage.makeIterator()))
        }
    }

    struct StorageIterator : IteratorProtocol {
        var headers: DictionaryIterator<Name, [String]>
        var header: (name: Name, values: IndexingIterator<[String]>)?

        init(_ iterator: DictionaryIterator<Name, [String]>) {
            headers = iterator
            header = headers.next().map { (name: $0.key, values: $0.value.makeIterator()) }
        }

        mutating func next() -> (name: Name, value: String)? {
            while header != nil {
                if let value = header!.values.next() {
                    return (name: header!.name, value: value)
                } else {
                    header = headers.next().map { (name: $0.key, values: $0.value.makeIterator()) }
                }
            }
            return nil
        }
    }
}

extension HTTPHeaders {
    public struct Name : Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
        let original: String
        let lowercased: String
        public let hashValue: Int

        public init(_ name: String) {
            original = name
            lowercased = name.lowercased()
            hashValue = lowercased.hashValue
        }

        public init(stringLiteral: String) {
            self.init(stringLiteral)
        }

        public init(unicodeScalarLiteral: String) {
            self.init(unicodeScalarLiteral)
        }

        public init(extendedGraphemeClusterLiteral: String) {
            self.init(extendedGraphemeClusterLiteral)
        }

        public var description: String {
            return original
        }

        public static func == (lhs: Name, rhs: Name) -> Bool {
            return lhs.lowercased == rhs.lowercased
        }

        // https://www.iana.org/assignments/message-headers/message-headers.xhtml
        // Permanent Message Header Field Names
        public static let aIM = Name("A-IM")
        public static let accept = Name("Accept")
        public static let acceptAdditions = Name("Accept-Additions")
        public static let acceptCharset = Name("Accept-Charset")
        public static let acceptDatetime = Name("Accept-Datetime")
        public static let acceptEncoding = Name("Accept-Encoding")
        public static let acceptFeatures = Name("Accept-Features")
        public static let acceptLanguage = Name("Accept-Language")
        public static let acceptPatch = Name("Accept-Patch")
        public static let acceptPost = Name("Accept-Post")
        public static let acceptRanges = Name("Accept-Ranges")
        public static let age = Name("Age")
        public static let allow = Name("Allow")
        public static let alpn = Name("ALPN")
        public static let altSvc = Name("Alt-Svc")
        public static let altUsed = Name("Alt-Used")
        public static let alternates = Name("Alternates")
        public static let applyToRedirectRef = Name("Apply-To-Redirect-Ref")
        public static let authenticationControl = Name("Authentication-Control")
        public static let authenticationInfo = Name("Authentication-Info")
        public static let authorization = Name("Authorization")
        public static let cExt = Name("C-Ext")
        public static let cMan = Name("C-Man")
        public static let cOpt = Name("C-Opt")
        public static let cPEP = Name("C-PEP")
        public static let cPEPInfo = Name("C-PEP-Info")
        public static let cacheControl = Name("Cache-Control")
        public static let calDAVTimezones = Name("CalDAV-Timezones")
        public static let close = Name("Close")
        public static let connection = Name("Connection")
        public static let contentBase = Name("Content-Base")
        public static let contentDisposition = Name("Content-Disposition")
        public static let contentEncoding = Name("Content-Encoding")
        public static let contentID = Name("Content-ID")
        public static let contentLanguage = Name("Content-Language")
        public static let contentLength = Name("Content-Length")
        public static let contentLocation = Name("Content-Location")
        public static let contentMD5 = Name("Content-MD5")
        public static let contentRange = Name("Content-Range")
        public static let contentScriptType = Name("Content-Script-Type")
        public static let contentStyleType = Name("Content-Style-Type")
        public static let contentType = Name("Content-Type")
        public static let contentVersion = Name("Content-Version")
        public static let cookie = Name("Cookie")
        public static let cookie2 = Name("Cookie2")
        public static let dasl = Name("DASL")
        public static let dav = Name("DAV")
        public static let date = Name("Date")
        public static let defaultStyle = Name("Default-Style")
        public static let deltaBase = Name("Delta-Base")
        public static let depth = Name("Depth")
        public static let derivedFrom = Name("Derived-From")
        public static let destination = Name("Destination")
        public static let differentialID = Name("Differential-ID")
        public static let digest = Name("Digest")
        public static let eTag = Name("ETag")
        public static let expect = Name("Expect")
        public static let expires = Name("Expires")
        public static let ext = Name("Ext")
        public static let forwarded = Name("Forwarded")
        public static let from = Name("From")
        public static let getProfile = Name("GetProfile")
        public static let hobareg = Name("Hobareg")
        public static let host = Name("Host")
        public static let http2Settings = Name("HTTP2-Settings")
        public static let im = Name("IM")
        public static let `if` = Name("If")
        public static let ifMatch = Name("If-Match")
        public static let ifModifiedSince = Name("If-Modified-Since")
        public static let ifNoneMatch = Name("If-None-Match")
        public static let ifRange = Name("If-Range")
        public static let ifScheduleTagMatch = Name("If-Schedule-Tag-Match")
        public static let ifUnmodifiedSince = Name("If-Unmodified-Since")
        public static let keepAlive = Name("Keep-Alive")
        public static let label = Name("Label")
        public static let lastModified = Name("Last-Modified")
        public static let link = Name("Link")
        public static let location = Name("Location")
        public static let lockToken = Name("Lock-Token")
        public static let man = Name("Man")
        public static let maxForwards = Name("Max-Forwards")
        public static let mementoDatetime = Name("Memento-Datetime")
        public static let meter = Name("Meter")
        public static let mimeVersion = Name("MIME-Version")
        public static let negotiate = Name("Negotiate")
        public static let opt = Name("Opt")
        public static let optionalWWWAuthenticate = Name("Optional-WWW-Authenticate")
        public static let orderingType = Name("Ordering-Type")
        public static let origin = Name("Origin")
        public static let overwrite = Name("Overwrite")
        public static let p3p = Name("P3P")
        public static let pep = Name("PEP")
        public static let picsLabel = Name("PICS-Label")
        public static let pepInfo = Name("Pep-Info")
        public static let position = Name("Position")
        public static let pragma = Name("Pragma")
        public static let prefer = Name("Prefer")
        public static let preferenceApplied = Name("Preference-Applied")
        public static let profileObject = Name("ProfileObject")
        public static let `protocol` = Name("Protocol")
        public static let protocolInfo = Name("Protocol-Info")
        public static let protocolQuery = Name("Protocol-Query")
        public static let protocolRequest = Name("Protocol-Request")
        public static let proxyAuthenticate = Name("Proxy-Authenticate")
        public static let proxyAuthenticationInfo = Name("Proxy-Authentication-Info")
        public static let proxyAuthorization = Name("Proxy-Authorization")
        public static let proxyFeatures = Name("Proxy-Features")
        public static let proxyInstruction = Name("Proxy-Instruction")
        public static let `public` = Name("Public")
        public static let publicKeyPins = Name("Public-Key-Pins")
        public static let publicKeyPinsReportOnly = Name("Public-Key-Pins-Report-Only")
        public static let range = Name("Range")
        public static let redirectRef = Name("Redirect-Ref")
        public static let referer = Name("Referer")
        public static let retryAfter = Name("Retry-After")
        public static let safe = Name("Safe")
        public static let scheduleReply = Name("Schedule-Reply")
        public static let scheduleTag = Name("Schedule-Tag")
        public static let secWebSocketAccept = Name("Sec-WebSocket-Accept")
        public static let secWebSocketExtensions = Name("Sec-WebSocket-Extensions")
        public static let secWebSocketKey = Name("Sec-WebSocket-Key")
        public static let secWebSocketProtocol = Name("Sec-WebSocket-Protocol")
        public static let secWebSocketVersion = Name("Sec-WebSocket-Version")
        public static let securityScheme = Name("Security-Scheme")
        public static let server = Name("Server")
        public static let setCookie = Name("Set-Cookie")
        public static let setCookie2 = Name("Set-Cookie2")
        public static let setProfile = Name("SetProfile")
        public static let slug = Name("SLUG")
        public static let soapAction = Name("SoapAction")
        public static let statusURI = Name("Status-URI")
        public static let strictTransportSecurity = Name("Strict-Transport-Security")
        public static let surrogateCapability = Name("Surrogate-Capability")
        public static let surrogateControl = Name("Surrogate-Control")
        public static let tcn = Name("TCN")
        public static let te = Name("TE")
        public static let timeout = Name("Timeout")
        public static let topic = Name("Topic")
        public static let trailer = Name("Trailer")
        public static let transferEncoding = Name("Transfer-Encoding")
        public static let ttl = Name("TTL")
        public static let urgency = Name("Urgency")
        public static let uri = Name("URI")
        public static let upgrade = Name("Upgrade")
        public static let userAgent = Name("User-Agent")
        public static let variantVary = Name("Variant-Vary")
        public static let vary = Name("Vary")
        public static let via = Name("Via")
        public static let wwwAuthenticate = Name("WWW-Authenticate")
        public static let wantDigest = Name("Want-Digest")
        public static let warning = Name("Warning")
        public static let xFrameOptions = Name("X-Frame-Options")

        // https://www.iana.org/assignments/message-headers/message-headers.xhtml
        // Provisional Message Header Field Names
        public static let accessControl = Name("Access-Control")
        public static let accessControlAllowCredentials = Name("Access-Control-Allow-Credentials")
        public static let accessControlAllowHeaders = Name("Access-Control-Allow-Headers")
        public static let accessControlAllowMethods = Name("Access-Control-Allow-Methods")
        public static let accessControlAllowOrigin = Name("Access-Control-Allow-Origin")
        public static let accessControlMaxAge = Name("Access-Control-Max-Age")
        public static let accessControlRequestMethod = Name("Access-Control-Request-Method")
        public static let accessControlRequestHeaders = Name("Access-Control-Request-Headers")
        public static let compliance = Name("Compliance")
        public static let contentTransferEncoding = Name("Content-Transfer-Encoding")
        public static let cost = Name("Cost")
        public static let ediintFeatures = Name("EDIINT-Features")
        public static let messageID = Name("Message-ID")
        public static let methodCheck = Name("Method-Check")
        public static let methodCheckExpires = Name("Method-Check-Expires")
        public static let nonCompliance = Name("Non-Compliance")
        public static let optional = Name("Optional")
        public static let refererRoot = Name("Referer-Root")
        public static let resolutionHint = Name("Resolution-Hint")
        public static let resolverLocation = Name("Resolver-Location")
        public static let subOK = Name("SubOK")
        public static let subst = Name("Subst")
        public static let title = Name("Title")
        public static let uaColor = Name("UA-Color")
        public static let uaMedia = Name("UA-Media")
        public static let uaPixels = Name("UA-Pixels")
        public static let uaResolution = Name("UA-Resolution")
        public static let uaWindowpixels = Name("UA-Windowpixels")
        public static let version = Name("Version")
        public static let xDeviceAccept = Name("X-Device-Accept")
        public static let xDeviceAcceptCharset = Name("X-Device-Accept-Charset")
        public static let xDeviceAcceptEncoding = Name("X-Device-Accept-Encoding")
        public static let xDeviceAcceptLanguage = Name("X-Device-Accept-Language")
        public static let xDeviceUserAgent = Name("X-Device-User-Agent")
    }
}
