// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

public enum HTTPVersion {
    case v1_0
    case v1_1

    init?(major: Int, minor: Int) {
        if major == 1 && minor == 0 {
            self = .v1_0
        } else if major == 1 && minor == 1 {
            self = .v1_1
        } else {
            return nil
        }
    }
}

extension HTTPVersion {
    var major: Int {
        switch self {
        case .v1_0:
            return 1
        case .v1_1:
            return 1
        }
    }

    var minor: Int {
        switch self {
        case .v1_0:
            return 0
        case .v1_1:
            return 1
        }
    }
}

extension HTTPVersion: Hashable {
    public var hashValue: Int {
        return self.major << 8 | self.minor
    }
}

extension HTTPVersion : Comparable {
    /// :nodoc:
    public static func < (lhs: HTTPVersion, rhs: HTTPVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else {
            return lhs.minor < rhs.minor
        }
    }
}

extension HTTPVersion : CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        return "HTTP/\(self.major).\(self.minor)"
    }
}
