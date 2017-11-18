// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation

extension HTTPHeaders {
    
    /// MIME type directive for `Accept` and `Content-Type` headers
    public struct ContentType: RawRepresentable, Hashable, Equatable {
        public var rawValue: String
        public typealias RawValue = String
        
        public init(rawValue: String) {
            self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        
        public var hashValue: Int { return rawValue.hashValue }
        public static func == (lhs: ContentType, rhs: ContentType) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        /// Directory
        static public let directory = ContentType(rawValue: "httpd/unix-directory")
        
        // Archive and Binary
        
        /// All types
        static public let all = ContentType(rawValue: "*/*")
        /// Binary stream and unknown types
        static public let stream = ContentType(rawValue: "application/octet-stream")
        /// Protable document format
        static public let pdf = ContentType(rawValue: "application/pdf")
        /// Zip archive
        static public let zip = ContentType(rawValue: "application/zip")
        /// Rar archive
        static public let rarArchive = ContentType(rawValue: "application/x-rar-compressed")
        /// 7-zip archive
        static public let lzma = ContentType(rawValue: "application/x-7z-compressed")
        /// Adobe Flash
        static public let flash = ContentType(rawValue: "application/x-shockwave-flash")
        /// ePub book
        static public let epub = ContentType(rawValue: "application/epub+zip")
        /// Java archive (jar)
        static public let javaArchive = ContentType(rawValue: "application/java-archive")
        
        // Texts
        
        /// All Text types
        static public let text = ContentType(rawValue: "text/*")
        /// Text file
        static public let plainText = ContentType(rawValue: "text/plain")
        /// Coma-separated values
        static public let csv = ContentType(rawValue: "text/csv")
        /// Hyper-text markup language
        static public let html = ContentType(rawValue: "text/html")
        /// Common style sheet
        static public let css = ContentType(rawValue: "text/css")
        /// eXtended Markup language
        static public let xml = ContentType(rawValue: "text/xml")
        /// Javascript code file
        static public let javascript = ContentType(rawValue: "application/javascript")
        /// Javascript notation
        static public let json = ContentType(rawValue: "application/json")
        
        // Documents
        
        /// Rich text file (RTF)
        static public let richText = ContentType(rawValue: "application/rtf")
        /// Excel 2013 (OOXML) document
        static public let excel = ContentType(rawValue: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        /// Powerpoint 2013 (OOXML) document
        static public let powerpoint = ContentType(rawValue: "application/vnd.openxmlformats-officedocument.presentationml.slideshow")
        /// Word 2013 (OOXML) document
        static public let word = ContentType(rawValue: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
        
        // Images
        
        /// Bitmap
        static public let bmp = ContentType(rawValue: "image/bmp")
        /// Graphics Interchange Format photo
        static public let gif = ContentType(rawValue: "image/gif")
        /// JPEG photo
        static public let jpeg = ContentType(rawValue: "image/jpeg")
        /// Portable network graphics
        static public let png = ContentType(rawValue: "image/png")
        
        // Audio & Video
        
        /// All Audio types
        static public let audio = ContentType(rawValue: "audio/*")
        /// All Video types
        static public let video = ContentType(rawValue: "video/*")
        /// MPEG Audio
        static public let mpegAudio = ContentType(rawValue: "audio/mpeg")
        /// MPEG Video
        static public let mpeg = ContentType(rawValue: "video/mpeg")
        /// MPEG4 Audio
        static public let mpeg4Audio = ContentType(rawValue: "audio/mp4")
        /// MPEG4 Video
        static public let mpeg4 = ContentType(rawValue: "video/mp4")
        /// OGG Audio
        static public let ogg = ContentType(rawValue: "audio/ogg")
        /// Advanced Audio Coding
        static public let aac = ContentType(rawValue: "audio/x-aac")
        /// Microsoft Audio Video Interleaved
        static public let avi = ContentType(rawValue: "video/x-msvideo")
        /// Microsoft Wave audio
        static public let wav = ContentType(rawValue: "audio/x-wav")
        /// Apple QuickTime format
        static public let quicktime = ContentType(rawValue: "video/quicktime")
        /// 3GPP
        static public let threegp = ContentType(rawValue: "video/3gpp")
    }
    
    /// Values available for `Conten-Disposition` header
    public enum ContentDisposition: CustomStringConvertible, Equatable {
        /// Default value, which indicates file must be shown in browser
        case inline
        /// Downloadable content, with specifed filename if available
        case attachment(filename: String?)
        /// Form-Data
        case formData(name: String?, filename: String?)
        
        public init?( _ rawValue: String) {
            guard let type = rawValue.components(separatedBy: ";").first?.lowercased() else {
                return nil
            }
            let params = HTTPHeaders.parseParams(rawValue)
            let name = params["name"]?.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .quoted)
            let filename = params["filename*"].flatMap(HTTPHeaders.parseRFC5987) ?? params["filename"]
            
            switch type {
            case "inline", "":
                self = .inline
            case "attachment":
                self = .attachment(filename: filename)
            case "form-data":
                self = .formData(name: name, filename: filename)
            default:
                return nil
            }
        }
        
        public var description: String {
            switch self {
            case .inline:
                return "inline"
            case .attachment(filename: let filename):
                // FIX: Use filename* for utf-8 file names
                let filenameParam = filename.flatMap({ "; filename=\"\($0)\"" }) ?? ""
                return "attachment\(filenameParam)"
            case .formData(name: let name, filename: let filename):
                let nameParam = name.flatMap({ "; name=\"\($0)\"" }) ?? ""
                let filenameParam = filename.flatMap({ "; filename=\"\($0)\"" }) ?? ""
                return "attachment\(nameParam)\(filenameParam)"
            }
        }
        
        public static func ==(lhs: HTTPHeaders.ContentDisposition, rhs: HTTPHeaders.ContentDisposition) -> Bool {
            return lhs.description == rhs.description
        }
}
    
    public enum CacheControl: CustomStringConvertible, Equatable {
        // Both Request and Response
        
        case noCache
        case noStore
        case noTransform
        case maxAge(TimeInterval)
        
        // Only Request
        
        case onlyIfCached
        case maxStale(TimeInterval)
        case minFresh(TimeInterval)
        
        // Only Response
        
        case `public`
        case `private`
        case privateWithField(field: String)
        case noCacheWithField(field: String)
        case mustRevalidate
        case proxyRevalidate
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
                return nil
            }
        }
        
        public static func ==(lhs: HTTPHeaders.CacheControl, rhs: HTTPHeaders.CacheControl) -> Bool {
            return lhs.description == rhs.description
        }
    }
    
    /// Defines HTTP Authorization request
    /// -Note: Paramters may be quoted or not according to RFCs
    public enum Authorization: CustomStringConvertible {
        /// Basic method [RFC7617](http://www.iana.org/go/rfc7617)
        case basic(user: String, password: String)
        /// Digest method [RFC7616](http://www.iana.org/go/rfc7616)
        case digest(params: [String: String])
        /// OAuth 1.0 method (OAuth) [RFC5849, Section 3.5.1](http://www.iana.org/go/rfc5849)
        case oAuth1(token: String)
        /// OAuth 2.0 method (Bearer) [RFC6750](http://www.iana.org/go/rfc6750)
        case oAuth2(token: String)
        /// Mututal method [RFC8120](http://www.iana.org/go/rfc8120)
        case mutual(params: [String: String])
        /// Negotiate method [RFC4559, Section 3](http://www.iana.org/go/rfc4559)
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
                var params = HTTPHeaders.parseParams(q)
                var token: String?
                for param in params {
                    if param.value.isEmpty {
                        token = param.key
                        params[param.key] = nil
                        break
                    }
                }
                self = .custom(type, token: token, params: params)
            }
        }
        
        public var description: String {
            switch self {
            case .basic(let user, let password):
                let text = "\(user):\(password)"
                let b64 = (text.data(using: .ascii) ?? text.data(using: .utf8))?.base64EncodedString() ?? ""
                return "Basic \(b64)"
            case .digest(let params):
                let paramsString = params.map({ "\($0.key)=\($0.value)" }).joined(separator: ", ")
                return "Digest \(paramsString)"
            case .oAuth1(let token):
                return "OAuth \(token)"
            case .oAuth2(let token):
                return "Bearer \(token)"
            case .mutual(let params):
                let paramsString = params.map({ "\($0.key)=\($0.value)" }).joined(separator: ", ")
                return "Mutual \(paramsString)"
            case .negotiate(let data):
                return "Negotiate \(data.base64EncodedString())"
            case .custom(let type, let token, let params):
                let tokenString = token.flatMap({ "\($0) " }) ?? ""
                let paramsString = params.map({ "\($0.key)=\($0.value)" }).joined(separator: ", ")
                return "\(type) \(tokenString)\(paramsString)"
            }
        }
    }
    
    /// Defines HTTP Authentication challenge method required to access
    public enum ChallengeType: CustomStringConvertible {
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
        /// Negotiate method [RFC4559, Section 3](http://www.iana.org/go/rfc4559)
        case negotiate
        /// Custom authentication method
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
    }
    
    /// Challenge defined in WWW-Authenticate
    /// -Note: Paramters may be quoted or not according to RFCs
   public struct Challenge: CustomStringConvertible {
        let type: ChallengeType
        let parameters: [String: String]
        var realm: String? {
            return parameters["realm"]?.trimmingCharacters(in: .quoted)
        }
        var charset: String.Encoding? {
            return parameters["charset"].flatMap(HTTPHeaders.charsetIANAToStringEncoding)
        }
        
        public init(type: ChallengeType, token: String? = nil, realm: String? = nil, charset: String.Encoding? = nil, parameters: [String: String] = [:]) {
            self.type = type
            var parameters = parameters
            parameters["realm"] = (realm?.trimmingCharacters(in: .quoted)).flatMap({ "\"\($0)\"" })
            parameters["charset"] = charset.flatMap(HTTPHeaders.StringEncodingToIANA)
            self.parameters = parameters
        }
        
        public init?(_ rawValue: String) {
            let typeSegment = rawValue.components(separatedBy: " ")
            guard let type = typeSegment.first.flatMap(ChallengeType.init) else { return nil }
            self.type = type
            let allparams = typeSegment.dropFirst().joined(separator: " ")
            let params: [(String, String)] = allparams.components(separatedBy: ",").flatMap { param in
                let keyval = param.components(separatedBy: "=")
                guard let key = keyval.first?.trimmingCharacters(in: .whitespaces), !key.isEmpty else { return nil }
                let value = keyval.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
                return (key, value)
            }
            self.parameters = Dictionary(params, uniquingKeysWith: { (f, s) in
                return f
            })
        }
        
        public var description: String {
            let params = parameters.map({ "\($0.key)=\($0.value)" }).joined(separator: ", ")
            return "\(type.description) \(params)"
        }
    }
    
    /// EntryTag used in `ETag`, `If-Modified`, etc
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
            let linted = rawValue.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .quotedWhitespace)
            self = .strong(linted)
        }
        
        public var description: String {
            switch self {
            case .strong(let etag):
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
            return lhs.description == rhs.description
        }
    }
    
    /// Encoding of body
    public enum Encoding: String {
        /// Accepting all encodings available
        case all = "*"
        /// Send body as is
        case identity
        /// Compress body data using lzw method
        case compress
        /// Compress body data using zlib deflate method
        case deflate
        /// Compress body data using gzip method
        case gzip
        /// Compress body data using brotli method
        case brotli = "br"
        
        // These values are valid for Transfer Encoding
        
        /// Chunked body in `Transfer-Encoding` response header
        case chunked
        /// Can have trailers in `TE` request header
        case trailers
    }
    
    /// Determines server accepts `Range` header or not
    public enum RangeType: String {
        /// Can't accept Range
        case none
        /// Accept range in bytes(octets)
        case bytes
    }
    
    /// `Pragma` header values
    public enum Pragma: String {
        // no-cache for Pragma
        case noCache = "no-cache"
    }
    
    // MARK: Request Headers
    
    /// Fetch `Accept` header values, sorted by `q` parameter
    public var accept: [ContentType] {
        get {
            let values: [String]? = self.storage[.accept]?.sorted {
                let q0 = HTTPHeaders.parseParams($0)["q"].flatMap(Double.init) ?? 1
                let q1 = HTTPHeaders.parseParams($1)["q"].flatMap(Double.init) ?? 1
                return q0 > q1
            }
            let results = (values ?? []).map { ContentType(rawValue: $0) }
            return results
        }
    }
    
    /// Sets new value for `Accept` header and removes previous values if set
    public mutating func set(accept: ContentType, quality: Double?) {
        self.storage[.accept]?.removeAll()
        self.add(accept: accept, quality: quality)
    }
    
    /// Adds a new `Accept` header value
    public mutating func add(accept: ContentType, quality: Double?) {
        if self.storage[.accept] == nil {
            self.storage[.accept] = []
        }
        if let qualityDesc = quality.flatMap({ String(format: "%.1f", Double.minimum(0, Double.maximum($0, 1))) }) {
            self.storage[.accept]!.append("\(accept.rawValue); q=\(qualityDesc)")
        } else {
            self.storage[.accept]!.append(accept.rawValue)
        }
    }
    
    /// Sets new value for `Accept-Encoding` header and removes previous values if set
    mutating func set(acceptCharset: String.Encoding, quality: Double? = nil) {
        self.storage[.acceptCharset]?.removeAll()
        self.add(acceptCharset: acceptCharset, quality: quality)
    }
    
    /// Adds a new `Accept-Encoding` header value
    mutating func add(acceptCharset: String.Encoding, quality: Double? = nil) {
        if self.storage[.acceptCharset] == nil {
            self.storage[.acceptCharset] = []
        }
        let charsetString = HTTPHeaders.StringEncodingToIANA(acceptCharset)
        if let qualityDesc = quality.flatMap({ String(format: "%.1f", Double.minimum(0, Double.maximum($0, 1))) }) {
            self.storage[.acceptCharset]!.append("\(charsetString); q=\(qualityDesc)")
        } else {
            self.storage[.acceptCharset]!.append(charsetString)
        }
    }
    
    /// `Accept-Datetime` header
    public var acceptDatetime: Date? {
        get {
            return self.storage[.acceptDatetime]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            self.storage[.acceptDatetime] = newValue.flatMap { [$0.format(with: .http)] }
        }
    }
    
    /// Fetch `Accept-Encoding` header values, sorted by `q` parameter
    public var acceptEncoding: [Encoding] {
        get {
            let values: [String]? = self.storage[.acceptEncoding]?.sorted {
                let q0 = HTTPHeaders.parseParams($0)["q"].flatMap(Double.init) ?? 1
                let q1 = HTTPHeaders.parseParams($1)["q"].flatMap(Double.init) ?? 1
                return q0 > q1
            }
            let results = (values ?? []).flatMap { Encoding(rawValue: $0) }
            return results
        }
    }
    
    /// Sets new value for `Accept` header and removes previous values if set
    public mutating func set(acceptEncoding: Encoding, quality: Double?) {
        self.storage[.acceptEncoding]?.removeAll()
        self.add(acceptEncoding: acceptEncoding, quality: quality)
    }
    
    /// Adds a new `Accept` header value
    public mutating func add(acceptEncoding: Encoding, quality: Double?) {
        if self.storage[.acceptEncoding] == nil {
            self.storage[.acceptEncoding] = []
        }
        if let qualityDesc = quality.flatMap({ String(format: "%.1f", Double.minimum(0, Double.maximum($0, 1))) }) {
            self.storage[.acceptEncoding]!.append("\(acceptEncoding.rawValue); q=\(qualityDesc)")
        } else {
            self.storage[.acceptEncoding]!.append(acceptEncoding.rawValue)
        }
    }
    
    // `Authorization` header value
    public var authorization: HTTPHeaders.Authorization? {
        get {
            return self.storage[.authorization]?.first.flatMap(Authorization.init)
        }
        set {
            self.storage[.authorization] = newValue.flatMap { [$0.description] }
        }
    }
    
    // `Cookie` header value
    public var cookie: [HTTPCookie] {
        let pairs: [(key: String, val: String)] = (self.storage[.cookie]?.first?.components(separatedBy: ";").flatMap { text in
            let segments = text.components(separatedBy: "=")
            guard let key = segments.first?.trimmingCharacters(in: .whitespaces), !key.isEmpty else {
                return nil
            }
            let value = segments.dropFirst().joined(separator: "=")
            return (key, value)
            }) ?? []
        
        return pairs.flatMap {
            // path should be set otherwise it will fail!
            return HTTPCookie(properties: [.name : $0.key, .value: $0.val, .path: "/"])
        }
    }
    
    /// `If-Match` header etag value
    public var ifMatch: [EntryTag] {
        get {
            return (self.storage[.ifMatch] ?? []).map(EntryTag.init)
        }
        set {
            // TOCHECK: When there is a wildcard, other values should be ignored
            if !newValue.isEmpty {
                self.storage[.ifMatch] = newValue.map { $0.description }
            } else {
                self.storage[.ifMatch] = nil
            }
        }
    }
    
    /// `If-None-Match` header etag value
    public var ifNoneMatch: [EntryTag] {
        get {
            return (self.storage[.ifNoneMatch] ?? []).map(EntryTag.init)
        }
        set {
            // TOCHECK: When there is a wildcard, other values should be ignored
            if !newValue.isEmpty {
                self.storage[.ifNoneMatch] = newValue.map { $0.description }
            } else {
                self.storage[.ifNoneMatch] = nil
            }
        }
    }
    
    /// `If-Range` header etag value
    public var ifRange: EntryTag? {
        get {
            return self.storage[.ifRange]?.first.flatMap(EntryTag.init)
        }
        set {
            self.storage[.ifRange] = newValue.flatMap { [$0.description] }
        }
    }
    
    /// `If-Modified-Since` header value
    public var ifModifiedSince: Date? {
        get {
            return self.storage[.ifModifiedSince]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            self.storage[.ifModifiedSince] = newValue.flatMap { [$0.format(with: .http)] }
        }
    }
    
    /// `If-Unmodified-Since` header value
    public var ifUnmodifiedSince: Date? {
        get {
            return self.storage[.ifUnmodifiedSince]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            self.storage[.ifUnmodifiedSince] = newValue.flatMap { [$0.format(with: .http)] }
        }
    }
    
    /// `Origin` header value
    public var origin: URL? {
        get {
            return self.storage[.origin]?.first.flatMap(URL.init(string:))
        }
        set {
            self.storage[.origin] = newValue.flatMap { [$0.absoluteString] }
        }
    }
    
    /// `Referer` header value
    public var referer: URL? {
        get {
            return self.storage[.referer]?.first.flatMap(URL.init(string:))
        }
        set {
            self.storage[.referer] = newValue.flatMap { [$0.absoluteString] }
        }
    }
    
    /// Fetch `TE` header values, sorted by `q` parameter
    public var te: [Encoding] {
        get {
            let values: [String]? = self.storage[.te]?.sorted {
                let q0 = HTTPHeaders.parseParams($0)["q"].flatMap(Double.init) ?? 1
                let q1 = HTTPHeaders.parseParams($1)["q"].flatMap(Double.init) ?? 1
                return q0 > q1
            }
            let results = (values ?? []).flatMap { Encoding(rawValue: $0) }
            return results
        }
    }
    
    // TODO: Parse User-Agent for Browser and Operating system
    
    // MARK: Response Headers
    
    /// `Accept-Ranges` header value
    public var acceptRanges: RangeType? {
        get {
            return self.storage[.acceptRanges]?.first.flatMap(RangeType.init(rawValue:))
        }
        set {
            self.storage[.acceptRanges] = newValue.flatMap { [$0.rawValue] }
        }
    }
    
    /// `Age` header value
    public var age: TimeInterval? {
        get {
            return self.storage[.age]?.first.flatMap(TimeInterval.init)
        }
        set {
            // TOCHECK: Can't be a negative value
            self.storage[.age] = newValue.flatMap { [String($0)] }
        }
    }
    
    /// `Allow` header value
    public var allow: [HTTPMethod] {
        get {
            return self.storage[.allow]?.flatMap({ HTTPMethod($0) }) ?? []
        }
        set {
            if !newValue.isEmpty {
                self.storage[.allow] = newValue.map { $0.method }
            } else {
                self.storage[.allow] = nil
            }
        }
    }
    
    /// `Cache-Control` header value
    /// - Note: Please set appropriate value according to request/response state of header.
    ///     No control is implmemted to check either value is appropriate for type of header or not.
    public var cacheControl: HTTPHeaders.CacheControl? {
        get {
            return self.storage[.cacheControl]?.first.flatMap(CacheControl.init)
        }
        set {
            self.storage[.cacheControl] = newValue.flatMap { [$0.description] }
        }
    }
    
    /// `Connection` header value
    public var connection: [HTTPMethod] {
        get {
            return self.storage[.connection]?.map({ HTTPMethod($0) }) ?? []
        }
        set {
            // TOCHECK: Only keepAlive is valid?
            if !newValue.isEmpty {
                self.storage[.connection] = newValue.flatMap { $0.method }
            } else {
                self.storage[.connection] = nil
            }
        }
    }
    
    /// `Content-Disposition` header value
    public var contentDisposition: HTTPHeaders.ContentDisposition? {
        get {
            return self.storage[.contentDisposition]?.first.flatMap(ContentDisposition.init)
        }
        set {
            self.storage[.contentDisposition] = newValue.flatMap { [$0.description] }
        }
    }
    
    /// `Content-Encoding` header value
    public var contentEncoding: HTTPHeaders.Encoding? {
        get {
            return self.storage[.contentEncoding]?.first.flatMap(Encoding.init)
        }
        set {
            self.storage[.contentEncoding] = newValue.flatMap { [$0.rawValue] }
        }
    }
    
    /// `Content-Language` header value
    public var contentLanguage: Locale? {
        get {
            return self.storage[.contentLanguage]?.first.flatMap(Locale.init(identifier:))
        }
        set {
            self.storage[.contentLanguage] = newValue.flatMap { [$0.identifier.replacingOccurrences(of: "_", with: "-")] }
        }
    }
    
    /// `Content-Length` header value
    public var contentLength: Int64? {
        get {
            return self.storage[.contentLength]?.first.flatMap { Int64($0) }
        }
        set {
            // TOCHECK: Can't be a negative value
            self.storage[.contentLength] = newValue.flatMap { [String($0)] }
        }
    }
    
    /// `Content-Location` header value
    public var contentLocation: URL? {
        get {
            return self.storage[.contentLocation]?.first.flatMap(URL.init(string:))
        }
        set {
            self.storage[.contentLength] = newValue.flatMap { [$0.absoluteString] }
        }
    }
    
    /// `Content-MD5` header value, parsed from Base64 into `Data`
    public var contentMD5: Data? {
        get {
            return self.storage[.contentMD5]?.first.flatMap { Data(base64Encoded: $0) }
        }
        set {
            self.storage[.contentMD5] = newValue.flatMap { [$0.base64EncodedString()] }
        }
    }
    
    fileprivate func dissectRange(_ value: String?) -> (from: Int64, to: Int64?, total: Int64?)? {
        guard let bytes = value?.components(separatedBy: "=").dropFirst().first?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        
        let passes = bytes.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let bounds = passes.first?.components(separatedBy: "-").map({ $0.trimmingCharacters(in: .whitespaces) }) else {
            return nil
        }
        
        let total = bytes.components(separatedBy: "/").dropFirst().first.flatMap { Int64($0) }
        let lower = bounds.first.flatMap { Int64($0) }
        let upper = bounds.dropFirst().first.flatMap { Int64($0) }
        return (lower ?? 0, upper, total)
    }
    
    fileprivate func createRange(from: Int64, to: Int64? = nil, total: Int64? = nil) -> String? {
        guard from >= 0, (to ?? 0) >= 0, (total ?? 1) >= 1 else {
            return total.flatMap({ "*/\($0)" })
        }
        let toString = to.flatMap(String.init) ?? ""
        let totalString = total.flatMap({ "/\($0)" }) ?? "/*"

        return "bytes=\(from)-\(toString)\(totalString)"
    }
    
    /// Returns `Content-Range` header value
    /// - Note: upperbound will be Int64.max in case of open ended Range
    public var contentRange: Range<Int64>? {
        // TODO: return PartialRangeFrom when possible
        get {
            guard let elements = self.storage[.contentMD5]?.first.flatMap({ self.dissectRange($0) }) else {
                return nil
            }
            let to = elements.to.flatMap({ $0 + 1 }) ?? Int64.max
            return elements.from..<to
        }
    }
    
    // Set `Content-Range` header
    public mutating func set(contentRange: Range<Int64>, size: Int64? = nil) {
        // TOCHECK: size >= contentRange.count
        let rangeStr = contentRange.upperBound == Int64.max ?
            createRange(from: contentRange.lowerBound, total: size) :
            createRange(from: contentRange.lowerBound, to: contentRange.upperBound - 1, total: size)
        self.storage[.contentRange] = rangeStr.flatMap { [$0] }
    }
    public mutating func set(contentRange: ClosedRange<Int64>, size: Int64? = nil) {
        // TOCHECK: size >= contentRange.count
        let rangeStr = contentRange.upperBound == Int64.max ?
            createRange(from: contentRange.lowerBound, total: size) :
            createRange(from: contentRange.lowerBound, to: contentRange.upperBound, total: size)
        self.storage[.contentRange] = rangeStr.flatMap { [$0] }
    }
    
    #if swift(>=4.0)
    /// Set half-open `Content-Range`
    public mutating func set(contentRange: PartialRangeFrom<Int64>) {
        let rangeStr = createRange(from: contentRange.lowerBound)
        self.storage[.contentRange] = rangeStr.flatMap { [$0] }
    }
    #endif
    
    /// `Content-Type` header value
    public var contentType: ContentType? {
        get {
            return self.storage[.contentType]?.first.flatMap { $0.components(separatedBy: ";").first.flatMap(ContentType.init(rawValue:)) }
        }
        set {
            if let charset = self.storage[.contentType]?.first.flatMap({ HTTPHeaders.parseParams($0)["charset"] }) {
                self.storage[.contentType] = newValue.flatMap { ["\($0.rawValue); charset=\(charset)"] }
            } else {
                self.storage[.contentType] = newValue.flatMap { [$0.rawValue] }
            }
        }
    }
    
    /// Extracted `charset` parameter in `Content-Type` header
    public var contentTypeCharset: String.Encoding? {
        get {
            return self.storage[.contentType]?.first.flatMap {
                if let charset = HTTPHeaders.parseParams($0)["charset"] {
                    return HTTPHeaders.charsetIANAToStringEncoding(charset)
                } else {
                    return nil
                }
            }
        }
        set {
            if let newValue = newValue {
                let ianaEncoding = HTTPHeaders.StringEncodingToIANA(newValue)
                if self.storage[.contentType] != nil {
                    self.storage[.contentType] = self.storage[.contentType]?.flatMap {
                        let type = $0.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "*"
                        return "\(type); charset=\(ianaEncoding))"
                    }
                } else {
                    self.storage[.contentType] = ["*; charset=\(ianaEncoding)"]
                }
                
            } else {
                self.storage[.contentType] = self.storage[.contentType]?.flatMap { ($0.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespacesAndNewlines)) }
            }
        }
    }
    
    /// `Date` header value
    public var date: Date? {
        get {
            return self.storage[.date]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            self.storage[.date] = newValue.flatMap { [$0.format(with: .http)] }
        }
    }
    
    /// `ETag` header value
    public var eTag: EntryTag? {
        get {
            return self.storage[.eTag]?.first.flatMap(EntryTag.init)
        }
        set {
            // TOCHECK: wildcard should be ignored
            self.storage[.eTag] = newValue.flatMap { [$0.description] }
        }
    }
    
    /// `Expires` header value
    public var expires: Date? {
        get {
            return self.storage[.expires]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            self.storage[.expires] = newValue.flatMap { [$0.format(with: .http)] }
        }
    }
    
    /// `Last-Modified` header value
    public var lastModified: Date? {
        get {
            return self.storage[.lastModified]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            self.storage[.lastModified] = newValue.flatMap { [$0.format(with: .http)] }
        }
    }
    
    /// `Location` header value
    public var location: URL? {
        get {
            return self.storage[.location]?.first.flatMap(URL.init(string:))
        }
        set {
            self.storage[.location] = newValue.flatMap { [$0.absoluteString] }
        }
    }
    
    /// `Pragma` header value
    public var pragma: Pragma? {
        get {
            return self.storage[.pragma]?.first.flatMap(Pragma.init)
        }
        set {
            self.storage[.pragma] = newValue.flatMap { [$0.rawValue] }
        }
    }
    
    // TODO: Implement var setCookie: [HTTPCookie]
    
    // TODO: Implement funcs set & add(setCookie: HTTPCookie)
    
    /// `Trailer` header value
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
    
    /// `Vary` header value
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
    fileprivate static func parseRFC5987(_ value: String) -> String {
        let components = value.components(separatedBy: "'")
        guard components.count >= 3 else {
            return value
        }
        let encoding = HTTPHeaders.charsetIANAToStringEncoding(components.first!)
        let string = components.dropFirst(2).joined(separator: "'")
        return string.removingPercentEscapes(encoding: encoding) ?? string
    }
    
    fileprivate static func parseParams(_ value: String, separator: String = ";") -> [String: String] {
        let rawParams: [String] = value.components(separatedBy: separator).dropFirst().flatMap { param in
            let result = param.trimmingCharacters(in: .whitespacesAndNewlines)
            return !result.isEmpty ? result : nil
        }
        var params: [String: String] = [:]
        for rawParam in rawParams {
            let arg = rawParam.components(separatedBy: "=")
            if let key = arg.first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                let value = arg.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                params[key] = value
            }
        }
        return params
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
            return HTTPHeaders.ianatable.filter({ return $0.value == charset }).first?.key ?? .isoLatin1
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
}

fileprivate extension String {
    // Similiar method is deprecated in Foundation, we implemented ours
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
