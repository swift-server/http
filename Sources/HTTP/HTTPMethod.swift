// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

/// HTTP method structure
public struct HTTPMethod {
    /// HTTP method
    public let method: String

    /// Creates an HTTP method
    public init(_ method: String) {
        self.method = method.uppercased()
    }
}

/// HTTP method constants
extension HTTPMethod {
    /// DELETE method.
    public static let delete = HTTPMethod("DELETE")
    /// GET method.
    public static let get = HTTPMethod("GET")
    /// HEAD method.
    public static let head = HTTPMethod("HEAD")
    /// POST method.
    public static let post = HTTPMethod("POST")
    /// PUT method.
    public static let put = HTTPMethod("PUT")
    /// CONNECT method.
    public static let connect = HTTPMethod("CONNECT")
    /// OPTIONS method.
    public static let options = HTTPMethod("OPTIONS")
    /// TRACE method.
    public static let trace = HTTPMethod("TRACE")
    /// COPY method.
    public static let copy = HTTPMethod("COPY")
    /// LOCK method.
    public static let lock = HTTPMethod("LOCK")
    /// MKCOL method.
    public static let mkol = HTTPMethod("MKCOL")
    /// MOVE method.
    public static let move = HTTPMethod("MOVE")
    /// PROPFIND method.
    public static let propfind = HTTPMethod("PROPFIND")
    /// PROPPATCH method.
    public static let proppatch = HTTPMethod("PROPPATCH")
    /// SEARCH method.
    public static let search = HTTPMethod("SEARCH")
    /// UNLOCK method.
    public static let unlock = HTTPMethod("UNLOCK")
    /// BIND method.
    public static let bind = HTTPMethod("BIND")
    /// REBIND method.
    public static let rebind = HTTPMethod("REBIND")
    /// UNBIND method.
    public static let unbind = HTTPMethod("UNBIND")
    /// ACL method.
    public static let acl = HTTPMethod("ACL")
    /// REPORT method.
    public static let report = HTTPMethod("REPORT")
    /// MKACTIVITY method.
    public static let mkactivity = HTTPMethod("MKACTIVITY")
    /// CHECKOUT method.
    public static let checkout = HTTPMethod("CHECKOUT")
    /// MERGE method.
    public static let merge = HTTPMethod("MERGE")
    /// MSEARCH method.
    public static let msearch = HTTPMethod("MSEARCH")
    /// NOTIFY method.
    public static let notify = HTTPMethod("NOTIFY")
    /// SUBSCRIBE method.
    public static let subscribe = HTTPMethod("SUBSCRIBE")
    /// UNSUBSCRIBE method.
    public static let unsubscribe = HTTPMethod("UNSUBSCRIBE")
    /// PATCH method.
    public static let patch = HTTPMethod("PATCH")
    /// PURGE method.
    public static let purge = HTTPMethod("PURGE")
    /// MKCALENDAR method.
    public static let mkcalendar = HTTPMethod("MKCALENDAR")
    /// LINK method.
    public static let link = HTTPMethod("LINK")
    /// UNLINK method.
    public static let unlink = HTTPMethod("UNLINK")
}

extension HTTPMethod : Hashable {
    public var hashValue: Int {
        return method.hashValue
    }

    /// :nodoc:
    public static func == (lhs: HTTPMethod, rhs: HTTPMethod) -> Bool {
        return lhs.method == rhs.method
    }

    /// :nodoc:
    public static func ~= (match: HTTPMethod, version: HTTPMethod) -> Bool {
        return match == version
    }
}

extension HTTPMethod : ExpressibleByStringLiteral {
    /// :nodoc:
    public init(stringLiteral: String) {
        self.init(stringLiteral)
    }

    /// :nodoc:
    public init(unicodeScalarLiteral: String) {
        self.init(unicodeScalarLiteral)
    }

    /// :nodoc:
    public init(extendedGraphemeClusterLiteral: String) {
        self.init(extendedGraphemeClusterLiteral)
    }
}

extension HTTPMethod : CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        return method
    }
}
