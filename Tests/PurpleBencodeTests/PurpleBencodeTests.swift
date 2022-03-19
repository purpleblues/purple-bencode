import XCTest
@testable import PurpleBencode

final class PurpleBencodeTests: XCTestCase {
    
    func testEncodingInteger() {
        XCTAssertEqual(Bencode.integer(123).data(), "i123e".data(using: .utf8)!)
    }
    
    func testEncodingString() {
        XCTAssertEqual(Bencode.string("Hello").data(), "5:Hello".data(using: .utf8)!)
    }
    
    func testEncodingList() {
        XCTAssertEqual(Bencode.list(["Hello", 123]).data(), "l5:Helloi123ee".data(using: .utf8)!)
    }
    
    func testEncodingDictionary() {
        
        XCTAssertEqual(Bencode.dictionary(["Hello": 123]).data(),
                       "d5:Helloi123ee".data(using: .utf8)!)
        
        XCTAssertEqual(Bencode.dictionary(["Hello": 123, "World": 456]).data(),
                       "d5:Helloi123e5:Worldi456ee".data(using: .utf8)!)
        
    }
    
    func testDecodingInteger() throws {
        
        for _ in 0..<20 {
            
            let value: Int = .random(in: .min ... .max)
        
            try XCTAssertEqual(Bencode(data: "i\(value)e".data(using: .utf8)!), .integer(value))
            
            try XCTAssertNotEqual(Bencode(data: "i\(value)e".data(using: .utf8)!), .integer(-value))

        }
        
        XCTAssertThrowsError(try Bencode(data: "i123".data(using: .utf8)!))
        
        XCTAssertThrowsError(try Bencode(data: "i123a".data(using: .utf8)!))
        
        XCTAssertThrowsError(try Bencode(data: "i1-23a".data(using: .utf8)!))
        
        XCTAssertThrowsError(try Bencode(data: "ie".data(using: .utf8)!))
        
        XCTAssertThrowsError(try Bencode(data: "i00e".data(using: .utf8)!))
        
        XCTAssertThrowsError(try Bencode(data: "i-0e".data(using: .utf8)!))
        
        XCTAssertThrowsError(try Bencode(data: "i0123e".data(using: .utf8)!))
        
        XCTAssertThrowsError(try Bencode(data: "i\(Int64.max)9999e".data(using: .utf8)!))
        
    }
    
    func testDecodingString() throws {
        
        let strings: [String] = [
            "Hello",
            "World",
            "안녕하세요",
            "😀Hello",
            "",
            "😀",
            "😀😀",
            "👩‍👩‍👧‍👧"
        ]
        
        for string in strings {
            
            try XCTAssertEqual(Bencode(data: "\(string.utf8.count):\(string)".data(using: .utf8)!),
                .string(string))
            
        }
        
    }
    
}
