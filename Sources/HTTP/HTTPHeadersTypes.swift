// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation

extension HTTPHeaders {
    /// Defines HTTP Authorization request.
    /// - Note: Paramters may be quoted or not according to RFCs.
    /// - Note: Quotation in parameters' values are preserved as is.
    public enum Authorization: RawRepresentable {
        /// Basic base64-encoded method [RFC7617](http://www.iana.org/go/rfc7617)
        case basic(user: String, password: String)
        /// Digest method [RFC7616](http://www.iana.org/go/rfc7616)
        case digest(params: [String: String])
        /// OAuth 1.0 method (OAuth) [RFC5849, Section 3.5.1](http://www.iana.org/go/rfc5849)
        case oAuth1(token: String)
        /// OAuth 2.0 method (Bearer) [RFC6750](http://www.iana.org/go/rfc6750)
        case oAuth2(token: String)
        /// Mututal method [RFC8120](http://www.iana.org/go/rfc8120)
        case mutual(params: [String: String])
        /// Negotiate method for Kerberos and NTLM [RFC4559, Section 3](http://www.iana.org/go/rfc4559)
        case negotiate(data: Data)
        /// Custom authentication method
        case custom(String, token: String?, params: [String: String])
        
        public init?(rawValue: String) {
            let sep = rawValue.components(separatedBy: " ")
            guard let type = sep.first?.trimmingCharacters(in: .whitespaces), !type.isEmpty else {
                return nil
            }
            let q = sep.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)
            switch type.lowercased() {
            case "basic":
                guard let data = Data(base64Encoded: q) else { return nil }
                guard let paramStr = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else { return nil }
                let decoded = paramStr.components(separatedBy: ":")
                guard let user = decoded.first else { return nil }
                let pass = decoded.dropFirst().joined(separator: ":")
                self = .basic(user: user, password: pass)
            case "digest":
                self = .digest(params: HTTPHeaders.parseParams(q))
            case "oauth":
                self = .oAuth1(token: q)
            case "bearer":
                self = .oAuth2(token: q)
            case "mutual":
                self = .mutual(params: HTTPHeaders.parseParams(q))
            case "negotiate":
                guard let data = Data(base64Encoded: q) else { return nil }
                self = .negotiate(data: data)
            default:
                if let token = sep.dropFirst().first, !token.contains(";") {
                    let qFixed = sep.dropFirst(2).joined(separator: " ")
                    self = .custom(type, token: token, params: HTTPHeaders.parseParams(qFixed))
                } else {
                    self = .custom(type, token: nil, params: HTTPHeaders.parseParams(q))
                }
            }
        }
        
        public var rawValue: String {
            switch self {
            case .basic(let user, let password):
                let text = "\(user):\(password)"
                let b64 = (text.data(using: .ascii) ?? text.data(using: .utf8))?.base64EncodedString() ?? ""
                return "Basic \(b64)"
            case .digest(let params):
                let nonquotedKeys: [String] = ["stale", "algorithm", "nc", "charset", "userhash", "qop"]
                let paramsString = HTTPHeaders.createParam(params, quotationValue: true, nonquotatedKeys: nonquotedKeys, separator: ", ")
                return "Digest \(paramsString)"
            case .oAuth1(let token):
                return "OAuth \(token)"
            case .oAuth2(let token):
                return "Bearer \(token)"
            case .mutual(let params):
                let nonquotedKeys: [String] = ["sid", "nc"]
                let paramsString = HTTPHeaders.createParam(params, quotationValue: true, nonquotatedKeys: nonquotedKeys, separator: ", ")
                return "Mutual \(paramsString)"
            case .negotiate(let data):
                return "Negotiate \(data.base64EncodedString())"
            case .custom(let type, let token, let params):
                let tokenString = token.flatMap({ "\($0) " }) ?? ""
                let paramsString = HTTPHeaders.createParam(params)
                return "\(type) \(tokenString)\(paramsString)"
            }
        }
    }
    
    /// Values available for `Cache-Control` header.
    public enum CacheControl: RawRepresentable, Equatable {
        // Both Request and Response
        
        /// `no-cache` header value. The cache should not store anything about the client request or server response.
        case noCache
        /// `no-store` header value.
        case noStore
        /// `no-transform` header value. No transformations or conversions should be made to the resource.
        /// The Content-Encoding, Content-Range, Content-Type headers must not be modified by a proxy.
        case noTransform
        /// `max-age=<seconds>` header value. Specifies the maximum amount of
        /// relative time a resource will be considered fresh.
        case maxAge(TimeInterval)
        /// custom header value undefined in `CacheControl` enum, parsed as `name=value` if there is
        /// a value or `name` if no value is provided.
        ///
        /// `immutable`, `stale-while-revalidate=<seconds>`
        case custom(String, value: String?)
        
        // Only Request
        
        /// `only-if-cached` header value, should be used in request header only. Indicates to
        /// not retrieve new data. The client only wishes to obtain a cached response,
        /// and should not contact the origin-server to see if a newer copy exists.
        case onlyIfCached
        /// `max-stale=<seconds>` header value, should be used in request header only.
        /// Indicates that the client is willing to accept a response that has exceeded its expiration time.
        case maxStale(TimeInterval)
        /// `min-fresh=<seconds>` header value, should be used in request header only.
        /// Indicates that the client wants a response that will still be fresh for at least
        /// the specified number of seconds.
        case minFresh(TimeInterval)
        
        // Only Response
        
        /// `public` header value, should be used in response header only.
        /// Indicates that the response may be cached by any cache.
        case `public`
        /// `private` header value, should be used in response header only.
        /// Indicates that the response is intended for a single user and must not be stored by
        /// a shared cache. A private cache may store the response.
        case `private`
        /// `private=<field>` header value, should be used in response header only.
        /// Indicates that the response is intended for a single user and must not be stored by
        /// a shared cache. A private cache may store the response limited to the field-values
        /// associated with the listed response header fields.
        case privateWithField(field: String)
        /// `no-cache=<field>` header value, should be used in response header only.
        /// Forces caches to submit the request to the origin server for validation before releasing a
        /// cached copy limited to the field-values associated with the listed response header fields.
        case noCacheWithField(field: String)
        /// `must-revalidate` header value, should be used in response header only.
        /// The cache must verify the status of the stale resources before using it and
        /// expired ones should not be used.
        case mustRevalidate
        /// `proxy-revalidate` header value, should be used in response header only.
        /// Same as `must-revalidate`, but it only applies to shared caches (e.g., proxies)
        /// and is ignored by a private cache.
        case proxyRevalidate
        /// `s-maxage=<seconds>` header value, should be used in response header only.
        /// Overrides `max-age` or the `Expires` header, but it only applies to shared caches\
        /// (e.g., proxies) and is ignored by a private cache.
        case sMaxAge(TimeInterval)
        
        public var rawValue: String {
            switch self {
            case .noCache:
                return "no-cache"
            case .noStore:
                return "no-store"
            case .noTransform:
                return "no-transform"
            case .maxAge(let interval):
                return "max-age=\(Int(interval))"
            case .onlyIfCached:
                return "only-if-cached"
            case .maxStale(let interval):
                return "max-stale=\(Int(interval))"
            case .minFresh(let interval):
                return "min-fresh=\(Int(interval))"
            case .`public`:
                return "public"
            case .`private`:
                return "private"
            case .privateWithField(field: let field):
                return "private=\"\(field)\""
            case .noCacheWithField(field: let field):
                return "no-cache=\"\(field)\""
            case .mustRevalidate:
                return "must-revalidate"
            case .proxyRevalidate:
                return "proxy-revalidate"
            case .sMaxAge(let interval):
                return "s-maxage=\(Int(interval))"
            case .custom(let name, value: let value):
                let v = value.flatMap({ "=\($0)" }) ?? ""
                return "\(name)\(v)"
            }
        }
        
        public init?(rawValue: String) {
            let keyVal = rawValue.components(separatedBy: "=").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard let key = keyVal.first?.lowercased() else { return nil }
            let val = keyVal.dropFirst().joined(separator: "=").trimmingCharacters(in: .quotedWhitespace)
            switch key {
            case "no-cache" where val.isEmpty:
                self = .noCache
            case "no-store":
                self = .noStore
            case "no-transform":
                self = .noTransform
            case "max-age":
                self = .maxAge(TimeInterval(val) ?? 0)
            case "only-if-cached":
                self = .onlyIfCached
            case "max-stale":
                self = .maxStale(TimeInterval(val) ?? 0)
            case "min-fresh":
                self = .minFresh(TimeInterval(val) ?? 0)
            case "public":
                self = .`public`
            case "private" where val.isEmpty:
                self = .`private`
            case "private":
                self = .privateWithField(field: val)
            case "no-cache":
                self = .noCacheWithField(field: val)
            case "must-revalidate":
                self = .mustRevalidate
            case "proxy-revalidate":
                self = .proxyRevalidate
            case "s-maxage":
                self = .sMaxAge(TimeInterval(val) ?? 0)
            default:
                let nameparam = rawValue.components(separatedBy: "=")
                guard let name = nameparam.first else { return nil }
                self = .custom(name, value: nameparam.dropFirst().first)
            }
        }
        
        /// :nodoc:
        public static func ==(lhs: HTTPHeaders.CacheControl, rhs: HTTPHeaders.CacheControl) -> Bool {
            switch (lhs, rhs) {
            case (.noCache, .noCache), (.noStore, .noStore), (.noTransform, .noTransform),
                 (.onlyIfCached, .onlyIfCached), (.`public`, .`public`), (.`private`, .`private`),
                 (.mustRevalidate, .mustRevalidate), (.proxyRevalidate, .proxyRevalidate):
                return true
            case let (.maxAge(l), .maxAge(r)), let (.maxStale(l), .maxStale(r)),
                 let (.minFresh(l), .minFresh(r)), let (.sMaxAge(l), .sMaxAge(r)):
                return Int(l) == Int(r)
            case let (.custom(ln, lv), .custom(rn, rv)):
                return ln == rn && lv == rv
            default:
                return false
            }
        }
    }
    
    /// Defines HTTP Authentication challenge method required to access.
    public enum ChallengeType: RawRepresentable, Hashable, Equatable {
        /// Basic method [RFC7617](http://www.iana.org/go/rfc7617)
        case basic
        /// Digest method [RFC7616](http://www.iana.org/go/rfc7616)
        case digest
        /// OAuth 1.0 method (OAuth) [RFC5849, Section 3.5.1](http://www.iana.org/go/rfc5849)
        case oAuth1
        /// OAuth 2.0 method (Bearer) [RFC6750](http://www.iana.org/go/rfc6750)
        case oAuth2
        /// Mututal method [RFC8120](http://www.iana.org/go/rfc8120)
        case mutual
        /// Negotiate method for Kerberos and NTLM [RFC4559, Section 3](http://www.iana.org/go/rfc4559)
        case negotiate
        /// Custom authentication method.
        case custom(String)
        
        public init(rawValue: String) {
            switch rawValue.lowercased() {
            case "basic":
                self = .basic
            case "digest":
                self = .digest
            case "oauth":
                self = .oAuth1
            case "bearer":
                self = .oAuth2
            case "mutual":
                self = .mutual
            case "negotiate":
                self = .negotiate
            default:
                self = .custom(rawValue.prefix(until: " ").trimmingCharacters(in: .whitespaces))
            }
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
        public var rawValue: String {
            switch self {
            case .basic: return "Basic"
            case .digest: return "Digest"
            case .oAuth1: return "OAuth"
            case .oAuth2: return "Bearer"
            case .mutual: return "Mutual"
            case .negotiate: return "Negotiate"
            case .custom(let type): return type
            }
        }
        
        public static func ==(lhs: HTTPHeaders.ChallengeType, rhs: HTTPHeaders.ChallengeType) -> Bool {
            switch (lhs, rhs) {
            case (.basic, .basic), (.digest, .digest), (.oAuth1, .oAuth1),
                 (.oAuth2, .oAuth2), (.mutual, .mutual), (.negotiate, .negotiate):
                return true
            case let (.custom(l), .custom(r)):
                return l == r
            default:
                return false
            }
        }
    }
    
    /// Challenge defined in WWW-Authenticate or Proxy-Authenticate.
    /// -Note: Paramters' quotations will be preserved for custom challenge type.
    public struct Challenge: RawRepresentable {
        /// Type of challenge
        public let type: ChallengeType
        /// All parameters associated to challenge
        public let parameters: [String: String]
        /// token parameter provided
        public var token: String?
        /// `realm` parameter without quotations
        public var realm: String? {
            return parameters["realm"]?.trimmingCharacters(in: .quoted)
        }
        /// `charset` parameter as String.Encoding
        public var charset: String.Encoding? {
            return parameters["charset"].flatMap(String.Encoding.init(ianaCharset:))
        }
        
        /// :nodoc:
        public subscript(parameterName: String) -> String? {
            get {
                return self.parameters[parameterName]?.trimmingCharacters(in: .quoted)
            }
        }
        
        /// Inits a noew
        public init(type: ChallengeType, token: String? = nil, realm: String? = nil, charset: String.Encoding? = nil, parameters: [String: String] = [:]) {
            self.type = type
            var parameters = parameters
            parameters["realm"] = realm?.trimmingCharacters(in: .quoted)
            parameters["charset"] = charset.flatMap({ $0.ianaCharset })
            if let token = token {
                parameters[token] = ""
            }
            self.parameters = parameters
        }
        
        public init?(rawValue: String) {
            let typeSegment = rawValue.components(separatedBy: " ")
            guard let type = typeSegment.first.flatMap(ChallengeType.init(rawValue:)) else { return nil }
            self.type = type
            let allparams = typeSegment.dropFirst().joined(separator: " ")
            let removeQ = type == .digest || type == .mutual
            let parsedParams = HTTPHeaders.parseParams(allparams, separator: ",", removeQuotation: removeQ)
            self.parameters = parsedParams
        }
        
        public var rawValue: String {
            switch type {
            case .digest:
                let nonquotedKeys: [String] = ["stale", "algorithm", "nc", "charset", "userhash"]
                let params = HTTPHeaders.createParam(parameters, quotationValue: true, nonquotatedKeys: nonquotedKeys, separator: ", ")
                return "\(type.rawValue) \(params)"
            case .mutual:
                let nonquotedKeys: [String] = ["sid", "nc"]
                let params = HTTPHeaders.createParam(parameters, quotationValue: true, nonquotatedKeys: nonquotedKeys, separator: ", ")
                return "\(type.rawValue) \(params)"
            default:
                let token = self.token.flatMap({ "\($0) "}) ?? ""
                let nonquotedKeys: [String] = ["charset"]
                let params = HTTPHeaders.createParam(parameters, quotationValue: true, nonquotatedKeys: nonquotedKeys, separator: ", ")
                return "\(type.rawValue) \(token)\(params)"
            }
        }
        
        static public func basic(realm: String? = nil, charset: String.Encoding? = .utf8, parameters: [String: String] = [:]) -> Challenge {
            return Challenge.init(type: .basic, realm: realm, charset: charset, parameters: parameters)
        }
        
        static public func digest(realm: String? = nil, parameters: [String: String] = [:]) -> Challenge {
            return Challenge.init(type: .digest, realm: realm, parameters: parameters)
        }
        
        static public func oAuth1(realm: String? = nil, parameters: [String: String] = [:]) -> Challenge {
            return Challenge.init(type: .oAuth1, realm: realm, parameters: parameters)
        }
        
        static public func oAuth2(realm: String? = nil, scope: String? = nil, parameters: [String: String] = [:]) -> Challenge {
            var params = parameters
            params["scope"] = scope
            return Challenge.init(type: .oAuth2, realm: realm, parameters: params)
        }
        
        static public func mutual(realm: String? = nil, parameters: [String: String] = [:]) -> Challenge {
            return Challenge.init(type: .mutual, realm: realm, parameters: parameters)
        }
        
        static public func negotiate(data: Data? = nil, parameters: [String: String] = [:]) -> Challenge {
            var params = parameters
            if let hexData = data?.map({ String(format: "%02hhx", $0) }).joined() {
                params[hexData] = ""
            }
            return Challenge.init(type: .negotiate, parameters: params)
        }
    }
    
    /// Content-Disposition type.
    public enum ContentDispositionType: String {
        /// Default value, which indicates file must be shown in browser.
        case inline
        /// Downloadable content, with specifed filename if available.
        case attachment
        /// Form-Data deposition type.
        case formData = "form-data"
    }
    
    /// Values available for `Content-Disposition` header.
    public struct ContentDisposition: RawRepresentable, Equatable {
        /// Content disposition type.
        public let type: ContentDispositionType
        /// All parameters associated to content disposition.
        public var parameters: [String: String]
        
        /// :nodoc:
        public subscript(parameterName: String) -> String? {
            get {
                return self.parameters[parameterName]
            }
            set {
                self.parameters[parameterName] = newValue
            }
        }
        
        // File name of content.
        public var filename: String? {
            get {
                return parameters["filename"]
            }
            set {
                // TOCHECK: Remove path component.
                parameters["filename"] = newValue
            }
        }
        
        // Name of `form-data` content.
        public var name: String? {
            get {
                return parameters["name"]
            }
            set {
                parameters["name"] = newValue
            }
        }
        
        // Modification date of contents.
        public var modificationDate: Date? {
            get {
                return parameters["modification-date"].flatMap(Date.init(rfcString:))
            }
            set {
                parameters["modification-date"] = newValue?.format(with: .http)
            }
        }
        
        // Modification date of contents.
        public var creationDate: Date? {
            get {
                return parameters["creation-datete"].flatMap(Date.init(rfcString:))
            }
            set {
                parameters["creation-date"] = newValue?.format(with: .http)
            }
        }
        
        public init(type: HTTPHeaders.ContentDispositionType, parameters: [String: String] = [:]) {
            self.type = type
            self.parameters = parameters
        }
        
        public init?(rawValue: String) {
            let (typeStr, params) = HTTPHeaders.parseParamsWithToken(rawValue, removeQuotation: true)
            guard let type = (typeStr?.lowercased()).flatMap(ContentDispositionType.init(rawValue:)) else {
                return nil
            }
            self.type = type
            self.parameters = params
        }
        
        public var rawValue: String {
            if parameters.isEmpty {
                return type.rawValue
            }
            let paramStr = HTTPHeaders.createParam(parameters, quotationValue: true)
            if paramStr.isEmpty {
                return type.rawValue
            } else {
                return "\(type.rawValue); \(paramStr)"
            }
        }
        
        /// :nodoc:
        public static func ==(lhs: HTTPHeaders.ContentDisposition, rhs: HTTPHeaders.ContentDisposition) -> Bool {
            return lhs.type == rhs.type && lhs.parameters == rhs.parameters
        }
        
        /// Default value, which indicates file must be shown in browser.
        public static let inline = ContentDisposition(type: .inline)
        
        /// Downloadable content, with specifed filename if available.
        public static func attachment(fileName: String? = nil) -> HTTPHeaders.ContentDisposition {
            let params: [String: String] = fileName.flatMap({ ["filename": $0 ] }) ?? [:]
            return self.init(type: .attachment, parameters: params)
        }
        
        /// Form-Data deposition.
        public static func formData(name: String? = nil, fileName: String? = nil) -> ContentDisposition {
            var params = [String: String]()
            name.flatMap({ params["name"] = $0 })
            fileName.flatMap({ params["filename"] = $0 })
            return self.init(type: .formData, parameters: params)
        }
    }
    
    /// MIME type directive for `Accept` and `Content-Type` headers.
    public struct MediaType: RawRepresentable, Hashable, Equatable, ExpressibleByStringLiteral {
        private let generalType: String
        private let subType: String
        public typealias RawValue = String
        public typealias StringLiteralType = String
        
        public init(rawValue: String) {
            let linted = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let slashIndex = linted.index(of: "/") else {
                self.generalType = linted
                self.subType = ""
                return
            }
            self.generalType = String(linted[linted.startIndex..<slashIndex])
            self.subType = String(linted[linted.index(after: slashIndex)...])
        }
        
        public init(stringLiteral: String) {
            self.init(rawValue: stringLiteral)
        }
        
        private init(generalType: String, type: String) {
            self.generalType = generalType
            self.subType = type
        }
        
        public var rawValue: String {
            return "\(generalType)/\(subType)"
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
        /// :nodoc:
        public static func == (lhs: MediaType, rhs: MediaType) -> Bool {
            return lhs.generalType == rhs.generalType &&  lhs.subType.replacingOccurrences(of: "x-", with: "", options: .anchored) == rhs.subType.replacingOccurrences(of: "x-", with: "", options: .anchored)
        }
        
        /// Returns true if media type provided in argument can be returned as `Content-Type`
        /// when this media type is provided by `Accept` header.
        public func canAccept(_ value: MediaType) -> Bool {
            // if self is */* it can accept any type
            if self == .all || (self.subType == "*" && self.generalType == value.generalType) {
                return true
            }
            
            // Removing nonstandard `x-` prefix
            // see [RFC 6838](https://tools.ietf.org/html/rfc6838)
            let selfType = self.subType.replacingOccurrences(of: "x-", with: "", options: .anchored)
            let valType = value.subType.replacingOccurrences(of: "x-", with: "", options: .anchored)
            
            // application and text are interchangable as in xml & json types.
            if valType == selfType {
                if self.generalType == value.generalType {
                    return true
                }
                let selfGType = self.generalType == "text" ? "application" : self.generalType
                let valGType = value.generalType == "text" ? "application" : value.generalType
                if selfGType == valGType {
                    return true
                }
            }
            
            return false
        }
        
        /// Directory
        static public let directory = MediaType(generalType: "text", type: "directory")
        /// Unix directory
        static public let unixDirectory = MediaType(generalType: "inode", type: "directory")
        /// Apache server's directory
        static public let apacheDirectory = MediaType(generalType: "httpd", type: "unix-directory")
        
        // Archive and Binary
        
        /// All types
        static public let all = MediaType(generalType: "*", type: "*")
        /// Binary stream and unknown types
        static public let stream = MediaType(generalType: "application", type: "octet-stream")
        /// Zip archive
        static public let zip = MediaType(generalType: "application", type: "zip")
        /// Protable document format
        static public let pdf = MediaType(generalType: "application", type: "pdf")
        /// ePub book
        static public let epub = MediaType(generalType: "application", type: "epub+zip")
        /// Java archive (jar)
        static public let javaArchive = MediaType(generalType: "application", type: "java-archive")
        
        // Texts
        
        /// All Text types
        static public let text = MediaType(generalType: "text", type: "*")
        /// Text file
        static public let plainText = MediaType(generalType: "text", type: "plain")
        /// Coma-separated values
        static public let csv = MediaType(generalType: "text", type: "csv")
        /// Hyper-text markup language
        static public let html = MediaType(generalType: "text", type: "html")
        /// Common style sheet
        static public let css = MediaType(generalType: "text", type: "css")
        /// eXtended Markup language
        static public let xml = MediaType(generalType: "text", type: "xml")
        /// eXtended Hyper-text markup language
        static public let xhtml = MediaType(generalType: "application", type: "xhtml+xml")
        /// Javascript code file
        static public let javascript = MediaType(generalType: "application", type: "javascript")
        /// Javascript notation
        static public let json = MediaType(generalType: "application", type: "json")
        
        // Images
        
        /// All Image types
        static public let image = MediaType(generalType: "image", type: "bmp")
        /// Bitmap
        static public let bmp = MediaType(generalType: "image", type: "bmp")
        /// Graphics Interchange Format photo
        static public let gif = MediaType(generalType: "image", type: "gif")
        /// JPEG photo
        static public let jpeg = MediaType(generalType: "image", type: "jpeg")
        /// Portable network graphics
        static public let png = MediaType(generalType: "image", type: "png")
        /// Scalable vector graphics
        static public let svg = MediaType(generalType: "image", type: "svg+xml")
        /// Scalable vector graphics
        static public let webp = MediaType(generalType: "image", type: "webp")
        
        // Audio & Video
        
        /// All Audio types
        static public let audio = MediaType(generalType: "audio", type: "*")
        /// All Video types
        static public let video = MediaType(generalType: "video", type: "*")
        /// MPEG Video
        static public let mpeg = MediaType(generalType: "video", type: "mpeg")
        /// MPEG Audio (including MP3)
        static public let mpegAudio = MediaType(generalType: "audio", type: "mpeg")
        /// MPEG4 Video
        static public let mpeg4 = MediaType(generalType: "video", type: "mp4")
        /// MPEG4 Audio
        static public let mpeg4Audio = MediaType(generalType: "audio", type: "mp4")
        /// Mpeg playlist
        static public let m3u8 = MediaType(generalType: "application", type: "vnd.apple.mpegurl")
        /// Mpeg playlist for Audio files
        static public let m3u8Audio = MediaType(generalType: "application", type: "vnd.apple.mpegurl.audio")
        /// Mpeg-2 transport stream
        static public let ts = MediaType(generalType: "video", type: "mp2t")
        /// OGG Audio
        static public let ogg = MediaType(generalType: "audio", type: "ogg")
        /// WebM Video
        static public let webm = MediaType(generalType: "video", type: "webm")
        /// WebM Audio
        static public let webmAudio = MediaType(generalType: "audio", type: "webm")
        /// Advanced Audio Coding
        static public let aac = MediaType(generalType: "audio", type: "aac")
        /// Microsoft Audio Video Interleaved
        static public let avi = MediaType(generalType: "video", type: "x-msvideo")
        /// Microsoft Wave audio
        static public let wav = MediaType(generalType: "audio", type: "wav")
        /// Apple QuickTime format
        static public let quicktime = MediaType(generalType: "video", type: "quicktime")
        /// 3GPP
        static public let threegp = MediaType(generalType: "video", type: "3gpp")
        
        // Font
        
        /// TrueType Font
        static public let ttf = MediaType(generalType: "font", type: "ttf")
        /// OpenType font
        static public let otf = MediaType(generalType: "font", type: "otf")
        /// Web Open Font Format
        static public let woff = MediaType(generalType: "font", type: "woff")
        /// Web Open Font Format 2
        static public let woff2 = MediaType(generalType: "font", type: "woff2")
        
        // Multipart
        
        /// Multipart mixed
        static public let multipart = MediaType(generalType: "multipart", type: "mixed")
        /// Multipart form-data
        static public let multipartFormData = MediaType(generalType: "multipart", type: "form-data")
        /// Multipart byteranges
        static public let multipartByteranges = MediaType(generalType: "multipart", type: "byteranges")
    }
    
    /// Media type and related parameters in Content-Type.
    public struct ContentType: RawRepresentable {
        /// Media type (MIME) of content
        public let mediaType: HTTPHeaders.MediaType
        /// All parameter provided with content type
        public var parameters: [String: String]
        /// charset parameter of content type
        public var charset: String.Encoding? {
            return parameters["charset"].flatMap(String.Encoding.init(ianaCharset:))
        }
        
        public init(type: HTTPHeaders.MediaType, charset: String.Encoding? = nil, parameters: [String: String] = [:]) {
            self.mediaType = type
            var parameters = parameters
            parameters["charset"] = charset.flatMap({ $0.ianaCharset })
            self.parameters = parameters
        }
        
        public init?(rawValue: String) {
            let typeSegment = rawValue.components(separatedBy: ";")
            guard let type = (typeSegment.first?.trimmingCharacters(in: .whitespaces))
                .flatMap(MediaType.init(rawValue:)) else { return nil }
            self.mediaType = type
            let allparams = typeSegment.dropFirst().joined(separator: ";")
            self.parameters = HTTPHeaders.parseParams(allparams)
        }
        
        /// :nodoc:
        public subscript(parameterName: String) -> String? {
            get {
                return self.parameters[parameterName]
            }
            set {
                self.parameters[parameterName] = newValue
            }
        }
        
        public var rawValue: String {
            let params = parameters.map({ " \($0.key)=\($0.value)" }).joined(separator: ";")
            if params.isEmpty {
                return "\(mediaType.rawValue)"
            } else {
                return "\(mediaType.rawValue);\(params)"
            }
            
        }
    }
    
    // Should we use enum? It's faster to compare.
    /// Encoding of body
    public struct Encoding: RawRepresentable, Hashable, Equatable {
        public var rawValue: String
        public typealias RawValue = String
        
        public init(rawValue: String) {
            let linted = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                .replacingOccurrences(of: "x-", with: "", options: .anchored)
            self.rawValue = linted
        }
        
        private init(linted: String) {
            self.rawValue = linted
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
        /// :nodoc:
        public static func == (lhs: Encoding, rhs: Encoding) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        /// Accepting all encodings available
        static public let all = Encoding(linted: "*")
        /// Sends body as is
        static public let identity = Encoding(linted: "identity")
        /// Compress body data using lzw method
        static public let compress = Encoding(linted: "compress")
        /// Compress body data using zlib deflate method
        static public let deflate = Encoding(linted: "deflate")
        /// Compress body data using gzip method
        static public let gzip = Encoding(linted: "gzip")
        /// Compress body data using bzip2 method
        static public let bzip2 = Encoding(linted: "bzip2")
        /// Compress body data using brotli method
        static public let brotli = Encoding(linted: "br")
        
        // These values are valid for Transfer Encoding
        
        /// Chunked body in `Transfer-Encoding` response header
        static public let chunked = Encoding(linted: "chunked")
        /// Can have trailers in `TE` request header
        static public let trailers = Encoding(linted: "trailers")
    }
    
    /// EntryTag used in `ETag`, `If-Modified`, etc.
    public enum EntryTag: RawRepresentable, Equatable, Hashable {
        /// Regular entry tag
        case strong(String)
        /// Weak entry tag prefixed with `"W/"`
        case weak(String)
        /// Equals to `"*"`
        case wildcard
        
        public init(rawValue: String) {
            let rawValue = rawValue.trimmingCharacters(in: .quoted)
            // Check begins with W/" in case-insensitive manner to indicate is weak or not
            if rawValue.range(of: "W/\"", options: [.anchored, .caseInsensitive]) != nil {
                let linted = rawValue.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "W/\"", with: "", options: [.anchored, .caseInsensitive])
                    .trimmingCharacters(in: .quotedWhitespace)
                self = .weak(linted)
                return
            }
            // Check value is wildcard
            if rawValue == "*" {
                self = .wildcard
                return
            }
            // Value is strong
            let linted = rawValue.trimmingCharacters(in: .quotedWhitespace)
            self = .strong(linted)
        }
        
        public var rawValue: String {
            switch self {
            case .strong(let etag):
                // TODO: Remove non ascii characters
                let lintedEtag = etag.trimmingCharacters(in: .quotedWhitespace)
                return "\"\(lintedEtag)\""
            case .weak(let etag):
                let lintedEtag = etag.replacingOccurrences(of: "W/\"", with: "", options: [.anchored, .caseInsensitive]).trimmingCharacters(in: .quotedWhitespace)
                return "W/\"\(lintedEtag)\""
            case .wildcard:
                return "*"
            }
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
        /// :nodoc:
        public static func ==(lhs: HTTPHeaders.EntryTag, rhs: HTTPHeaders.EntryTag) -> Bool {
            switch (lhs, rhs) {
            case (.wildcard, .wildcard):
                return true
            case let (.strong(l), .strong(r)),
                 let (.weak(l), .weak(r)):
                return l == r
            default:
                return false
            }
        }
    }
    
    /// Values for `If-Range` header.
    public enum IfRange: RawRepresentable, Equatable, Hashable {
        /// An entry tag for `If-Range` to be checked againt `ETag`
        case tag(EntryTag)
        /// an entry tag for `If-Range` to be checked againt `Last-Modified`
        case date(Date)
        
        public init(rawValue: String) {
            if let parsedDate = Date(rfcString: rawValue) {
                self = .date(parsedDate)
            } else {
                self = .tag(EntryTag(rawValue: rawValue))
            }
        }
        
        public var rawValue: String {
            switch self {
            case .date(let date):
                return date.format(with: .http)
            case .tag(let tag):
                return tag.rawValue
            }
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
        /// :nodoc:
        public static func ==(lhs: HTTPHeaders.IfRange, rhs: HTTPHeaders.IfRange) -> Bool {
            switch (lhs, rhs) {
            case let (.tag(l), .tag(r)):
                return l == r
            case let (.date(l), .date(r)):
                return l == r
            default:
                return false
            }
        }
    }
    
    /// How the connection and may be used to set a timeout and a maximum amount of requests.
    public struct KeepAlive: RawRepresentable, Hashable, Equatable {
        /// Minimum amount of time an idle connection has to be kept opened (in seconds).
        public let timeout: TimeInterval
        /// Maximum number of requests that can be sent on this connection before closing it.
        public var max: Int?
        
        public typealias RawValue = String
        
        public init?(rawValue: String) {
            let params = HTTPHeaders.parseParams(rawValue, removeQuotation: true)
            guard let timeout = params["timeout"].flatMap(TimeInterval.init) else {
                return nil
            }
            self.timeout = timeout
            self.max = params["max"].flatMap(Int.init)
        }
        
        public init(timeout: TimeInterval, maxTries: Int? = nil) {
            self.timeout = timeout
            self.max = maxTries
        }
        
        public var rawValue: String {
            let maxStr = max.flatMap({ "; max=\($0)"}) ?? ""
            return "timeout=\(Int(timeout))\(maxStr)"
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
        /// :nodoc:
        public static func == (lhs: KeepAlive, rhs: KeepAlive) -> Bool {
            return lhs.timeout == rhs.timeout && lhs.max == rhs.max
        }
    }
    
    public struct Link: RawRepresentable, Hashable, Equatable {
        public let url: URL
        public var parameters: [String: String]
        
        public typealias RawValue = String
        
        public init?(rawValue: String) {
            let components = rawValue.components(separatedBy: ">")
            let urlLimiters = CharacterSet(charactersIn: "<> ")
            guard let urlStr = components.first?.trimmingCharacters(in: urlLimiters),
                let url = URL(string: urlStr) else {
                return nil
            }
            self.url = url
            self.parameters = HTTPHeaders.parseParams(components.dropFirst().joined(separator: ">"), removeQuotation: true)
        }
        
        public init(url: URL, relation: RelationType?, relationURL: URL? = nil, title: String? = nil, parameters: [String: String] = [:]) {
            self.url = url
            self.parameters = parameters
            self.parameters["rel"] = relation?.rawValue
            self.relationURL = relationURL
            self.parameters["title"] = title
        }
        
        public var rawValue: String {
            let paramStr = HTTPHeaders.createParam(parameters, quotationValue: true)
            return "<\(url.absoluteString)>; \(paramStr)"
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
        /// :nodoc:
        public static func == (lhs: Link, rhs: Link) -> Bool {
            return lhs.url == rhs.url && lhs.parameters == rhs.parameters
        }
        
        /// Link `rel` parameter's type
        public var relationType: RelationType? {
            get {
                return parameters["rel"].flatMap(RelationType.init(rawValue:))
            }
            set {
                let urlStr = parameters["rel"]?.components(separatedBy: " ")
                    .dropFirst().joined(separator: " ") ?? ""
                parameters["rel"] = (newValue?.rawValue).flatMap({ "\($0)\(urlStr)"})
            }
        }
        
        /// Link `rel` parameter's url
        public var relationURL: URL? {
            get {
                let urlStr = parameters["rel"]?.components(separatedBy: " ").dropFirst().joined(separator: " ")
                return urlStr.flatMap(URL.init(string:))
            }
            set {
                guard let type = parameters["rel"]?.prefix(until: " "), !type.isEmpty else {
                    return
                }
                let urlStr = newValue.flatMap({ " \($0.absoluteString)" }) ?? ""
                parameters["rel"] = "\(type)\(urlStr)"
            }
        }
        
        /// Link `anchor` parameter
        public var anchor: URL? {
            get {
                return parameters["anchor"].flatMap(URL.init(string:))
            }
            set {
                parameters["anchor"] = newValue?.absoluteString
            }
        }
        
        /// Link `hreflang` parameter
        public var language: Locale? {
            get {
                return parameters["hreflang"].flatMap(Locale.init(identifier:))
            }
            set {
                parameters["hreflang"] = newValue?.identifier
            }
        }
        
        /// Link `media` parameter
        public var media: MediaType? {
            get {
                return parameters["media"].flatMap(MediaType.init(rawValue:))
            }
            set {
                parameters["media"] = newValue?.rawValue
            }
        }
        
        /// Link `title` parameter
        public var title: String? {
            get {
                return parameters["title"]
            }
            set {
                parameters["title"] = newValue
            }
        }
        
        /// Link `type` parameter
        public var type: MediaType? {
            get {
                return parameters["type"].flatMap(MediaType.init(rawValue:))
            }
            set {
                parameters["type"] = newValue?.rawValue
            }
        }
        
        public struct RelationType: RawRepresentable, Equatable, Hashable {
            public var rawValue: String
            
            public init?(rawValue: String) {
                self.rawValue = rawValue.prefix(until: " ").lowercased()
            }
            
            public var hashValue: Int {
                return self.rawValue.hashValue
            }
            
            /// :nodoc:
            public static func == (lhs: RelationType, rhs: RelationType) -> Bool {
                return lhs.rawValue == rhs.rawValue
            }
            
            // List: https://tools.ietf.org/html/rfc5988#section-6.2.2
            
            /// Designates a substitute for the link's context.
            public static let alternate = RelationType(rawValue: "alternate")
            /// Refers to an appendix.
            public static let appendix = RelationType(rawValue: "appendix")
            /// Refers to a bookmark or entry point.
            public static let bookmark = RelationType(rawValue: "bookmark")
            /// Refers to a chapter in a collection of resources.
            public static let chapter = RelationType(rawValue: "chapter")
            /// Refers to a table of contents
            public static let contents = RelationType(rawValue: "contents")
            /// Refers to a copyright statement that applies to the link's context.
            public static let copyright = RelationType(rawValue: "copyright")
            /// Refers to a resource containing the most recent item(s) in a collection of resources.
            public static let current = RelationType(rawValue: "current")
            /// Refers to a resource providing information about the link's context.
            public static let describedby = RelationType(rawValue: "describedby")
            /// Refers to a resource that can be used to edit the link's context.
            public static let edit = RelationType(rawValue: "edit")
            /// Refers to a resource that can be used to edit media associated with the link's context.
            public static let editMedia = RelationType(rawValue: "edit-media")
            /// Identifies a related resource that is potentially large and might require special handling.
            public static let enclosure = RelationType(rawValue: "enclosure")
            /// An IRI that refers to the furthest preceding resource in a series of resources.
            public static let first = RelationType(rawValue: "first")
            /// Refers to a glossary of terms.
            public static let glossary = RelationType(rawValue: "glossary")
            /// Refers to a resource offering help (more information,
            /// links to other sources information, etc.)
            public static let help = RelationType(rawValue: "help")
            /// Refers to a hub that enables registration for notification of updates to the context.
            public static let hub = RelationType(rawValue: "hub")
            /// Refers to an index.
            public static let index = RelationType(rawValue: "index")
            /// An IRI that refers to the furthest following resource in a series of resources.
            public static let last = RelationType(rawValue: "last")
            /// Points to a resource containing the latest (e.g., current) version of the context.
            public static let latestVersion = RelationType(rawValue: "latest-version")
            /// Refers to a license associated with the link's context.
            public static let license = RelationType(rawValue: "license")
            /// Refers to the next resource in a ordered series of resources.
            public static let next = RelationType(rawValue: "next")
            /// Refers to the immediately following archive resource.
            public static let nextArchive = RelationType(rawValue: "next-archive")
            /// Indicates a resource where payment is accepted.
            public static let payment = RelationType(rawValue: "payment")
            /// Refers to the previous resource in an ordered series of resources.  Synonym for `previous`.
            public static let prev = RelationType(rawValue: "prev")
            /// Points to a resource containing the predecessor version in the version history.
            public static let predecessorVersion = RelationType(rawValue: "predecessor-version")
            /// Refers to the previous resource in an ordered series of resources.  Synonym for `prev`.
            public static let previous = RelationType(rawValue: "previous")
            /// Refers to the immediately preceding archive resource.
            public static let prevArchive = RelationType(rawValue: "prev-archive")
            /// Identifies a related resource.
            public static let related = RelationType(rawValue: "related")
            /// Identifies a resource that is a reply to the context of the link.
            public static let replies = RelationType(rawValue: "replies")
            /// Refers to a section in a collection of resources.
            public static let section = RelationType(rawValue: "section")
            /// Conveys an identifier for the link's context.
            public static let selfRelation = RelationType(rawValue: "self")
            /// Indicates a URI that can be used to retrieve a service document.
            public static let service = RelationType(rawValue: "service")
            /// Refers to the first resource in a collection of resources.
            public static let start = RelationType(rawValue: "start")
            /// Refers to an external style sheet.
            public static let stylesheet = RelationType(rawValue: "stylesheet")
            /// Refers to a resource serving as a subsection in a collection of resources.
            public static let subsection = RelationType(rawValue: "subsection")
            /// Points to a resource containing the successor version in the version history.
            public static let successorVersion = RelationType(rawValue: "successor-version")
            /// Refers to a parent document in a hierarchy of documents.
            public static let up = RelationType(rawValue: "up")
            /// points to a resource containing the version history for the context.
            public static let versionHistory = RelationType(rawValue: "version-history")
            /// Identifies a resource that is the source of the information in the link's context.
            public static let via = RelationType(rawValue: "via")
            /// Points to a working copy for this resource.
            public static let workingCopy = RelationType(rawValue: "working-copy")
            /// Points to the versioned resource from which this working copy was obtained.
            public static let workingCopyOf = RelationType(rawValue: "working-copy-of")
        }
    }
    
    /// `Pragma` header values
    public enum Pragma: String {
        // no-cache for Pragma
        case noCache = "no-cache"
    }
    
    /// Determines server accepts `Range` header or not
    public struct RangeType: RawRepresentable, Hashable, Equatable {
        public var rawValue: String
        
        public typealias RawValue = String
        
        public init(rawValue: String) {
            let linted = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.rawValue = linted
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
        public static func == (lhs: RangeType, rhs: RangeType) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        /// Can't accept Range.
        public static let none = RangeType(rawValue: "none")
        /// Accept range in bytes(octets).
        public static let bytes = RangeType(rawValue: "bytes")
        /// Accept range in item numbers (non-standard).
        public static let items = RangeType(rawValue: "items")
    }
}

internal extension HTTPHeaders {
    /// Parses lists that have `q` paramter and sorts the result based on that.
    /// - Note: This method will remove items with `q=0.0` as they should not be used.
    internal static func parseQuilified<T>(_ value: [String], _ initializer: (String) -> T) -> [T] {
        return value.flatMap({ (value) -> [String] in
            return value.components(separatedBy: ",")
        }).flatMap({ (value) -> (typed: T, q: Double)? in
            let (typedStr, params) = parseParamsWithToken(value, removeQuotation: false)
            guard let typed = typedStr.flatMap(initializer) else {
                return nil
            }
            let q = params["q"].flatMap(Double.init) ?? 1
            // Removing values with q=0 according to [RFC7231](https://tools.ietf.org/html/rfc7231)
            if q == 0 {
                return nil
            }
            return (typed, q)
        }).sorted(by: {
            $0.q > $1.q
        }).map({ $0.typed })
    }
    
    /// Parses `key=value` pairs into dictionary. RFC5987 encoded params will be reverted to utf8 string.
    private static func parseParams(rawParams: [String], removeQuotation: Bool) -> [String: String] {
        var params: [String: String] = [:]
        for rawParam in rawParams {
            let arg = rawParam.components(separatedBy: "=")
            if let key = arg.first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                /* Keys ended with * are preferred re RFC5987. If a key has * version,
                 it will be iterated and replaces Ascii-encoded version.
                 `else if` section neglects normal version if * version is already iterated.
                 This check guarantees paramters' order won't cause a bug.
                 */
                if key.hasSuffix("*") {
                    let decodedKey = key.replacingOccurrences(of: "*", with: "", options: [.backwards, .anchored])
                    let value = arg.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                    /* Here we use `decodingRFC5987enforced`. We can change this behavior to use
                     `decodingRFC5987` and fallback to non-asterisk version if available
                     and use `decodingRFC5987`.
                     I didn't implemented the latter for the sake of better performance.
                     Both behaviors are ok re section-3.2.1 in RFC 8187.
                     */
                    let decodedValue = value.decodingRFC5987enforced
                    params[decodedKey] = decodedValue
                } else if params.index(forKey: key) == nil {
                    let trimCharset = removeQuotation ? CharacterSet(charactersIn: " ;\r\n\"") : .whitespacesAndNewlines
                    let value = arg.dropFirst().joined(separator: "=").trimmingCharacters(in: trimCharset)
                    params[key] = value
                }
            }
        }
        return params
    }
    
    /// Converts `name=value` pairs into a dictionary
    internal static func parseParams(_ value: String, separator: String = ";", removeQuotation: Bool = false) -> [String: String] {
        let rawParams: [String] = value.components(separatedBy: separator).flatMap { param in
            let result = param.trimmingCharacters(in: .whitespacesAndNewlines)
            return !result.isEmpty ? result : nil
        }
        return parseParams(rawParams: rawParams, removeQuotation: removeQuotation)
    }
    
    /// Converts `name=value` pairs into a dictionary
    fileprivate static func parseParamsWithToken(_ value: String, separator: String = ";", removeQuotation: Bool = false) -> (token: String?, params: [String: String]) {
        var rawParams: [String] = value.components(separatedBy: separator).flatMap { param in
            let result = param.trimmingCharacters(in: .whitespacesAndNewlines)
            return !result.isEmpty ? result : nil
        }
        var token: String?
        if rawParams.first?.index(of: "=") == nil {
            token = rawParams.removeFirst()
        }
        return (token, parseParams(rawParams: rawParams, removeQuotation: removeQuotation))
    }
    
    fileprivate static func createParam(_ params: [String: String], quotationValue: Bool = true, quotedKeys: [String] = [], nonquotatedKeys: [String] = [], separator: String = "; ") -> String {
        
        var result: [String] = []
        
        func appendParam(key: String, value: String) {
            if (quotedKeys.contains(key) || (quotationValue && !nonquotatedKeys.contains(key))) {
                // Removes quotation enclose if already exists and encloses string again.
                result.append("\(key)=\"\(value.trimmingCharacters(in: .quoted))\"")
            } else if nonquotatedKeys.contains(key) {
                // Remove quotations if key must not have enclosed value
                result.append("\(key)=\(value.trimmingCharacters(in: .quoted))")
            } else {
                // Use value as is.
                result.append("\(key)=\(value)")
            }
        }
        
        for param in params {
            if param.value.isEmpty {
                // Indeed the parameter is a token!
                result.append(param.key)
            } else if param.value.isAscii {
                /* Historically, HTTP has allowed field content with text in the ISO-8859-1 charset.
                 In practice, most HTTP header field values use only a subset of the US-ASCII charset.
                 Newly defined header fields SHOULD limit their field values to US-ASCII octets.
                 */
                appendParam(key: param.key, value: param.value)
            } else { // Value is utf8 rich string!
                /* Check if value is encodable to utf8 string re RFC 5987.
                 ISO-8859-1 version is not required re RFC 8187 section-3.2.2 (Sep 2017).
                 But to support legacy browsers, we still provide ascii-encoded version if possible.
                 */
                if let encodedValue = param.value.rfc5987encoded {
                    let keyval = "\(param.key)*=\(encodedValue)"
                    result.append(keyval)
                }
                let value = param.value.ascii.trimmingCharacters(in: .quoted)
                // If striped string is empty, we neglect this value entirely.
                if value.isEmpty {
                    continue
                }
                // Adding ASCII version.
                appendParam(key: param.key, value: value)
            }
        }
        return result.joined(separator: separator)
    }
}

internal extension Date {
    /// Date formats used commonly in internet messaging defined by various RFCs.
    enum RFCStandards: String {
        /// Date format defined by usenet, commonly used in old implementations.
        case rfc850 = "EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z"
        /// Date format defined by RFC 1123 for http.
        case rfc1123 = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss z"
        /// Date format defined by ISO 8601, also defined in RFC 3339. Used by Dropbox.
        case iso8601 = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
        /// Date string returned by asctime() function.
        case asctime = "EEE MMM d HH':'mm':'ss yyyy"
        
        /// Equivalent to and defined by RFC 1123.
        public static let http = RFCStandards.rfc1123
        /// Equivalent to and defined by ISO 8610.
        public static let rfc3339 = RFCStandards.iso8601
        /// Equivalent to and defined by RFC 850.
        public static let usenet = RFCStandards.rfc850
        
        // Sorted by commonness
        fileprivate static let allValues: [RFCStandards] = [.rfc1123, .rfc850, .iso8601, .asctime]
    }
    
    private static let posixLocale = Locale(identifier: "en_US_POSIX")
    private static let utcTimezone = TimeZone(identifier: "UTC")
    
    /// Checks date string against various RFC standards and returns `Date`.
    init?(rfcString: String) {
        let dateFor: DateFormatter = DateFormatter()
        dateFor.locale = Date.posixLocale
        
        for standard in RFCStandards.allValues {
            dateFor.dateFormat = standard.rawValue
            if let date = dateFor.date(from: rfcString) {
                self = date
                return
            }
        }
        
        return nil
    }
    
    /// Formats date according to RFCs standard.
    /// - Note: local and timezone paramters should be nil for `.http` standard
    func format(with standard: RFCStandards, locale: Locale? = nil, timeZone: TimeZone? = nil) -> String {
        let fm = DateFormatter()
        fm.dateFormat = standard.rawValue
        fm.timeZone = timeZone ?? Date.utcTimezone
        fm.locale = locale ?? Date.posixLocale
        return fm.string(from: self)
    }
}

fileprivate extension CharacterSet {
    static let quoted = CharacterSet(charactersIn: "\"")
    static let quotedWhitespace = CharacterSet(charactersIn: "\" ")
    // Alphanumeric + "!#$&+-.^_`|~"
    static let urlRFC5987Allowed = CharacterSet(charactersIn: "!#$&+-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz|~")
}

fileprivate extension String {
    var isAscii: Bool {
        for scalar in self.unicodeScalars {
            if !scalar.isASCII {
                return false
            }
        }
        return true
    }
    
    var ascii: String {
        return self.filter({ $0.unicodeScalars.count == 1 ? $0.unicodeScalars.first!.isASCII : false })
    }
    
    /// Returns utf-8 percent encoded string according to [RFC 8187](https://tools.ietf.org/html/rfc8187)
    var rfc5987encoded: String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlRFC5987Allowed).flatMap({
            "UTF-8''\($0)"
        })
    }
    
    @inline(__always)
    private func rfc5987decoded(forced: Bool) -> String? {
        // Encoded string is not enclosed by quotation marks
        guard !self.hasPrefix("\"") && !self.hasSuffix("\"") else {
            return nil
        }
        /// First component is encoding. Second is language which we ignore. Third is data
        let components = self.components(separatedBy: "'")
        guard components.count >= 3 else {
            return self
        }
        let encoding = String.Encoding(ianaCharset: components.first!) ?? .isoLatin1
        let string = components.dropFirst(2).joined(separator: "'")
        return string.removingPercentEscapes(encoding: encoding, forced: forced)
    }
    
    /// Converts percent encoded to normal string according to [RFC 8187](https://tools.ietf.org/html/rfc8187)
    var decodingRFC5987: String? {
        return rfc5987decoded(forced: false)
    }
    
    /// Converts percent encoded to normal string according to [RFC 8187](https://tools.ietf.org/html/rfc8187)
    /// Substitutes undecodable percent encoded characters to a `U+FFFD` (Replacement) character.
    var decodingRFC5987enforced: String {
        return rfc5987decoded(forced: true) ?? self
    }
    
    // Similiar method is deprecated in Foundation, we implemented ours!
    /// - Parameter forced: Forces routine to return non-nil string by substituting
    ///     a non-decodable octet sequence by a replacement.
    func removingPercentEscapes(encoding: String.Encoding, forced: Bool = false) -> String? {
        if encoding == .utf8 && !forced {
            return self.removingPercentEncoding
        }
        
        var str = self
        var lastcheckedIndex = str.startIndex
        while true {
            guard let index = str[lastcheckedIndex...].index(of: "%") else {
                break
            }
            lastcheckedIndex = index
            var range = index..<(str.index(index, offsetBy: 3))
            while str[range.upperBound] == "%" {
                range = range.lowerBound..<str.index(range.upperBound, offsetBy: 3)
            }
            let percentEncoded = str[range]
            let bytes: [UInt8] = percentEncoded.split(separator: "%").flatMap({ UInt8($0, radix: 16) })
            
            let charData = Data(bytes: bytes)
            if let converted = String(data: charData, encoding: encoding) {
                str.replaceSubrange(range, with: converted)
            } else {
                if forced {
                    // Another option, though non-standard in RFC, is to use ISO-8859-1 to interpret encoded sequence.
                    str.replaceSubrange(range, with: "\u{fffd}")
                } else {
                    return nil
                }
            }
            
        }
        return str
    }
}

internal extension String {
    @inline(__always)
    internal func prefix(until: Character) -> String {
        // TOOTIMIZE: Return Substring, when Substring.trim() implemented in linux.
        return String(self.prefix(while: { $0 != until }))
    }
}

internal extension String.Encoding {
    #if os(macOS) || os(iOS) || os(tvOS)
    #else
    static private let ianatable: [String.Encoding: String] = [
    .ascii: "us-ascii", .isoLatin1: "iso-8859-1", .isoLatin2: "iso-8859-2", .utf8: "utf-8",
    .utf16: "utf-16", .utf16BigEndian: "utf-16be", .utf16LittleEndian: "utf-16le",
    .utf32: "utf-32", .utf32BigEndian: "utf-32be", .utf32LittleEndian: "utf-32le",
    .japaneseEUC: "euc-jp",.shiftJIS: "cp932", .iso2022JP: "iso-2022-jp",
    .windowsCP1251: "windows-1251", .windowsCP1252: "windows-1252", .windowsCP1253: "windows-1253",
    .windowsCP1254: "windows-1254", .windowsCP1250: "windows-1250",
    .nextstep: "x-nextstep", .macOSRoman: "macintosh", .symbol: "x-mac-symbol"]
    #endif
    
    init?(ianaCharset charset: String) {
        #if os(macOS) || os(iOS) || os(tvOS)
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
        if cfEncoding != kCFStringEncodingInvalidId {
            self = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
        } else {
            return nil
        }
        #else
        // CFStringConvertIANACharSetNameToEncoding is not exported in SwiftFoundation!
        // We use this as workaround until SwiftFoundation got fixed.
        let charset = charset.lowercased()
        if let encoding = String.Encoding.ianatable.first(where: { return $0.value == charset })?.key {
            self = encoding
        } else {
            return nil
        }
        #endif
    }
    
    internal var ianaCharset: String? {
        #if os(macOS) || os(iOS) || os(tvOS)
        return (CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.rawValue)) as String?)
        #else
        // CFStringConvertEncodingToIANACharSetName is not exported in SwiftFoundation!
        // We use this as workaround until SwiftFoundation got fixed.
        return String.Encoding.ianatable[self]
        #endif
    }
}
