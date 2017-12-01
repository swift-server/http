// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import XCTest

@testable import HTTP

class HeadersAccessorsTests: XCTestCase {
    func testRequestHeaders() {
        let headers: HTTPHeaders = [
            .accept: "text/html, application/xhtml+xml;q=0.5, text/xml;q=0.9, */*;q=0.8",
            .acceptCharset: "iso-8859-1;q=0.5, utf-8",
            .acceptEncoding: "br;q=1.0, gzip;q=0.8, *;q=0.1",
            .acceptLanguage: "ru-RU, ru;q=0.8, en-US;q=0.6, en;q=0.4",
            .authorization: "Basic YWxhZGRpbjpvcGVuc2VzYW1l", // aladdin:opensesame
            .cacheControl: "no-cache, no-store, must-revalidate",
            .contentLength: "200",
            .cookie: "PHPSESSID=298zf09hf012fh2; csrftoken=\"u32t4o3tb3gg43\"; _gat=1;",
            .host: "developer.cdn.mozilla.net",
            .ifMatch: "W/\"67ab43\", \"54ed21\", \"7892dd\"",
            .ifNoneMatch: "*",
            .ifModifiedSince: "Wed, 21 Oct 2015 07:28:00 GMT",
            .ifUnmodifiedSince: "Wed, 21 Oct 2015 07:28:00 GMT",
            .origin: "https://developer.mozilla.org",
            .range: "bytes=200-1000, 2000-6576, 19000-, -3",
            .referer: "https://developer.mozilla.org/en-US/docs/Web/JavaScript",
            .te: "trailers, deflate;q=0.5, gzip;q=0.0",
            .userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1",
            ]
        XCTAssertEqual(headers.accept, [.html, .xml, .all, .xhtml])
        XCTAssertEqual(headers.acceptCharset, [.utf8, .isoLatin1])
        XCTAssertEqual(headers.acceptEncoding, [.brotli, .gzip, .all])
        XCTAssertEqual(headers.acceptLanguage.flatMap({ $0.languageCode }), [
            "ru", "ru", "en", "en"])
        switch headers.authorization! {
        case .basic(user: let user, password: let passw):
            XCTAssertEqual(user, "aladdin")
            XCTAssertEqual(passw, "opensesame")
        default:
            XCTAssert(false)
        }
        XCTAssertEqual(headers.cacheControl, [.noCache, .noStore, .mustRevalidate])
        XCTAssertEqual(headers.contentLength, 200)
        XCTAssertEqual(headers.cookieDictionary["csrftoken"], "u32t4o3tb3gg43")
        XCTAssertEqual(headers.host?.host, "developer.cdn.mozilla.net")
        XCTAssertEqual(headers.ifMatch, [.weak("67ab43"), .strong("54ed21"), .strong("7892dd")])
        XCTAssertEqual(headers.ifNoneMatch, [.wildcard])
        XCTAssertEqual(headers.ifModifiedSince?.timeIntervalSinceReferenceDate, 467105280)
        XCTAssertEqual(headers.ifUnmodifiedSince?.timeIntervalSinceReferenceDate, 467105280)
        XCTAssertEqual(headers.origin, URL(string: "https://developer.mozilla.org"))
        XCTAssertEqual(headers.rangeType, .bytes)
        XCTAssertEqual(headers.range, [200..<1001, 2000..<6577, 19000..<Int64.max, -3..<(-2)])
        XCTAssertEqual(headers.referer?.path, "/en-US/docs/Web/JavaScript")
        XCTAssertEqual(headers.te, [.trailers, .deflate])
        let browser = headers.clientBrowser
        XCTAssertEqual(browser?.name, "Safari")
        XCTAssertEqual(browser?.version, 10.0)
        XCTAssertEqual(headers.clientOperatingSystem, "iOS 10.3.1")
    }
    
    func testResponseHeadersGetter() {
        let headers: HTTPHeaders = [
            .acceptRanges: "bytes",
            .age: "24",
            .allow: "GET, POST, HEAD",
            .cacheControl: "public, max-age=31536000",
            .connection: "keep-alive",
            .contentDisposition: "attachment; filename=\"filename.jpg\"",
            .contentEncoding: "br",
            .contentLanguage: "de-DE",
            .contentLocation: "https://developer.mozilla.org/en-US/docs/Web/JavaScript",
            .contentMD5: "Q2hlY2sgSW50ZWdyaXR5IQ==",
            .contentRange: "bytes 200-1000/67589",
            .contentType: "text/html; charset=utf-8",
            .date: "Wed, 21 Oct 2015 07:28:00 GMT",
            .eTag: "W/\"0815\"",
            .expires: "Wed, 21 Oct 2015 07:28:00 GMT",
            .lastModified: "Wed, 21 Oct 2015 07:28:00 GMT",
            .link: "</feed>; rel=\"alternate\"",
            .location: "https://developer.mozilla.org/",
            .pragma: "no-cache",
            .trailer: "Expires",
            .transferEncoding: "gzip, chunked",
            .vary: "User-Agent",
            .wwwAuthenticate: "Basic realm=\"Access to the staging site\", charset=\"UTF-8\"",
            ]
        XCTAssertEqual(headers.acceptRanges, .bytes)
        XCTAssertEqual(headers.age, 24.0)
        //XCTAssertTrue(headers.allow.contains(.head))
        XCTAssertEqual(headers.cacheControl, [.`public`, .maxAge(31536000)])
        XCTAssertEqual(headers.connection, [.keepAlive])
        XCTAssertEqual(headers.contentDisposition?.type, .attachment)
        XCTAssertEqual(headers.contentDisposition?.filename, "filename.jpg")
        XCTAssertEqual(headers.contentEncoding, .brotli)
        XCTAssertEqual(headers.contentLanguage?.languageCode, "de")
        XCTAssertEqual(headers.contentLocation?.scheme, "https")
        XCTAssertEqual(headers.contentMD5?.count, 16)
        XCTAssertEqual(headers.contentRange, 200..<1001)
        XCTAssertEqual(headers.contentType?.mediaType, .html)
        XCTAssertEqual(headers.contentType?.charset, .utf8)
        XCTAssertEqual(headers.date?.timeIntervalSinceReferenceDate, 467105280)
        XCTAssertEqual(headers.eTag, .weak("0815"))
        let date = Date(timeIntervalSinceReferenceDate: 467105280)
        XCTAssertEqual(headers.expires, date)
        XCTAssertEqual(headers.lastModified, date)
        XCTAssertEqual(headers.link.first?.url, URL(string: "/feed"))
        XCTAssertEqual(headers.link.first?.relationType, .alternate)
        XCTAssertEqual(headers.pragma, .noCache)
        XCTAssertEqual(headers.trailer, [.expires])
        XCTAssertEqual(headers.transferEncoding, [.gzip, .chunked])
        XCTAssertEqual(headers.vary, [.userAgent])
        XCTAssertEqual(headers.wwwAuthenticate?.type, .basic)
        XCTAssertEqual(headers.wwwAuthenticate?.realm, "Access to the staging site")
        XCTAssertEqual(headers.wwwAuthenticate?.charset, .utf8)
    }
    
    func testResponseHeadersWrite() {
        /*
         These accessors set underlying string storage directly, thus there is a converting
         forth back from typed header to raw string.
         If we change underlying storage architecture anytime, we must rewrite this method.
        */
        var headers = HTTPHeaders()
        headers.acceptRanges = .none
        XCTAssertEqual(headers.acceptRanges, .none)
        headers.age = 2000.25
        XCTAssertEqual(headers.age, 2000)
        headers.allow = [.get, .post, .head]
        //XCTAssertEqual(headers[.allow], "GET, POST, HEAD")
        headers.cacheControl = [.maxAge(2000.2)]
        XCTAssertEqual(headers.cacheControl, [.maxAge(2000)])
        headers.connection = [.keepAlive]
        XCTAssertEqual(headers.connection, [.keepAlive])
        headers.contentDisposition = .attachment(fileName: "file√utf.çav")
        XCTAssertEqual(headers.contentDisposition?.type, .attachment)
        XCTAssertEqual(headers.contentDisposition?.filename, "file√utf.çav")
        headers.contentEncoding = .brotli
        XCTAssertEqual(headers.contentEncoding, .brotli)
        headers.contentLanguage = Locale(identifier: "de_DE")
        XCTAssertEqual(headers.contentLanguage?.languageCode, "de")
        headers.contentLocation = URL(string: "https://developer.mozilla.org/en-US/docs/Web/JavaScript")
        XCTAssertEqual(headers.contentLocation?.scheme, "https")
        headers.set(contentRange: 200..<1001, size: 10000)
        XCTAssertEqual(headers.contentRange, 200..<1001)
        XCTAssertEqual(headers.contentRangeType, .bytes)
        headers.contentType = HTTPHeaders.ContentType(type: .html, charset: .utf8)
        XCTAssertEqual(headers.contentType?.mediaType, .html)
        XCTAssertEqual(headers.contentType?.charset, .utf8)
        headers.date = Date(timeIntervalSinceReferenceDate: 467105280.1)
        XCTAssertEqual(headers.date?.timeIntervalSinceReferenceDate, 467105280)
        headers.eTag = .weak("0815")
        XCTAssertEqual(headers.eTag, .weak("0815"))
        headers.expires = Date(timeIntervalSinceReferenceDate: 467105280.1)
        XCTAssertEqual(headers.expires?.timeIntervalSinceReferenceDate, 467105280)
        headers.lastModified  = Date(timeIntervalSinceReferenceDate: 467105280.1)
        XCTAssertEqual(headers.expires?.timeIntervalSinceReferenceDate, 467105280)
        headers.link = [HTTPHeaders.Link(url: URL(string: "/relative/path")!, relation: .prev)]
        headers.pragma = .noCache
        XCTAssertEqual(headers.pragma, .noCache)
        headers.transferEncoding = [.gzip, .chunked]
        XCTAssertEqual(headers.transferEncoding, [.gzip, .chunked])
        headers.vary = [.userAgent]
        XCTAssertEqual(headers.vary, [.userAgent])
        headers.wwwAuthenticate = HTTPHeaders.Challenge.basic(realm: "Access to the staging site", charset: .utf8)
        XCTAssertEqual(headers.wwwAuthenticate?.type, .basic)
        XCTAssertEqual(headers.wwwAuthenticate?.realm, "Access to the staging site")
        XCTAssertEqual(headers.wwwAuthenticate?.charset, .utf8)
        
    }
    
    static var allTests = [
        ("testResponseHeaders", testRequestHeaders),
        ("testResponseHeaders", testRequestHeaders),
        ]
}

