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
            let val = keyVal.dropFirst().joined(separator: "=")
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
                self = .privateWithField(field: val.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
            case "no-cache":
                self = .noCacheWithField(field: val.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
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
    
    /// Defines HTTP Authentication challenge method required to access
    public enum Challenge: CustomStringConvertible {
        /// Basic method for authentication
        case basic
        /// Digest method for authentication
        case digest
        /// OAuth 1.0 method for authentication (OAuth)
        case oAuth1
        /// OAuth 2.0 method for authentication (Bearer)
        case oAuth2
        /// Custom authentication method
        case custom(String)
        
        public var description: String {
            switch self {
            case .basic: return "Basic"
            case .digest: return "Digest"
            case .oAuth1: return "OAuth"
            case .oAuth2: return "Bearer"
            case .custom(let type): return type
            }
        }
    }
    
    public enum EntryTag: CustomStringConvertible, Equatable, Hashable {
        case strong(String)
        case weak(String)
        case wildcard
        
        public init(_ rawValue: String) {
            // Check begins with W/" in case-insensitive manner to indicate is weak or not
            if rawValue.range(of: "W/\"", options: [.anchored, .caseInsensitive]) != nil {
                let linted = rawValue.replacingOccurrences(of: "W/\"", with: "", options: [.anchored, .caseInsensitive]).trimmingCharacters(in: CharacterSet(charactersIn: " \""))
                self = .weak(linted)
            }
            // Check value is wildcard
            if rawValue == "*" {
                self = .wildcard
            }
            // Value is strong
            let linted = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: " \""))
            self = .strong(linted)
        }
        
        public var description: String {
            switch self {
            case .strong(let etag):
                let lintedEtag = etag.trimmingCharacters(in: CharacterSet(charactersIn: " \""))
                return "\"\(lintedEtag)\""
            case .weak(let etag):
                let lintedEtag = etag.replacingOccurrences(of: "W/\"", with: "", options: [.anchored, .caseInsensitive]).trimmingCharacters(in: CharacterSet(charactersIn: " \""))
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
        /// Compress body data using zlib method
        case compress
        /// Compress body data using deflate method
        case deflate
        /// Compress body data using gzip method
        case gzip
        /// Compress body data using brotli method
        case brotli
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
    
    fileprivate func parseParams(_ value: String) -> [String: String] {
        let rawParams: [String] = value.components(separatedBy: ";").dropFirst().flatMap { param in
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
    
    // Request Headers
    
    /// Fetch `Accept` header values, sorted by `q` parameter
    public var accept: [ContentType] {
        get {
            let values: [String]? = self.storage[.accept]?.sorted {
                let q0 = parseParams($0)["q"].flatMap(Double.init) ?? 1
                let q1 = parseParams($1)["q"].flatMap(Double.init) ?? 1
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
        let charsetString = StringEncodingToIANA(acceptCharset)
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
            self.storage[.acceptDatetime] = newValue.flatMap { [$0.format(with: .rfc1123)] }
        }
    }
    
    /// Fetch `Accept-Encoding` header values, sorted by `q` parameter
    public var acceptEncoding: [Encoding] {
        get {
            let values: [String]? = self.storage[.acceptEncoding]?.sorted {
                let q0 = parseParams($0)["q"].flatMap(Double.init) ?? 1
                let q1 = parseParams($1)["q"].flatMap(Double.init) ?? 1
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
    
    // TODO: Implement var authentication
    
    // TODO: Implement var cookie: [HTTPCookie]
    
    /// `If-Match` header etag value
    public var ifMatch: [EntryTag] {
        get {
            return (self.storage[.ifMatch] ?? []).map(EntryTag.init)
        }
        set {
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
            self.storage[.ifModifiedSince] = newValue.flatMap { [$0.format(with: .rfc1123)] }
        }
    }
    
    /// `If-Unmodified-Since` header value
    public var ifUnmodifiedSince: Date? {
        get {
            return self.storage[.ifUnmodifiedSince]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            self.storage[.ifUnmodifiedSince] = newValue.flatMap { [$0.format(with: .rfc1123)] }
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
    
    // TODO: Parse User-Agent for Browser and Operating system
    
    // Response Headers
    
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
            self.storage[.age] = newValue.flatMap { [String($0)] }
        }
    }
    
    /// `Allow` header value
    public var allow: [HTTPMethod]? {
        get {
            return self.storage[.allow]?.map { HTTPMethod($0) }
        }
        set {
            if let value = newValue {
                self.storage[.allow] = value.map { $0.method }
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
        guard from >= 0, (to ?? 0) >= 0, (total ?? 1) >= 1 else { return nil }
        let toString = to.flatMap(String.init) ?? ""
        let totalString = total.flatMap({ "/\($0)" }) ?? ""
        
        return "bytes=\(from)-\(toString)\(totalString)"
    }
    
    /// Returns `Content-Range` header value
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
    public mutating func set(contentRange: Range<Int64>) {
        let rangeStr = contentRange.upperBound == Int64.max ?
            createRange(from: contentRange.lowerBound) :
            createRange(from: contentRange.lowerBound, to: contentRange.upperBound - 1)
        self.storage[.contentRange] = rangeStr.flatMap { [$0] }
    }
    public mutating func set(contentRange: ClosedRange<Int64>) {
        let rangeStr = contentRange.upperBound == Int64.max ?
            createRange(from: contentRange.lowerBound) :
            createRange(from: contentRange.lowerBound, to: contentRange.upperBound)
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
            if let charset = self.storage[.contentType]?.first.flatMap({ parseParams($0)["charset"] }) {
                self.storage[.contentType] = newValue.flatMap { ["\($0.rawValue); charset=\(charset)"] }
            } else {
                self.storage[.contentType] = newValue.flatMap { [$0.rawValue] }
            }
        }
    }
    
    #if os(macOS) || os(iOS) || os(tvOS)
    #else
    static private let ianatable: [String.Encoding: String] = [.ascii: "us-ascii", .nextstep: "x-nextstep",
                                            .japaneseEUC: "euc-jp", .utf8: "utf-8", .isoLatin1: "iso-8859-1",
                                            .symbol: "x-mac-symbol", .shiftJIS: "cp932", .isoLatin2: "iso-8859-2",
                                            .windowsCP1251: "windows-1251", .windowsCP1252: "windows-1252",
                                            .windowsCP1253: "windows-1253", .windowsCP1254: "windows-1254",
                                            .windowsCP1250: "windows-1250", .iso2022JP: "iso-2022-jp", .macOSRoman: "macintosh",
                                            .utf16: "utf-16", .utf16BigEndian: "utf-16be", .utf16LittleEndian: "utf-16le",
                                            .utf32: "utf-32", .utf32BigEndian: "utf-32be", .utf32LittleEndian: "utf-32le"]
    #endif
    
    private func charsetIANAToStringEncoding(_ charset: String) -> String.Encoding {
        #if os(macOS) || os(iOS) || os(tvOS)
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
        #else
        // CFStringConvertIANACharSetNameToEncoding is not exposed in SwiftFoundation!
        // We use this as workaround until SwiftFoundation got fixed
            let charset = charset.lowercased()
            return HTTPHeaders.ianatable.filter({ return $0.value == charset }).first?.key ?? .utf8
        #endif
    }
    
    private func StringEncodingToIANA(_ encoding: String.Encoding) -> String {
        
        #if os(macOS) || os(iOS) || os(tvOS)
        return (CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)) as String?) ?? "utf-8"
        #else
        // CFStringConvertEncodingToIANACharSetName is not exposed in SwiftFoundation!
        // We use this as workaround until SwiftFoundation got fixed
        return HTTPHeaders.ianatable[encoding] ?? "utf-8"
        #endif
    }
    
    /// Extracted `charset` parameter in `Content-Type` header
    public var contentCharset: String.Encoding? {
        get {
            return self.storage[.contentType]?.first.flatMap {
                if let charset = parseParams($0)["charset"] {
                    return charsetIANAToStringEncoding(charset)
                } else {
                    return nil
                }
            }
        }
        set {
            if let newValue = newValue {
                let ianaEncoding = StringEncodingToIANA(newValue)
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
            self.storage[.date] = newValue.flatMap { [$0.format(with: .rfc1123)] }
        }
    }
    
    /// `ETag` header value
    public var eTag: EntryTag? {
        get {
            return self.storage[.eTag]?.first.flatMap(EntryTag.init)
        }
        set {
            self.storage[.eTag] = newValue.flatMap { [$0.description] }
        }
    }
    
    /// `Expires` header value
    public var expires: Date? {
        get {
            return self.storage[.expires]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            self.storage[.expires] = newValue.flatMap { [$0.format(with: .rfc1123)] }
        }
    }
    
    /// `Last-Modified` header value
    public var lastModified: Date? {
        get {
            return self.storage[.lastModified]?.first.flatMap(Date.init(rfcString:))
        }
        set {
            self.storage[.lastModified] = newValue.flatMap { [$0.format(with: .rfc1123)] }
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
    
    // TODO: Implement func add(setCookie: HTTPCookie)
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
    private static let defaultTImezone = TimeZone(identifier: "UTC")
    
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
        fm.timeZone = timeZone ?? Date.defaultTImezone
        fm.locale = locale ?? Date.defaultLocale
        return fm.string(from: self)
    }
}
