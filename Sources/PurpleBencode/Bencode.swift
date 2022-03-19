@preconcurrency
import Foundation

public indirect enum Bencode: Hashable, Sendable {
    
    case integer(Int)
    
    case data(Data)
    
    case list([Self])
    
    case dictionary([Data: Self])
    
    
    /// Create `Bencode.data` from string.
    ///
    /// - Returns: nil when string can't be converted to UTF-8 data.
    public static func string(_ string: String) -> Self? {
        string.data(using: .utf8).map { .data($0) }
    }
    
    /// Create `Bencode.dictionary` from dictionary with `String` keys.
    ///
    /// - Returns: nil when a key in dictionary can't be converted to UTF-8 data.
    public static func dictionaryFromStringKey(_ dictionary: [String: Self]) -> Self? {
        
        var result: [Data: Self] = [:]
        
        result.reserveCapacity(dictionary.count)
        
        for (key, value) in dictionary {
            
            guard let data = key.data(using: .utf8) else {
                return nil
            }
            
            result[data] = value
            
        }
        
        return .dictionary(result)
        
    }
    
}


extension Bencode: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .integer(value)
    }
}

extension Bencode: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .data(value.data(using: .utf8)!)
    }
}

extension Bencode: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Self...) {
        self = .list(elements)
    }
}

extension Bencode: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (Data, Self)...) {
        self = .dictionary(.init(uniqueKeysWithValues: elements))
    }
    
}

extension Bencode {
    
    /// Initialize bencode from data
    ///
    /// - Throws: ``DecodingError``
    public init(data: Data) throws {
        var parser = Parser(data: data)
        self = try parser.parse()
    }
    
}


extension Bencode {
    
    /// - Throws: ``EncodingError``
    public func write<D: MutableDataProtocol>(to data: inout D) throws {
        
        switch self {
            
        case .integer(let integer):
            
            data.append(ASCII.i.rawValue)
            
            data.append(contentsOf: String(integer).utf8)
            
            data.append(ASCII.e.rawValue)
            
        case .data(let dataValue):
            
            data.append(contentsOf: String(dataValue.count).utf8)
            
            data.append(ASCII.colon.rawValue)
            
            data.append(contentsOf: dataValue)
            
        case .list(let list):
            
            data.append(ASCII.l.rawValue)
            
            for child in list {
                try child.write(to: &data)
            }
            
            data.append(ASCII.e.rawValue)
            
        case .dictionary(let dictionary):
            
            data.append(ASCII.d.rawValue)
            
            let sortedKeys = try dictionary.keys.sorted(by: {
                
                guard let a = String(data: $0, encoding: .utf8) else {
                    throw EncodingError.failedToConvertKeyDataToSring($0)
                }
                
                guard let b = String(data: $1, encoding: .utf8) else {
                    throw EncodingError.failedToConvertKeyDataToSring($1)
                }
                
                return a < b
                
            })
            
            for key in sortedKeys {
                
                let value = dictionary[key]!
                
                try Self.data(key).write(to: &data)
                
                try value.write(to: &data)
                
            }
            
            data.append(ASCII.e.rawValue)
            
        }
        
    }
    
    /// - Throws: ``EncodingError``
    public func data() throws -> Data {
        
        var result: Data = .init()
        
        try write(to: &result)
        
        return result
        
    }
    
}


extension Bencode {
    
    public enum EncodingError: Foundation.LocalizedError {
        
        case failedToConvertKeyDataToSring(Data)
        
        public var errorDescription: String? {
            
            switch self {
                
            case .failedToConvertKeyDataToSring(let data):
                return "Failed to convert key data to string (data: \(data))"
            }
            
        }
        
    }
    
    public enum DecodingError: Foundation.LocalizedError {
        
        case invalidFormat(index: Data.Index)
        
        case integerOverflow(index: Data.Index)
        
        public var errorDescription: String? {
            switch self {
            case .invalidFormat(let index):
                return "Invalid format, error at \(index)"
            case .integerOverflow(let index):
                return "Integer overflow at \(index)"
            }
            
        }
        
    }
    
    
}

