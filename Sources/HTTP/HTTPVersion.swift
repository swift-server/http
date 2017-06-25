// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

/// Version number of the HTTP Protocol
public struct HTTPVersion {
    /// Major version component.
    public private(set) var major: Int
    /// Minor version component.
    public private(set) var minor: Int

    /// Creates an HTTP version.
    public init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }
}

extension HTTPVersion : Hashable {

    public var hashValue: Int {
        return major ^ minor
    }

    public static func == (lhs: HTTPVersion, rhs: HTTPVersion) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public static func != (lhs: HTTPVersion, rhs: HTTPVersion) -> Bool {
        return lhs.hashValue != rhs.hashValue
    }
    
    public static func ~= (match: HTTPVersion, version: HTTPVersion) -> Bool {
        return match == version
    }
}

extension HTTPVersion : Comparable {
    
    public static func > (lhs: HTTPVersion, rhs: HTTPVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major > rhs.major
        } else {
            return lhs.minor > rhs.minor
        }
    }
    
    public static func >= (lhs: HTTPVersion, rhs: HTTPVersion) -> Bool {
        return lhs > rhs || lhs == rhs
    }
    
    public static func < (lhs: HTTPVersion, rhs: HTTPVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else {
            return lhs.minor < rhs.minor
        }
    }
    
    public static func <= (lhs: HTTPVersion, rhs: HTTPVersion) -> Bool {
        return lhs < rhs || lhs == rhs
    }

}

extension HTTPVersion : CustomStringConvertible {
    public var description: String {
        return "HTTP/" + major.description + "." + minor.description
    }
}
