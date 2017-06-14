// This source file is part of the Swift.org Server APIs open source project
//
// Copyright (c) 2017 Swift Server API project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
//

import Foundation

/// Version number of the HTTP Protocol
public typealias Version = (Int, Int)

/// Takes in a Request and an object to write to, and returns a function that handles reading the request body
public typealias WebApp = (Request, ResponseWriter) -> BodyProcessing

/// Class protocol containing the WebApp func. Using a class protocol to allow weak references for ARC
public protocol WebAppContaining: class {
    /// WebApp method
    func serve(req: Request, res: ResponseWriter ) -> BodyProcessing
}

/// Headers structure.
public struct Headers {
    var storage: [String:[String]]     /* lower cased keys */
    var original: [(String, String)]   /* original casing */
    let description: String
    
    public subscript(key: String) -> [String] {
        get {
            return storage[key.lowercased()] ?? []
        }
        mutating set {
            original = original.filter { $0.0 != key.lowercased() }
            storage[key.lowercased()]=nil
            for val in newValue {
                self.append(newHeader: (key, val))
            }
        }
    }
    
    func makeIterator() -> IndexingIterator<Array<(String, String)>> {
        return original.makeIterator()
    }
    
    public mutating func append(newHeader: (String, String)) {
        original.append(newHeader)
        let key = newHeader.0.lowercased()
        let val = newHeader.1
        
        var existing = storage[key] ?? []
        existing.append(val)
        storage[key] = existing
    }

    /// Create Header structure from an array of string pairs
    public init(_ headers: [(String, String)] = []) {
        original = headers
        description=""
        storage = [String:[String]]()
        makeIterator().forEach { (element: (String, String)) in
            let key = element.0.lowercased()
            let val = element.1
            
            var existing = storage[key] ?? []
            existing.append(val)
            storage[key] = existing
        }
    }
}

public enum Result<POSIXError, Void> {
    case success(())
    case failure(POSIXError)
    
    // MARK: Constructors
    /// Constructs a success wrapping a `closure`.
    public init(completion: ()) {
        self = .success(completion)
    }
    
    /// Constructs a failure wrapping an `POSIXError`.
    public init(error: POSIXError) {
        self = .failure(error)
    }
}
