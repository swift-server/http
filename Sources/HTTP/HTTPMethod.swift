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
    public static let delete = HTTPMethod("DELETE")
    public static let get = HTTPMethod("GET")
    public static let head = HTTPMethod("HEAD")
    public static let post = HTTPMethod("POST")
    public static let put = HTTPMethod("PUT")
    public static let connect = HTTPMethod("CONNECT")
    public static let options = HTTPMethod("OPTIONS")
    public static let trace = HTTPMethod("TRACE")
    public static let copy = HTTPMethod("COPY")
    public static let lock = HTTPMethod("LOCK")
    public static let mkol = HTTPMethod("MKCOL")
    public static let move = HTTPMethod("MOVE")
    public static let propfind = HTTPMethod("PROPFIND")
    public static let proppatch = HTTPMethod("PROPPATCH")
    public static let search = HTTPMethod("SEARCH")
    public static let unlock = HTTPMethod("UNLOCK")
    public static let bind = HTTPMethod("BIND")
    public static let rebind = HTTPMethod("REBIND")
    public static let unbind = HTTPMethod("UNBIND")
    public static let acl = HTTPMethod("ACL")
    public static let report = HTTPMethod("REPORT")
    public static let mkactivity = HTTPMethod("MKACTIVITY")
    public static let checkout = HTTPMethod("CHECKOUT")
    public static let merge = HTTPMethod("MERGE")
    public static let msearch = HTTPMethod("MSEARCH")
    public static let notify = HTTPMethod("NOTIFY")
    public static let subscribe = HTTPMethod("SUBSCRIBE")
    public static let unsubscribe = HTTPMethod("UNSUBSCRIBE")
    public static let patch = HTTPMethod("PATCH")
    public static let purge = HTTPMethod("PURGE")
    public static let mkcalendar = HTTPMethod("MKCALENDAR")
    public static let link = HTTPMethod("LINK")
    public static let unlink = HTTPMethod("UNLINK")
}

extension HTTPMethod : Hashable {
    
    public var hashValue: Int {
        return method.hashValue
    }
    
    public static func == (lhs: HTTPMethod, rhs: HTTPMethod) -> Bool {
        return lhs.method == rhs.method
    }
    
    public static func ~= (match: HTTPMethod, version: HTTPMethod) -> Bool {
        return match == version
    }
}

extension HTTPMethod : ExpressibleByStringLiteral {
    public init(stringLiteral: String) {
        self.init(stringLiteral)
    }
    
    public init(unicodeScalarLiteral: String) {
        self.init(unicodeScalarLiteral)
    }
    
    public init(extendedGraphemeClusterLiteral: String) {
        self.init(extendedGraphemeClusterLiteral)
    }
}

extension HTTPMethod : CustomStringConvertible {
    public var description: String {
        return method
    }
}
