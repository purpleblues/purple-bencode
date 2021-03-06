import Foundation

extension Bencode {
    
    struct Parser {
        
        private let data: Data
        
        private var index: Data.Index
        
        init(data: Data) {
            self.data = data
            self.index = data.startIndex
        }
        
    }
    
}


extension Bencode.Parser {
    
    typealias Error = Bencode.DecodingError
    
    mutating func parse() throws -> Bencode {
        
        try parseValue()
        
    }
    
}


private extension Bencode.Parser {
    
    func checkIndex() throws {
        
        guard index < data.endIndex else {
            throw Error.invalidFormat(index: index)
        }
        
    }
    
    mutating func parseValue() throws -> Bencode {
        
        try checkIndex()
        
        switch data[index] {
        case ASCII.i.rawValue:
            
            index += 1
            
            let value = try parseInteger()
            
            try parse(.e)
            
            return .integer(value)
            
        case ASCII._0.rawValue...ASCII._9.rawValue:
            
            return try .data(parseDataWithCount())
            
        case ASCII.l.rawValue:
            
            index += 1
            
            var result: [Bencode] = []
            
            while true {
                
                try result.append(parseValue())
                
                try checkIndex()
                
                if data[index] == ASCII.e.rawValue {
                    index += 1
                    break
                }
                
            }
            
            return .list(result)
            
        case ASCII.d.rawValue:
            
            index += 1
            
            var result: [Data: Bencode] = [:]
            
            while true {
                
                let key = try parseDataWithCount()
                
                let value = try parseValue()
                
                result[key] = value
                
                try checkIndex()
                
                if data[index] == ASCII.e.rawValue {
                    index += 1
                    break
                }
                
            }
            
            return .dictionary(result)
            
        default:
            throw Error.invalidFormat(index: index)
        }
        
    }
    
    mutating func parseDataWithCount() throws -> Data {
        
        let count = try parseNonNegativeInteger()
        
        try parse(.colon)
        
        return try parseData(forCount: count)
        
    }
    
    mutating func parseData(forCount count: Int) throws -> Data {
        
        guard index + count <= data.endIndex else {
            throw Error.invalidFormat(index: index)
        }
        
        let result = data.subdata(in: index ..< index + count)
        
        index += count
        
        return result
        
    }
    
    mutating func parse(_ ascii: ASCII) throws {
        
        try checkIndex()
        
        guard data[index] == ascii.rawValue else {
            throw Error.invalidFormat(index: index)
        }
        
        index += 1
        
    }
    
    mutating func parseNonNegativeInteger() throws -> Int {
        
        var result: Int = 0
        
        while true {
            
            try checkIndex()
            
            let value = data[index]
            
            switch value {
            case ASCII._0.rawValue...ASCII._9.rawValue:
                
                var (partialValue, overflow) = result.multipliedReportingOverflow(by: 10)
                
                guard !overflow else {
                    throw Error.integerOverflow(index: index)
                }
                
                result = partialValue
                
                (partialValue, overflow) = result.addingReportingOverflow(.init(value - ASCII._0.rawValue))
                
                guard !overflow else {
                    throw Error.integerOverflow(index: index)
                }
                
                result = partialValue
                
                index += 1
                
            default:
                return result
            }
            
        }
        
    }
    
    mutating func parseInteger() throws -> Int {
        
        try checkIndex()
        
        let firstValue = data[index]
        
        switch firstValue {
        case ASCII._0.rawValue:
            index += 1
            return 0
        case ASCII.dash.rawValue:
            index += 1
            
            let value = try parseNonNegativeInteger()
            
            precondition(value >= 0)
            
            guard value != 0 else {
                // Negative zero is not allowed
                throw Error.invalidFormat(index: index)
            }
            
            return -value
            
        case ASCII._1.rawValue...ASCII._9.rawValue /* '1'...'9' */:
            
            return try parseNonNegativeInteger()
            
        default:
            throw Error.invalidFormat(index: index)
        }
        
    }
    
}
