import Foundation

public indirect enum Bencode: Hashable, Sendable {
    
    case integer(Int)
    
    case string(String)
    
    case list([Self])
    
    case dictionary([String: Self])
    
}

extension Bencode: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .integer(value)
    }
}

extension Bencode: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Bencode: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Self...) {
        self = .list(elements)
    }
}

extension Bencode: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Self)...) {
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
    
    public func write<D: MutableDataProtocol>(to data: inout D) {
        
        switch self {
            
        case .integer(let integer):
            
            data.append(ASCII.i.rawValue)
            
            data.append(contentsOf: String(integer).utf8)
            
            data.append(ASCII.e.rawValue)
            
        case .string(let string):
            
            data.append(contentsOf: String(string.utf8.count).utf8)
            
            data.append(ASCII.colon.rawValue)
            
            data.append(contentsOf: string.utf8)
            
        case .list(let list):
            
            data.append(ASCII.l.rawValue)
            
            for child in list {
                child.write(to: &data)
            }
            
            data.append(ASCII.e.rawValue)
            
        case .dictionary(let dictionary):
            
            data.append(ASCII.d.rawValue)
            
            for (key, value) in dictionary.sorted(by: { $0.key < $1.key }) {
                Self.string(key).write(to: &data)
                value.write(to: &data)
            }
            
            data.append(ASCII.e.rawValue)
            
        }
        
    }
    
    public func data() -> Data {
        
        var result: Data = .init()
        
        write(to: &result)
        
        return result
        
    }
    
}


extension Bencode {
    
    public enum DecodingError: Foundation.LocalizedError {
        
        case invalidFormat(index: Data.Index)
        
        case integerOverflow(index: Data.Index)
        
        public var errorDescription: String? {
            switch self {
            case .invalidFormat(let index):
                return "invalidFormat, error at \(index)"
            case .integerOverflow(let index):
                return "integerOverflow at \(index)"
            }
            
        }
        
    }
    
    
}

