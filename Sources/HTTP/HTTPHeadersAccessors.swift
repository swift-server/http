// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation

extension HTTPHeaders {
    
    /// MIME type directive for `Accept` and `Content-Type` headers.
    public struct MediaType: RawRepresentable, Hashable, Equatable, ExpressibleByStringLiteral {
        private let generalType: String
        private let type: String
        public typealias RawValue = String
        public typealias StringLiteralType = String
        
        public init(rawValue: String) {
            let linted = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let slashIndex = linted.index(of: "/") else {
                self.generalType = linted
                self.type = ""
                return
            }
            self.generalType = String(linted[linted.startIndex..<slashIndex])
            self.type = String(linted[linted.index(after: slashIndex)...])
        }
        
        public init(stringLiteral: String) {
            self.init(rawValue: stringLiteral)
        }
        
        private init(generalType: String, type: String) {
            self.generalType = generalType
            self.type = type
        }
        
        public var rawValue: String {
            return "\(generalType)/\(type)"
        }
        
        public var hashValue: Int {
            return rawValue.hashValue
        }
        
        public static func == (lhs: MediaType, rhs: MediaType) -> Bool {
            return lhs.generalType == rhs.generalType &&  lhs.type.replacingOccurrences(of: "x-", with: "", options: .anchored) == rhs.type.replacingOccurrences(of: "x-", with: "", options: .anchored)
        }
        
        /// Returns true if media type provided in argument can be returned as `Content-Type`
        /// when this media type is provided by `Accept` header.
        public func canAccept(_ value: MediaType) -> Bool {
            // if self is */* it can accept any type
            if self == .all || (self.type == "*" && self.generalType == value.generalType) {
                return true
            }
            
            // Removing nonstandard `x-` prefix
            // see [RFC 6838](https://tools.ietf.org/html/rfc6838)
            let selfType = self.type.replacingOccurrences(of: "x-", with: "", options: .anchored)
            let valType = value.type.replacingOccurrences(of: "x-", with: "", options: .anchored)
            
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
    
    /// Values available for `Conten-Disposition` header.
    public enum ContentDisposition: CustomStringConvertible, Equatable {
        /// Default value, which indicates file must be shown in browser.
        case inline
        /// Downloadable content, with specifed filename if available.
        case attachment(filename: String?)
        /// Form-Data deposition type.
        case formData(name: String?, filename: String?)
        
        public init?( _ rawValue: String) {
            guard let type = rawValue.components(separatedBy: ";").first?.lowercased() else {
                return nil
            }
            
            let params = HTTPHeaders.parseParams(rawValue, removeQuotation: true)
            switch type {
            case "inline", "":
                self = .inline
            case "attachment":
                self = .attachment(filename: params["filename"])
            case "form-data":
                self = .formData(name: params["name"], filename: params["filename"])
            default:
                return nil
            }
        }
        
        public var description: String {
            switch self {
            case .inline:
                return "inline"
            case .attachment(filename: let filename):
                // We add both IsoLatin and UTF-8 encoded file names for compatibility
                let isoFileName = filename?.isoLatinStripped
                let filenameParam = isoFileName.flatMap({ "; filename=\"\($0)\"" }) ?? ""
                let filenameAstrisk = filename.flatMap({ "; filename*=\($0.rfc5987encoded)" }) ?? ""
                return "attachment\(filenameParam)\(filenameAstrisk)"
            case .formData(name: let name, filename: let filename):
                let nameParam = name.flatMap({ "; name=\"\($0)\"" }) ?? ""
                let isoFileName = filename?.isoLatinStripped
                let filenameParam = isoFileName.flatMap({ "; filename=\"\($0)\"" }) ?? ""
                let filenameAstrisk = filename.flatMap({ "; filename*=\($0.rfc5987encoded)" }) ?? ""
                return "form-data\(nameParam)\(filenameParam)\(filenameAstrisk)"
            }
        }
        
        public static func ==(lhs: HTTPHeaders.ContentDisposition, rhs: HTTPHeaders.ContentDisposition) -> Bool {
            switch (lhs, rhs) {
            case (.inline, .inline):
                return true
            case let (.attachment(l), .attachment(r)):
                return l == r
            case let (.formData(nl, fnl), .formData(nr, fnr)):
                return nl == nr && fnl == fnr
            default:
                return false
            }
        }
    }
    
    ///
    public enum CacheControl: CustomStringConvertible, Equatable {
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
        
        public var description: String {
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
        
        public init?(_ rawValue: String) {
            let keyVal = rawValue.components(separatedBy: "=").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard let key = keyVal.first?.lowercased() else { return nil }
            let val = keyVal.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .quoted)
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
        
        public static func ==(lhs: HTTPHeaders.CacheControl, rhs: HTTPHeaders.CacheControl) -> Bool {
            switch (lhs, rhs) {
            case (.noCache, .noCache), (.noStore, .noStore), (.noTransform, .noTransform),
                 (.onlyIfCached, .onlyIfCached), (.`public`, .`public`), (.`private`, .`private`),
                 (.mustRevalidate, .mustRevalidate), (.proxyRevalidate, .proxyRevalidate):
                return true
            case let (.maxAge(l), .maxAge(r)), let (.maxStale(l), .maxStale(r)),
                 let (.minFresh(l), .minFresh(r)), let (.sMaxAge(l), .sMaxAge(r)):
                return Int(l) == Int(r)
            default:
                return lhs.description == rhs.description
            }
        }
    }
    
    /// Defines HTTP Authorization request.
    /// - Note: Paramters may be quoted or not according to RFCs.
    /// - Note: Quotation in parameters' values are preserved as is.
    public enum Authorization: CustomStringConvertible {
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
        
        public init?(_ rawValue: String) {
            let sep = rawValue.components(separatedBy: " ")
            guard let type = sep.first?.trimmingCharacters(in: .whitespaces), !type.isEmpty else {
                return nil
            }
            let q = sep.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)
            switch type.lowercased() {
            case "basic":
                guard let data = Data(base64Encoded: q) else { return nil }
                guard let paramStr = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8) else { return nil }
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
        
        public var description: String {
            switch self {
            case .basic(let user, let password):
                let text = "\(user):\(password)"
                let b64 = (text.data(using: .ascii) ?? text.data(using: .utf8))?.base64EncodedString() ?? ""
                return "Basic \(b64)"
            case .digest(let params):
                let nonquotedKeys: [String] = ["stale", "algorithm", "nc", "charset", "userhash", "qop"]
                let paramsString = HTTPHeaders.createParam(params, quotationValue: true, quotedKeys: [], nonquotatedKeys: nonquotedKeys, separator: ", ")
                return "Digest \(paramsString)"
            case .oAuth1(let token):
                return "OAuth \(token)"
            case .oAuth2(let token):
                return "Bearer \(token)"
            case .mutual(let params):
                let nonquotedKeys: [String] = ["sid", "nc"]
                let paramsString = HTTPHeaders.createParam(params, quotationValue: true, quotedKeys: [], nonquotatedKeys: nonquotedKeys, separator: ", ")
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
    
    /// Defines HTTP Authentication challenge method required to access.
    public enum ChallengeType: CustomStringConvertible, Hashable, Equatable {
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
        
        public init(_ rawValue: String) {
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
                self = .custom(rawValue.components(separatedBy: " ").first?.trimmingCharacters(in: .whitespaces) ?? "")
            }
        }
        
        public var hashValue: Int {
            return description.hashValue
        }
        
        public var description: String {
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
    public struct Challenge: CustomStringConvertible {
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
            return parameters["charset"].flatMap(HTTPHeaders.charsetIANAToStringEncoding)
        }
        
        /// Inits a noew
        public init(type: ChallengeType, token: String? = nil, realm: String? = nil, charset: String.Encoding? = nil, parameters: [String: String] = [:]) {
            self.type = type
            var parameters = parameters
            parameters["realm"] = (realm?.trimmingCharacters(in: .quoted)).flatMap({ "\"\($0)\""})
            parameters["charset"] = charset.flatMap(HTTPHeaders.StringEncodingToIANA)
            if let token = token {
                parameters[token] = ""
            }
            self.parameters = parameters
        }
        
        public init?(_ rawValue: String) {
            let typeSegment = rawValue.components(separatedBy: " ")
            guard let type = typeSegment.first.flatMap(ChallengeType.init) else { return nil }
            self.type = type
            let allparams = typeSegment.dropFirst().joined(separator: " ")
            let removeQ = type == .digest || type == .mutual
            let parsedParams = HTTPHeaders.parseParams(allparams, separator: ",", removeQuotation: removeQ)
            self.parameters = parsedParams
        }
        
        public var description: String {
            switch type {
            case .digest:
                let nonquotedKeys: [String] = ["stale", "algorithm", "nc", "charset", "userhash"]
                let params = HTTPHeaders.createParam(parameters, quotationValue: true, quotedKeys: [], nonquotatedKeys: nonquotedKeys, separator: ", ")
                return "\(type.description) \(params)"
            case .mutual:
                let nonquotedKeys: [String] = ["sid", "nc"]
                let params = HTTPHeaders.createParam(parameters, quotationValue: true, quotedKeys: [], nonquotatedKeys: nonquotedKeys, separator: ", ")
                return "\(type.description) \(params)"
            default:
                let token = self.token.flatMap({ "\($0) "}) ?? ""
                let params = HTTPHeaders.createParam(parameters, quotationValue: false, quotedKeys: [], nonquotatedKeys: [], separator: ", ")
                return "\(type.description) \(token)\(params)"
            }
        }
    }
    
    /// Media type and related parameters in Content-Type.
    public struct ContentType: CustomStringConvertible {
        /// Media type (MIME) of content
        let mediaType: HTTPHeaders.MediaType
        /// All parameter provided with content type
        let parameters: [String: String]
        /// charset parameter of content type
        var charset: String.Encoding? {
            return parameters["charset"].flatMap(HTTPHeaders.charsetIANAToStringEncoding)
        }
        
        public init(type: HTTPHeaders.MediaType, charset: String.Encoding? = nil, parameters: [String: String] = [:]) {
            self.mediaType = type
            var parameters = parameters
            parameters["charset"] = charset.flatMap(HTTPHeaders.StringEncodingToIANA)
            self.parameters = parameters
        }
        
        public init?(_ rawValue: String) {
            let typeSegment = rawValue.components(separatedBy: ";")
            guard let type = (typeSegment.first?.trimmingCharacters(in: .whitespaces)).flatMap(MediaType.init(rawValue:)) else { return nil }
            self.mediaType = type
            let allparams = typeSegment.dropFirst().joined(separator: ";")
            self.parameters = HTTPHeaders.parseParams(allparams)
        }
        
        public var description: String {
            let params = parameters.map({ " \($0.key)=\($0.value)" }).joined(separator: ",")
            return "\(mediaType.rawValue)\(params)"
        }
    }
    
    /// EntryTag used in `ETag`, `If-Modified`, etc.
    public enum EntryTag: CustomStringConvertible, Equatable, Hashable {
        /// Regular entry tag
        case strong(String)
        /// Weak entry tag prefixed with `"W/"`
        case weak(String)
        /// Equals to `"*"`
        case wildcard
        
        public init(_ rawValue: String) {
            // Check begins with W/" in case-insensitive manner to indicate is weak or not
            if rawValue.range(of: "W/\"", options: [.anchored, .caseInsensitive]) != nil {
                let linted = rawValue.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "W/\"", with: "", options: [.anchored, .caseInsensitive]).trimmingCharacters(in: .quotedWhitespace)
                self = .weak(linted)
            }
            // Check value is wildcard
            if rawValue == "*" {
                self = .wildcard
            }
            // Value is strong
            let linted = rawValue.trimmingCharacters(in: .quotedWhitespace)
            self = .strong(linted)
        }
        
        public var description: String {
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
            return self.description.hashValue
        }
        
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
    
    // Should we use enum? It's faster to compare.
    /// Encoding of body
    public struct Encoding: RawRepresentable, Hashable, Equatable {
        public var rawValue: String
        public var hashValue: Int
        public typealias RawValue = String
        
        public init(rawValue: String) {
            let linted = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                .replacingOccurrences(of: "x-", with: "", options: .anchored)
            self.rawValue = linted
            self.hashValue = linted.hashValue
        }
        
        private init(linted: String) {
            self.rawValue = linted
            self.hashValue = linted.hashValue
        }
        
        public static func == (lhs: Encoding, rhs: Encoding) -> Bool {
            return  lhs.hashValue == rhs.hashValue && lhs.rawValue == rhs.rawValue
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
    
    /// Values for `If-Range` header.
    public enum IfRange: CustomStringConvertible, Equatable, Hashable {
        /// An entry tag for `If-Range` to be checked againt `ETag`
        case tag(EntryTag)
        /// an entry tag for `If-Range` to be checked againt `Last-Modified`
        case date(Date)
        
        public init( _ rawValue: String) {
            if let parsedDate = Date(rfcString: rawValue) {
                self = .date(parsedDate)
            } else {
                self = .tag(EntryTag(rawValue))
            }
        }
        
        public var description: String {
            switch self {
            case .date(let date):
                return date.format(with: .http)
            case .tag(let tag):
                return tag.description
            }
        }
        
        public var hashValue: Int {
            return self.description.hashValue
        }
        
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
    
    /// Determines server accepts `Range` header or not
    public struct RangeType: RawRepresentable, Hashable, Equatable {
        public var rawValue: String
        public var hashValue: Int
        
        public typealias RawValue = String
        
        public init(rawValue: String) {
            let linted = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.rawValue = linted
            self.hashValue = linted.hashValue
        }
        
        public static func == (lhs: RangeType, rhs: RangeType) -> Bool {
            return lhs.hashValue == rhs.hashValue && lhs.rawValue == rhs.rawValue
        }
        
        /// Can't accept Range.
        public static let none = RangeType(rawValue: "none")
        /// Accept range in bytes(octets).
        public static let bytes = RangeType(rawValue: "bytes")
        /// Accept range in item numbers (non-standard).
        public static let items = RangeType(rawValue: "items")
    }
    
    /// `Pragma` header values
    public enum Pragma: String {
        // no-cache for Pragma
        case noCache = "no-cache"
    }
    
    // MARK: Request Headers
    
    /// Fetch `Accept` header values, sorted by `q` parameter. An empty array means no value is set in header.
    public var accept: [MediaType] {
        get {
            return self.storage[.accept].flatMap({
                HTTPHeaders.parseQuilified($0, MediaType.init(rawValue:))
            }) ?? []
        }
    }
    
    /// Fetch `Accept-Charset` header values, sorted by `q` parameter. An empty array means no value is set in header.
    public var acceptCharset: [String.Encoding] {
        get {
            return self.storage[.acceptCharset].flatMap({
                HTTPHeaders.parseQuilified($0, HTTPHeaders.charsetIANAToStringEncoding)
            }) ?? []
        }
    }
    
    /// `Accept-Datetime` header.
    public var acceptDatetime: Date? {
        get {
            return self.storage[.acceptDatetime]?.first.flatMap(Date.init(rfcString:))
        }
    }
    
    /// Fetch `Accept-Encoding` header values, sorted by `q` parameter. An empty array means no value is set in header.
    public var acceptEncoding: [Encoding] {
        get {
            return self.storage[.acceptEncoding].flatMap({
                HTTPHeaders.parseQuilified($0, Encoding.init(rawValue:))
            }) ?? []
        }
    }
    
    /// Fetch `Accept-Language` header values, sorted by `q` parameter. An empty array means no value is set in header.
    public var acceptLanguage: [Locale] {
        get {
            return self.storage[.acceptLanguage].flatMap({
                HTTPHeaders.parseQuilified($0, Locale.init(identifier:))
            }) ?? []
        }
    }
    
    /// `Authorization` header value.
    public var authorization: HTTPHeaders.Authorization? {
        get {
            return self.storage[.authorization]?.first.flatMap(Authorization.init)
        }
        set {
            self.storage[.authorization] = newValue.flatMap { [$0.description] }
        }
    }
    
    // `Cookie` header value. An empty array means no value is set in header.
    public var cookie: [HTTPCookie] {
        // Regarding `Cookie2` is obsolete, should we have to integrate it into values?
        let pairs = self.storage[.cookie]?.first.flatMap({ HTTPHeaders.parseParams($0, separator: ";", removeQuotation: true) }) ?? [:]
        return pairs.flatMap {
            // path should be set otherwise it will fail!
            return HTTPCookie(properties: [.name : $0.key, .value: $0.value, .path: "/"])
        }
    }
    
    /// `Origin` header value.
    public var host: URL? {
        get {
            return self.storage[.host]?.first.flatMap {
                if $0.contains("://") {
                    return URL(string: $0)
                } else {
                    return URL(string: "://\($0)")
                }
            }
        }
        set {
            self.storage[.host] = newValue.flatMap {
                guard let host = $0.host else { return nil }
                let port = $0.port.flatMap({ ":\($0)" }) ?? ""
                return ["\(host)\(port)"]
            }
        }
    }
    
    /// `If-Match` header etag value. An empty array means no value is set in header.
    public var ifMatch: [EntryTag] {
        get {
            return (self.storage[.ifMatch] ?? []).flatMap({ (value) -> [String] in
                return value.components(separatedBy: ",")
            }).map(EntryTag.init)
        }
    }
    
    /// `If-None-Match` header etag value. An empty array means no value is set in header.
    public var ifNoneMatch: [EntryTag] {
        get {
            return (self.storage[.ifNoneMatch] ?? []).flatMap({ (value) -> [String] in
                return value.components(separatedBy: ",")
            }).map(EntryTag.init)
        }
    }
    
    /// `If-Range` header etag value.
    public var ifRange: HTTPHeaders.IfRange? {
        get {
            return self.storage[.ifRange]?.first.flatMap(IfRange.init)
        }
    }
    
    /// `If-Modified-Since` header value.
    public var ifModifiedSince: Date? {
        get {
            return self.storage[.ifModifiedSince]?.first.flatMap(Date.init(rfcString:))
        }
    }
    
    /// `If-Unmodified-Since` header value.
    public var ifUnmodifiedSince: Date? {
        get {
            return self.storage[.ifUnmodifiedSince]?.first.flatMap(Date.init(rfcString:))
        }
    }
    
    /// `Origin` header value.
    public var origin: URL? {
        get {
            return self.storage[.origin]?.first.flatMap(URL.init(string:))
        }
        set {
            self.storage[.origin] = newValue.flatMap { [$0.absoluteString] }
        }
    }
    
    fileprivate func dissectRanges(_ value: String?) -> [(from: Int64, to: Int64?)] {
        // Converting real negatives to _ to avoid conflict with - as separator
        let value = value?.replacingOccurrences(of: "=-", with: "=_").replacingOccurrences(of: "--", with: "-_").replacingOccurrences(of: ",-", with: ",_")
        guard let bytes = value?.components(separatedBy: "=").dropFirst().first?.trimmingCharacters(in: .whitespaces) else {
            return []
        }
        
        var ranges = [(from: Int64, to: Int64?)]()
        for range in bytes.components(separatedBy: ",") {
            let elements = range.components(separatedBy: "-").map({ $0.trimmingCharacters(in: .whitespaces) })
            
            guard let lower = elements.first.flatMap({ Int64($0.replacingOccurrences(of: "_", with: "-")) }) else {
                continue
            }
            let upper = elements.dropFirst().first.flatMap { Int64($0.replacingOccurrences(of: "_", with: "-")) }
            ranges.append((lower, upper))
        }
        return ranges
    }
    
    /// Returns `Range` header values. An empty array means no value is set in header.
    /// - Note: upperbound will be Int64.max for positive ranges and 0 for negative
    ///   ranges in case of open ended Range.
    /// - Note: Server response should be `multipart/byteranges` in case of more than one range is returned.
    ///    See [MDN's HTTP range requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests) for more info.
    /// - Important: A negative range means server must return last bytes/items of file.
    public var range: [Range<Int64>] {
        // TODO: return PartialRangeFrom when possible
        get {
            guard let ranges = (self.storage[.range]?.joined(separator: ",")).flatMap({ self.dissectRanges($0) }) else {
                return []
            }
            
            return ranges.flatMap({ elements in
                // Determining upper bound. Negative ranges are meaningful up to 0 or eof.
                let to = elements.to.flatMap({ $0 + 1 }) ?? (elements.from >= 0 ? Int64.max : 0)
                // Avoiding server crash if upper bound is less than lower bound!
                guard to >= elements.from else {
                    return nil
                }
                return elements.from..<to
            })
        }
    }
    
    /// Returns `Range` type, usually `.bytes`
    public var rangeType: RangeType? {
        get {
            return self.storage[.range]?.first?.components(separatedBy: "=").first.flatMap(HTTPHeaders.RangeType.init(rawValue:))
        }
    }
    
    /// `Referer` header value.
    public var referer: URL? {
        get {
            return self.storage[.referer]?.first.flatMap(URL.init(string:))
        }
        set {
            self.storage[.referer] = newValue.flatMap { [$0.absoluteString] }
        }
    }
    
    /// Fetch `TE` header values, sorted by `q` parameter. An empty array means no value is set in header.
    public var te: [Encoding] {
        get {
            return self.storage[.te].flatMap({
                HTTPHeaders.parseQuilified($0, Encoding.init(rawValue:))
            }) ?? []
        }
    }
    
    /// Returns client's browser name and version using `User-Agent`.
    public var clientBrowser: (name: String, version: Float?)? {
        
        func getVersion(_ value: String) -> (name: String, version: Float?) {
            let browser = value.components(separatedBy: "/")
            let name = browser.first ?? "unknown"
            let version = (browser.dropFirst().first?.trimmingCharacters(in: CharacterSet(charactersIn: " ;()")).components(separatedBy: ".").prefix(2).joined(separator: ".")).flatMap(Float.init)
            return (name, version)
        }
        
        guard let agent = self.storage[.userAgent]?.first, !agent.isEmpty else {
            return nil
        }
        
        let dissect = agent.components(separatedBy: " ")
        
        // Many common browsers begins with `"Mozila/5.0"`
        guard agent.hasPrefix("Mozilla/") else {
            // Presto-based Opera, Crawlers, Custom apps
            return dissect.first.flatMap(getVersion)
        }
        
        // Checking for browsers, Ordered by commonness and exclusivity of browser name in user-agent string
        
        // For performance, checking user-agent are reversed order for some
        let rdissect = dissect.reversed()
        if let firefox = rdissect.first(where: { $0.hasPrefix("Firefox") }) {
            return getVersion(firefox)
        }
        // Opera (webkit-based)
        if let opera = rdissect.first(where: { $0.hasPrefix("OPR") }) {
            return getVersion(opera)
        }
        // Microsoft Edge
        if let edge = rdissect.first(where: { $0.hasPrefix("Edge") }) {
            return getVersion(edge)
        }
        // Chrome and Chromium
        if let chrome = dissect.first(where: { $0.hasPrefix("Chrome") }) {
            return getVersion(chrome)
        }
        // Safari browser
        if rdissect.first(where: { $0.hasPrefix("Safari") }) != nil {
            let version = dissect.first(where: { $0.hasPrefix("Version") }).flatMap(getVersion)
            // Sould we distinguish Mobile Safari & Desktop Safari?
            let isMobile = rdissect.index(of: "Mobile") != nil
            return (isMobile ? "Mobile Safari" : "Safari", version?.version)
        }
        // Internet Explorer
        if dissect.first(where: { $0.hasPrefix("MSIE") }) != nil {
            let version = (dissect.drop(while: { $0 != "MSIE" }).dropFirst().first?.trimmingCharacters(in: CharacterSet(charactersIn: "; )")).components(separatedBy: ".").prefix(2).joined(separator: ".")).flatMap(Float.init)
            return ("Internet Explorer", version)
        }
        
        // Google bot
        if let googlebot = dissect.first(where: { $0.hasPrefix("Googlebot") }) {
            return getVersion(googlebot)
        }
        
        // Now try to return engine
        
        // UIWebView, Game Consoles
        if let webkit = dissect.first(where: { $0.hasPrefix("AppleWebKit") || $0.hasPrefix("WebKit") }) {
            return getVersion(webkit)
        }
        // Gecko based browsers
        if dissect.first(where: { $0.hasPrefix("Gecko/") }) != nil {
            // Gecko version is fixed to 20100101, we have to read rv: value
            let version = (dissect.first(where: { $0.hasPrefix("rv:") })?.replacingOccurrences(of: "rv:", with: "", options: .anchored).trimmingCharacters(in: CharacterSet(charactersIn: "); ")).components(separatedBy: ".").prefix(2).joined(separator: ".")).flatMap(Float.init)
            return ("Gecko", version)
        }
        // Trident based
        if let trident = dissect.first(where: { $0.hasPrefix("Trident") }) {
            return getVersion(trident)
        }
        
        // Indeed unknown browser but compatible with Netscape/Mozila.
        return dissect.first.flatMap({ getVersion($0) }) ?? ("Mozila", 5.0)
    }
    
    /// Returns client's operating system name and version (if available) using `User-Agent`.
    /// - Note: return value for macOS begins with `"Intel Mac OS X"` or `"PPC Mac OS X"`.
    /// - Note: return value for iOS begins with `"iOS"`.
    public var clientOperatingSystem: String? {
        guard let agent = self.storage[.userAgent]?.first else {
            return nil
        }
        
        guard let parIndex = agent.index(of: "(") else {
            return nil
        }
        
        // Extract first paranthesis enclosed substring
        let deviceString = String(agent[parIndex..<(agent.index(of: ")") ?? agent.endIndex)])
        var deviceArray = deviceString.trimmingCharacters(in: CharacterSet(charactersIn: " ;()")).components(separatedBy: ";").map({ $0.trimmingCharacters(in: .whitespaces) })
        // Remove frequent but meaningless ids
        let isX11 = deviceArray.index(of: "X11") != nil
        let removable: [String] = ["X11", "U", "I", "compatible", "Macintosh"]
        deviceArray = deviceArray.filter({ !removable.contains($0) })
        
        // Check for known misarrangements!
        
        // Check for Windows Phone to ignore redundant Android in string
        if let windows = deviceArray.first(where: { $0.hasPrefix("Windows") }) {
            return windows
        }
        // Check Android
        if let android = deviceArray.first(where: { $0.hasPrefix("Android") }) {
            return android
        }
        // Check Tizen
        if let tizen = deviceArray.first(where: { $0.hasPrefix("Tizen") }) {
            return tizen
        }
        // Check iOS
        if let ios = deviceArray.first(where: { $0.hasPrefix("CPU iPhone OS") || $0.hasPrefix("CPU OS") }) {
            let version = ios.components(separatedBy: " OS ").dropFirst().first?.replacingOccurrences(of: "_", with: ".") ?? ""
            return "iOS \(version)"
        }
        
        return deviceArray.first ?? (isX11 ? "X11" : nil)
    }
    
    // MARK: Response Headers
    
    /// `Accept-Ranges` header value.
    public var acceptRanges: RangeType? {
        get {
            return self.storage[.acceptRanges]?.first.flatMap(RangeType.init(rawValue:))
        }
        set {
            self.storage[.acceptRanges] = newValue.flatMap { [$0.rawValue] }
        }
    }
    
    /// `Age` header value.
    public var age: TimeInterval? {
        get {
            return self.storage[.age]?.first.flatMap(TimeInterval.init)
        }
        set {
            // TOCHECK: Can't be a negative value
            self.storage[.age] = newValue.flatMap { [String(Int($0))] }
        }
    }
    
    /// `Allow` header value. An empty array means no value is set in header.
    public var allow: [HTTPMethod] {
        get {
            return self.storage[.allow]?.flatMap({ (value) -> [String] in
                return value.components(separatedBy: ",")
            }).flatMap({ HTTPMethod($0) }) ?? []
        }
        set {
            if !newValue.isEmpty {
                self.storage[.allow] = newValue.map { $0.method }
            } else {
                self.storage[.allow] = nil
            }
        }
    }
    
    /// `Cache-Control` header values. An empty array means no value is set in header.
    /// - Note: Please set appropriate value according to request/response state of header.
    ///     No control is implmemted to check either value is appropriate for type of header or not.
    public var cacheControl: [HTTPHeaders.CacheControl] {
        get {
            return self.storage[.cacheControl]?.flatMap({ (value) -> [String] in
                return value.components(separatedBy: ",")
            }).flatMap(CacheControl.init) ?? []
        }
        set {
            if !newValue.isEmpty {
                self.storage[.cacheControl] = newValue.flatMap { $0.description }
            } else {
                self.storage[.cacheControl] = nil
            }
        }
    }
    
    /// `Connection` header value. An empty array means no value is set in header.
    public var connection: [HTTPHeaders.Name] {
        get {
            return self.storage[.connection]?.flatMap({ (value) -> [String] in
                return value.components(separatedBy: ",")
            }).map({ HTTPHeaders.Name($0) }) ?? []
        }
        set {
            // TOCHECK: Only keepAlive is valid?
            if !newValue.isEmpty {
                self.storage[.connection] = newValue.flatMap { $0.lowercased }
            } else {
                self.storage[.connection] = nil
            }
        }
    }
    
    /// `Content-Disposition` header value.
    public var contentDisposition: HTTPHeaders.ContentDisposition? {
        get {
            return self.storage[.contentDisposition]?.first.flatMap(ContentDisposition.init)
        }
        set {
            self.storage[.contentDisposition] = newValue.flatMap { [$0.description] }
        }
    }
    
    /// `Content-Encoding` header value.
    public var contentEncoding: HTTPHeaders.Encoding? {
        get {
            return self.storage[.contentEncoding]?.first.flatMap(Encoding.init)
        }
        set {
            self.storage[.contentEncoding] = newValue.flatMap { [$0.rawValue] }
        }
    }
    
    /// `Content-Language` header value.
    public var contentLanguage: Locale? {
        get {
            return self.storage[.contentLanguage]?.first.flatMap(Locale.init(identifier:))
        }
        set {
            self.storage[.contentLanguage] = newValue.flatMap { [$0.identifier.replacingOccurrences(of: "_", with: "-")] }
        }
    }
    
    /// `Content-Length` header value.
    public var contentLength: Int64? {
        get {
            return self.storage[.contentLength]?.first.flatMap { Int64($0) }
        }
        set {
            // TOCHECK: Can't be a negative value.
            self.storage[.contentLength] = newValue.flatMap { [String($0)] }
        }
    }
    
    /// `Content-Location` header value.
    public var contentLocation: URL? {
        get {
            return self.storage[.contentLocation]?.first.flatMap(URL.init(string:))
        }
        set {
            self.storage[.contentLength] = newValue.flatMap { [$0.absoluteString] }
        }
    }
    
    /// `Content-MD5` header value, parsed from Base64 into `Data`.
    public var contentMD5: Data? {
        get {
            // TODO: Tolerate base64 string not padded with =, Should we?
            return self.storage[.contentMD5]?.first.flatMap { Data(base64Encoded: $0) }
        }
        set {
            self.storage[.contentMD5] = newValue.flatMap { [$0.base64EncodedString()] }
        }
    }
    
    fileprivate func dissectContentRange(_ value: String?) -> (from: Int64, to: Int64?, total: Int64?)? {
        // Converting real negatives to _ to avoid conflict with - as separator
        let value = value?.replacingOccurrences(of: "=-", with: "=_").replacingOccurrences(of: "--", with: "-_")
        guard let bytes = value?.components(separatedBy: "=").dropFirst().first?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        
        let passes = bytes.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let bounds = passes.first?.components(separatedBy: "-").map({ $0.trimmingCharacters(in: .whitespaces) }) else {
            return nil
        }
        
        let total = bytes.components(separatedBy: "/").dropFirst().first.flatMap { Int64($0) }
        let lower = bounds.first.flatMap { Int64($0.replacingOccurrences(of: "_", with: "-")) }
        let upper = bounds.dropFirst().first.flatMap { Int64($0) }
        return (lower ?? 0, upper, total)
    }
    
    fileprivate func createRange(from: Int64, to: Int64? = nil, total: Int64? = nil, type: HTTPHeaders.RangeType = .bytes) -> String? {
        guard from >= 0, (to ?? 0) >= 0, (total ?? 1) >= 1 else {
            return total.flatMap({ "*/\($0)" })
        }
        let toString = to.flatMap(String.init) ?? ""
        let totalString = total.flatMap({ "/\($0)" }) ?? "/*"

        return "\(type.rawValue)=\(from)-\(toString)\(totalString)"
    }
    
    /// Returns `Content-Range` header value.
    /// - Note: upperbound will be Int64.max in case of open ended Range.
    /// - Important: A negative range means server must return last bytes/items of file
    public var contentRange: Range<Int64>? {
        // TODO: return PartialRangeFrom when possible
        get {
            guard let elements = self.storage[.contentRange]?.first.flatMap({ self.dissectContentRange($0) }) else {
                return nil
            }
            let to = elements.to.flatMap({ $0 + 1 }) ?? Int64.max
            return elements.from..<to
        }
    }
    
    /// Returns `Content-Range` type, usually `.bytes`.
    public var contentRangeType: RangeType? {
        get {
            return self.storage[.contentRange]?.first?.components(separatedBy: "=").first.flatMap(HTTPHeaders.RangeType.init(rawValue:))
        }
    }
    
    /// Set `Content-Range` header.
    public mutating func set(contentRange: Range<Int64>, size: Int64? = nil, type: HTTPHeaders.RangeType = .bytes) {
        // TOCHECK: size >= contentRange.count, type != .none
        let upper: Int64? = contentRange.upperBound == Int64.max ? nil : (contentRange.upperBound - 1)
        let rangeStr = createRange(from: contentRange.lowerBound, to: upper, total: size, type: type)
        self.storage[.contentRange] = rangeStr.flatMap { [$0] }
    }
    
    /// Set `Content-Range` header, set upperbound to `Int64.max` to set an opened-end range.
    public mutating func set(contentRange: ClosedRange<Int64>, size: Int64? = nil, type: HTTPHeaders.RangeType = .bytes) {
        // TOCHECK: size >= contentRange.count, type != .none
        let upper: Int64? = contentRange.upperBound == Int64.max ? nil : (contentRange.upperBound - 1)
        let rangeStr = createRange(from: contentRange.lowerBound, to: upper, total: size, type: type)
        self.storage[.contentRange] = rangeStr.flatMap { [$0] }
    }
    
    #if swift(>=4.0)
    /// Set half-open `Content-Range`.
    public mutating func set(contentRange: PartialRangeFrom<Int64>, size: Int64? = nil, type: HTTPHeaders.RangeType = .bytes) {
        // TOCHECK: size >= 0, type != .none
        let rangeStr = createRange(from: contentRange.lowerBound, total: size, type: type)
        self.storage[.contentRange] = rangeStr.flatMap { [$0] }
    }
    #endif
    
    /// `Content-Type` header value.
    public var contentType: ContentType? {
        get {
            return self.storage[.contentType]?.first.flatMap(ContentType.init)
        }
        set {
            self.storage[.contentType] = newValue.flatMap { [$0.description] }
        }
    }
    
    /// `Date` header value.
    public var date: Date? {
        get {
            return self.storage[.date]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            // TOCHECK: newValue <= Date()
            self.storage[.date] = newValue.flatMap { [$0.format(with: .http)] }
        }
    }
    
    /// `ETag` header value.
    public var eTag: EntryTag? {
        get {
            return self.storage[.eTag]?.first.flatMap(EntryTag.init)
        }
        set {
            // TOCHECK: wildcard should be ignored
            self.storage[.eTag] = newValue.flatMap { [$0.description] }
        }
    }
    
    /// `Expires` header value.
    public var expires: Date? {
        get {
            return self.storage[.expires]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            // TOCHECK: newValue =< Date() + 1 year
            self.storage[.expires] = newValue.flatMap { [$0.format(with: .http)] }
        }
    }
    
    /// `Last-Modified` header value.
    public var lastModified: Date? {
        get {
            return self.storage[.lastModified]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            // TOCHECK: newValue <= Date()
            self.storage[.lastModified] = newValue.flatMap { [$0.format(with: .http)] }
        }
    }
    
    /// `Location` header value.
    public var location: URL? {
        get {
            return self.storage[.location]?.first.flatMap(URL.init(string:))
        }
        set {
            self.storage[.location] = newValue.flatMap { [$0.absoluteString] }
        }
    }
    
    /// `Pragma` header value.
    public var pragma: Pragma? {
        get {
            return self.storage[.pragma]?.first.flatMap(Pragma.init)
        }
        set {
            self.storage[.pragma] = newValue.flatMap { [$0.rawValue] }
        }
    }
    
    /// `Set-Cookie` header values. An empty array means no value is set in header.
    public var setCookie: [HTTPCookie] {
        return self.storage[.setCookie]?.flatMap({ HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": $0], for: URL(string: "/")!) }) ?? []
    }
    
    /// Appends a cookie to`Set-Cookie` header values.
    /// - Parameter setCookie: The cookie object to be appended.
    public mutating func add(setCookie cookie: HTTPCookie) {
        if self.storage[.setCookie] == nil {
            self.storage[.setCookie] = []
        }
        
        var cookieString = "\(cookie.name)"
        cookieString += !cookie.value.isEmpty ? "=\(cookie)" : ""
        cookieString += cookie.expiresDate.flatMap({ "; Expires=\($0.format(with: .http))" }) ?? ""
        cookieString += !(cookie.domain.isEmpty || cookie.domain == "^filecookies^") ? "; Domain=\(cookie.domain)" : ""
        cookieString += !cookie.path.isEmpty ? "; Path=\(cookie.path)" : ""
        cookieString += cookie.properties?[.maximumAge].flatMap({ "; Max-Age=\($0)" }) ?? ""
        cookieString += cookie.properties?[.comment].flatMap({ "; Comment=\"\($0)\"" }) ?? ""
        cookieString += cookie.isSecure ? "; Secure" : ""
        cookieString += cookie.isHTTPOnly ? "; HttpOnly" : ""
        self.storage[.setCookie]?.append(cookieString)
    }
    
    /// Appends a cookie to`Set-Cookie` header values.
    /// - Parameter name: Name of cookie.
    /// - Parameter name: Value of cookie. Can be empty string of cookie has no value.
    /// - Parameter path: Indicates a URL path that must exist in the requested resource.
    /// - Parameter domain: Specifies those hosts to which the cookie will be sent.
    /// - Parameter expiresDate: The maximum lifetime of the cookie as an HTTP-date timestamp.
    /// - Parameter maximumAge: Number of seconds until the cookie expires.
    /// - Parameter comment: Comment of cookie application shown in browser settings to user.
    /// - Parameter isSecure: Cookie has `Secure` attribute. HTTPS encrypted sites will be supported if ture.
    /// - Parameter isHTTPOnly: Cookie has `HTTPOnly` attribute, unaccessible by javascript.
    /// - Parameter others: Other possible parameters for cookie.
    public mutating func add(setCookie name: String, value: String, path: String, domain: String, expiresDate: Date? = nil, maximumAge: TimeInterval? = nil, comment: String? = nil, isSecure: Bool = false, isHTTPOnly: Bool = false, others: [String: String] = [:]) {
        if self.storage[.setCookie] == nil {
            self.storage[.setCookie] = []
        }
        
        var cookieString = "\(name)"
        cookieString += !value.isEmpty ? "=\(cookie)" : ""
        cookieString += expiresDate.flatMap({ "; Expires=\($0.format(with: .http))" }) ?? ""
        cookieString += !(domain.isEmpty || domain == "^filecookies^") ? "; Domain=\(domain)" : ""
        cookieString += !path.isEmpty ? "; Path=\(path)" : ""
        cookieString += maximumAge.flatMap({ "; Max-Age=\(Int($0))" }) ?? ""
        cookieString += comment.flatMap({ "; Comment=\"\($0)\"" }) ?? ""
        cookieString += isSecure ? "; Secure" : ""
        cookieString += isHTTPOnly ? "; HttpOnly" : ""
        for item in others {
            cookieString += !item.value.isEmpty ? "; \(item.key)=\(item.value)" : "\(item.key)"
        }
        self.storage[.setCookie]?.append(cookieString)
    }
    
    /// `Trailer` header value. An empty array means no value is set in header.
    public var trailer: [HTTPMethod] {
        get {
            return self.storage[.trailer]?.flatMap({ HTTPMethod($0) }) ?? []
        }
        set {
            if !newValue.isEmpty {
                // TOCHECK: Forbidden headers ought to be ignored/dropped
                self.storage[.trailer] = newValue.map { $0.method }
            } else {
                self.storage[.trailer] = nil
            }
        }
    }
    
    /// `Vary` header value. An empty array means no value is set in header.
    public var vary: [HTTPMethod] {
        get {
            return self.storage[.vary]?.flatMap({ HTTPMethod($0) }) ?? []
        }
        set {
            if !newValue.isEmpty {
                // TOCHECK: Forbidden headers ought to be ignored/dropped
                self.storage[.vary] = newValue.map { $0.method }
            } else {
                self.storage[.vary] = nil
            }
        }
    }
    
    /// `WWW-Authenticate` header value.
    public var wwwAuthenticate: HTTPHeaders.Challenge? {
        get {
            return self.storage[.wwwAuthenticate]?.first.flatMap(Challenge.init)
        }
        set {
            self.storage[.wwwAuthenticate] = newValue.flatMap { [$0.description] }
        }
    }
}

extension HTTPHeaders {
    fileprivate static func parseQuilified<T>(_ value: [String], _ initializer: (String) -> T) -> [T] {
        return value.flatMap({ (value) -> [String] in
            return value.components(separatedBy: ",")
        }).flatMap({ (value) -> (typed: T, q: Double)? in
            let typed = initializer(value)
            let q = parseParams(value)["q"].flatMap(Double.init) ?? 1
            // Removing values with q=0 according to [RFC7231](https://tools.ietf.org/html/rfc7231)
            if q == 0 {
                return nil
            }
            return (typed, q)
        }).sorted(by: {
            $0.q > $1.q
        }).map({ $0.typed })
    }
    
    private static func parseParams(rawParams: [String], removeQuotation: Bool) -> [String: String] {
        var params: [String: String] = [:]
        for rawParam in rawParams {
            let arg = rawParam.components(separatedBy: "=")
            if let key = arg.first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                if key.hasSuffix("*") {
                    let decodedKey = key.replacingOccurrences(of: "*", with: "", options: [.backwards, .anchored])
                    let value = arg.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                    let decodedValue = value.decodingRFC5987
                    params[decodedKey] = decodedValue
                } else {
                    let trimCharset = removeQuotation ? CharacterSet(charactersIn: " ;\r\n\"") : .whitespacesAndNewlines
                    let value = arg.dropFirst().joined(separator: "=").trimmingCharacters(in: trimCharset)
                    params[key] = value
                }
            }
        }
        return params
    }
    
    /// Converts `name=value` pairs into a dictionary
    fileprivate static func parseParams(_ value: String, separator: String = ";", removeQuotation: Bool = false) -> [String: String] {
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
        for param in params {
            if param.value.isEmpty {
                 result.append(param.key)
            } else if param.value.isAscii {
                if (quotedKeys.contains(param.key) || (quotationValue && !nonquotatedKeys.contains(param.key))) {
                    result.append("\(param.key)=\"\(param.value.trimmingCharacters(in: .quoted))\"")
                } else {
                    result.append("\(param.key)=\(param.value)")
                }
            } else {
                let keyval = "\(param.key)*=\(param.value.rfc5987encoded)"
                result.append(keyval)
            }
        }
        return result.joined(separator: separator)
    }
    
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
    
    fileprivate static func charsetIANAToStringEncoding(_ charset: String) -> String.Encoding {
        #if os(macOS) || os(iOS) || os(tvOS)
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
            } else {
                return .isoLatin1
            }
        #else
            // CFStringConvertIANACharSetNameToEncoding is not exposed in SwiftFoundation!
            // We use this as workaround until SwiftFoundation got fixed.
            let charset = charset.lowercased()
            return HTTPHeaders.ianatable.first(where: { return $0.value == charset })?.key ?? .isoLatin1
        #endif
    }
    
    fileprivate static func StringEncodingToIANA(_ encoding: String.Encoding) -> String {
        // Default charset for HTTP 1.1 is "iso-8859-1"
        #if os(macOS) || os(iOS) || os(tvOS)
            return (CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)) as String?) ?? "iso-8859-1"
        #else
            // CFStringConvertEncodingToIANACharSetName is not exposed in SwiftFoundation!
            // We use this as workaround until SwiftFoundation got fixed.
            return HTTPHeaders.ianatable[encoding] ?? "iso-8859-1"
        #endif
    }

}

fileprivate extension Date {
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
    
    private static let defaultLocale = Locale(identifier: "en_US_POSIX")
    private static let defaultTimezone = TimeZone(identifier: "UTC")
    
    /// Checks date string against various RFC standards and returns `Date`.
    init?(rfcString: String) {
        let dateFor: DateFormatter = DateFormatter()
        dateFor.locale = Date.defaultLocale
        
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
        fm.timeZone = timeZone ?? Date.defaultTimezone
        fm.locale = locale ?? Date.defaultLocale
        return fm.string(from: self)
    }
}

fileprivate extension CharacterSet {
    static let quoted = CharacterSet(charactersIn: "\"")
    static let quotedWhitespace = CharacterSet(charactersIn: "\" ")
    static let legal = CharacterSet(charactersIn: "!#$&+-.^_`|~").intersection(.alphanumerics).inverted
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
    
    var isoLatinStripped: String {
        let isoLatinCharset = CharacterSet.init(charactersIn: Unicode.Scalar(32)..<Unicode.Scalar(255))
        let isoLatin = self.filter({ $0.unicodeScalars.count == 1 ? isoLatinCharset.contains($0.unicodeScalars.first!) : false })
        return isoLatin
    }
    
    /// Returns percent encoded string according to [RFC 8187](https://tools.ietf.org/html/rfc8187)
    var rfc5987encoded: String {
        let encoded = self.addingPercentEncoding(withAllowedCharacters: .legal) ?? self
        return "UTF-8''\(encoded)"
    }
    
    /// Converts percent encoded to normal string according to [RFC 8187](https://tools.ietf.org/html/rfc8187)
    var decodingRFC5987: String {
        let components = self.components(separatedBy: "'")
        guard components.count >= 3 else {
            return self
        }
        let encoding = HTTPHeaders.charsetIANAToStringEncoding(components.first!)
        let string = components.dropFirst(2).joined(separator: "'")
        return string.removingPercentEscapes(encoding: encoding) ?? string
    }
    
    // Similiar method is deprecated in Foundation, we implemented ours!
    func removingPercentEscapes(encoding: String.Encoding) -> String? {
        if encoding == .utf8 {
            return self.removingPercentEncoding
        }
        
        var str = self
        while true {
            guard let index = str.index(of: "%") else {
                break
            }
            var range = index..<(str.index(index, offsetBy: 3))
            while str[range.upperBound] == "%" {
                range = range.lowerBound..<str.index(range.upperBound, offsetBy: 3)
            }
            let percentEncoded = str[range]
            let bytes: [UInt8] = percentEncoded.split(separator: "%").flatMap({ UInt8($0, radix: 16) })
            
            let charData = Data(bytes: bytes)
            guard let converted = String(data: charData, encoding: encoding) else {
                return nil
            }
            str.replaceSubrange(range, with: converted)
        }
        return str
    }
}
