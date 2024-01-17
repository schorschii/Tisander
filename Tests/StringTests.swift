//
//  StringTests.swift
//  TisanderTests
//
//  Created by Mike Bignell on 26/06/2018.
//  Copyright © 2018 Mike Bignell. All rights reserved.
//

import XCTest
@testable import Tisander

class StringTests: TisanderTest {
    func testSimpleString() {
        let input = """
["a"]
"""
        var json: Value
        do { json = try JSON.parse(string: input) } catch let e { XCTFail((e as? SerializationError)?.rawValue ?? "Unknown exception"); return }
        
        XCTAssertEqual(json[0] as? String, "a")
    }
    
    func testEmptyString() {
        let input = """
[""]
"""
        var json: Value
        do { json = try JSON.parse(string: input) } catch let e { XCTFail((e as? SerializationError)?.rawValue ?? "Unknown exception"); return }
        
        XCTAssertEqual(json[0] as? String, "")
    }
    
    func testEscapedStringString() {
        let input = """
["\\a"]
"""
        var json: Value
        do { json = try JSON.parse(string: input) } catch let e { XCTFail((e as? SerializationError)?.rawValue ?? "Unknown exception"); return }
        
        XCTAssertEqual(json[0] as? String, "\\a")
    }
    
    func testEscapedCharsString() {
        let input = """
["\\n", "\\t", "\\r", "\\\"", "\\u00fc", "\\\\"]
"""
        var json: Value
        do { json = try JSON.parse(string: input) } catch let e { XCTFail((e as? SerializationError)?.rawValue ?? "Unknown exception"); return }
        
        XCTAssertEqual(json[0] as? String, "\n")
        XCTAssertEqual(json[1] as? String, "\t")
        XCTAssertEqual(json[2] as? String, "\r")
        XCTAssertEqual(json[3] as? String, "\"")
        XCTAssertEqual(json[4] as? String, "ü")
        XCTAssertEqual(json[5] as? String, "\\")
    }
    
    func testEscapedSlashString() {
        // invalid JSON ["a\b\"] should throw SerializationError.unterminatedString
        let input = """
["a\\b\\"]
"""
        XCTAssertThrowsError(try JSON.parse(string: input)) { error in
            XCTAssertEqual(error as! SerializationError, SerializationError.unterminatedString)
        }
    }
    
    func testUnterminatedString() {
        let input = """
["]
"""
        do {
            _ = try JSON.parse(string: input)
            XCTFail()
        } catch let e {
            XCTAssert(e as? SerializationError == SerializationError.unterminatedString)
        }
    }
}
