// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation

extension HTTPHeaders {
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
        return cookieDictionary.flatMap {
            // path should be set otherwise it will fail!
            return HTTPCookie(properties: [.name : $0.key, .value: $0.value, .path: "/"])
        }
    }
    
    // `Cookie` header value. An empty array means no value is set in header.
    public var cookieDictionary: [String: String] {
        // Regarding `Cookie2` is obsolete, should we have to integrate it into values?
        let pairs = (self.storage[.cookie]?.joined(separator: ";")).flatMap({
            HTTPHeaders.parseParams($0, separator: ";", removeQuotation: true)
        }) ?? [:]
        return pairs
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
            return self.storage[.pragma]?.first.flatMap(Pragma.init(rawValue:))
        }
        set {
            self.storage[.pragma] = newValue.flatMap { [$0.rawValue] }
        }
    }
    
    /// `Set-Cookie` header values. An empty array means no value is set in header.
    public var setCookie: [HTTPCookie] {
        return self.storage[.setCookie]?.flatMap({ HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": $0], for: URL(string: "/")!) }) ?? []
    }
    
    /// Appends a cookie to `Set-Cookie` header values.
    /// - Parameter cookie: The cookie object to be appended.
    public mutating func add(setCookie cookie: HTTPCookie) {
        let maximumAge = (cookie.properties?[.maximumAge] as? String).flatMap(TimeInterval.init)
        let comment = cookie.properties?[.comment] as? String
        self.add(setCookie: cookie.name, value: cookie.value, path: cookie.path,
                 domain: cookie.domain, expiresDate: cookie.expiresDate, maximumAge: maximumAge,
                 comment: comment, isSecure: cookie.isSecure, isHTTPOnly: cookie.isHTTPOnly)
    }
    
    /// Appends a cookie to `Set-Cookie` header values.
    /// - Parameter name: Name of cookie.
    /// - Parameter value: Value of cookie. Can be empty string of cookie has no value.
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
        
        var cookieString = name
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
    
    /// `Transfer-Encoding` header values. An empty array means no value is set in header.
    ///
    /// Transfer-Encoding is a hop-by-hop header, that is applying to a message between two nodes,
    /// not to a resource itself.
    public var transferEncoding: [Encoding] {
        get {
            return self.storage[.transferEncoding]?.flatMap({ (value) -> [String] in
                return value.components(separatedBy: ",")
            }).map(Encoding.init(rawValue:)) ?? []
        }
        set {
            if !newValue.isEmpty {
                self.storage[.transferEncoding] = newValue.flatMap { $0.rawValue }
            } else {
                self.storage[.transferEncoding] = nil
            }
        }
    }
    
    /// `Link` header values. An empty array means no value is set in header.
    public var link: [HTTPHeaders.Link] {
        get {
            return self.storage[.link]?.flatMap({ (value) -> [String] in
                return value.components(separatedBy: ",")
            }).flatMap(Link.init(rawValue:)) ?? []
        }
        set {
            if !newValue.isEmpty {
                self.storage[.link] = newValue.flatMap { $0.rawValue }
            } else {
                self.storage[.link] = nil
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
