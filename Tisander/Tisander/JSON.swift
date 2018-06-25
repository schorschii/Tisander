//
//  JSON.swift
//  Tisander
//
//  Created by Mike Bignell on 22/06/2018.
//  Copyright © 2018 Mike Bignell. All rights reserved.
//

import Foundation

enum SerializationError: String, Error {
    case unterminatedObject
    case unterminatedArray
    case unterminatedString
    case invalidJSON
    case invalidArrayElement
    case invalidNumberMissingExponent
    case invalidNumberMissingFractionalElement
    case unexpectedEndOfFile
}

public protocol JSONElement: Value {}

public protocol Value {
    subscript(key: String) -> Value? { get }
    subscript(index: Int) -> Value? { get }
    func toJSONString() -> String
}

public extension Value {
    public subscript(key: String) -> Value? {
        get {
            return (self as? [JSON.ObjectElement])?.reduce(nil, { (result, element) -> Value? in
                guard result == nil else { return result }
                
                return element.key == key ? element.value : nil
            })
        }
    }
    
    public subscript(index: Int) -> Value? {
        get {
            guard let elementArray = self as? [JSON.ArrayElement],
                index >= 0,
                index <  elementArray.count
                else { return nil }
            
            return ((elementArray as [Any])[index] as? JSON.ArrayElement)?.value
        }
    }
    
    public var keys: [String]? {
        return (self as? [JSON.ObjectElement])?.compactMap { $0.key }
    }
    
    public var values: [Value]? {
        return (self as? [JSON.ArrayElement])?.map { $0.value } ?? (self as? [JSON.ObjectElement])?.map { $0.value }
    }
}

extension Bool: Value {
    public func toJSONString() -> String { return self ? "true" : "false" }
}
extension Int: Value {
    public func toJSONString() -> String { return String(self) }
}
extension Double: Value {
    public func toJSONString() -> String { return String(self) }
}
extension String: Value {
    public func toJSONString() -> String { return "\"\(self)\"" }
}
extension JSON.ArrayElement: JSONElement {
    public func toJSONString() -> String { return self.value.toJSONString() }
}
extension JSON.ObjectElement: JSONElement {
    public func toJSONString() -> String { return "\"\(self.key)\":\(self.value.toJSONString())" }
}
extension JSON.NULL: Value {
    public func toJSONString() -> String { return "null" }
}

extension Array: Value where Array.Element: JSONElement {
    public func toJSONString() -> String {
        if Array.Element.self == JSON.ObjectElement.self {
            return "{\( (self as! [JSON.ObjectElement]).map { $0.toJSONString() }.joined(separator: ",") )}"
        } else if Array.Element.self == JSON.ArrayElement.self {
            return "[\( (self as! [JSON.ArrayElement]).map { $0.toJSONString() }.joined(separator: ",") )]"
        }
        
        return ""
    }
}

open class JSON {
    open class NULL {}
    
    public struct ArrayElement {
        let value: Value
    }
    
    public struct ObjectElement {
        let key: String
        let value: Value
    }
    
    public static func parse(string: String) throws -> Value {
        
        let json = JSON()
        
        var index = string.startIndex
        
        // Run space parser to remove beginning spaces
        _ = json.spaceParser(string, index: &index)
        
        if let arrayElements = try json.arrayParser(string, index: &index) {
            return arrayElements
        } else if let objectElements = try json.objectParser(string, index: &index) {
            return objectElements
        }
        
        throw SerializationError.invalidJSON
    }
    
    //function to parser object
    //Starts by checking for a {
    //Next checks for the key of the object
    //finally the value of the key
    //Uses - KeyParser,SpaceParser,valueParser and endofsetParser
    //Finally checks for the end of the main Object with a }
    private func objectParser(_ jsonString: String, index: inout String.Index) throws -> [ObjectElement]? {
        guard index != jsonString.endIndex, jsonString[index] == "{" else { return nil }
        
        var parsedDict = [ObjectElement]()
        index = jsonString.index(after: index)
        
        while true {
            if let key = try keyParser(jsonString,index: &index) {
                _ = spaceParser(jsonString, index: &index)
                
                guard let _ = colonParser(jsonString, index: &index) else { return nil }
                
                if let value = try valueParser(jsonString, index: &index) {
                    parsedDict.append(ObjectElement(key: key, value: value))
                }
                
                _ = spaceParser(jsonString, index: &index)
                
                if let _ = endOfSetParser(jsonString, index: &index) {
                    return parsedDict
                }
            } else if index == jsonString.endIndex {
                throw SerializationError.unterminatedObject
            } else if jsonString[index] == "}" || isSpace(jsonString[index]) {
                _ = spaceParser(jsonString, index: &index)
                
                guard let _ = endOfSetParser(jsonString, index: &index) else {
                    throw SerializationError.unterminatedObject
                }
                
                return parsedDict
            } else {
                break
            }
        }
        
        return nil
    }
    
    //function to check key value in an object
    //Uses SpaceParser and StringParser
    private func keyParser(_ jsonString: String, index: inout String.Index) throws -> String? {
        _ = spaceParser(jsonString, index: &index)
        
        return try stringParser(jsonString, index: &index) ?? nil
    }
    
    //function to check colon
    private func colonParser(_ jsonString: String, index: inout String.Index) -> String? {
        guard index != jsonString.endIndex, jsonString[index] == ":" else { return nil }
        
        index = jsonString.index(after: index)
        
        return ":"
    }
    
    //function to check value in an object
    //SpaceParser to remove spaces
    //pass it to the elemParser
    //stores the returned element in a variable called value
    //afetr which the string is then passed to the space and comma parser
    private func valueParser(_ jsonString:String, index: inout String.Index) throws -> Value? {
        _ = spaceParser(jsonString, index: &index)
        
        guard let value = try elemParser(jsonString, index: &index) else { return nil }
        
        _ = spaceParser(jsonString, index: &index)
        _ = commaParser(jsonString, index: &index)
        return value
    }
    
    //function to check end of object
    //checks for a }
    private func endOfSetParser(_ jsonString:String, index: inout String.Index) -> Bool? {
        guard jsonString[index] == "}" else { return nil }
        
        index = jsonString.index(after: index)
        
        return true
    }
    
    //function to parser an array
    //starts by checking for a [
    //after which it is passed to an elemParser store the returned value in another array called parsed array
    //Uses elemParser,SpaceParser,commaParser,endOfArrayParser
    //Finally checks for a ] to mark the end of the array
    private func arrayParser(_ jsonString: String, index: inout String.Index) throws -> [ArrayElement]? {
        guard jsonString[index] == "[" else { return nil }
        
        var parsedArray = [ArrayElement]()
        index = jsonString.index(after: index)
        
        while true {
            if let returnedElem = try elemParser(jsonString, index: &index) {
                parsedArray.append(ArrayElement(value: returnedElem))
                _ = spaceParser(jsonString, index: &index)
                
                if let _ = commaParser(jsonString, index: &index) {
                    
                } else if let _ = endOfArrayParser(jsonString, index: &index) {
                    return parsedArray
                } else {
                    return nil
                }
            } else if index == jsonString.endIndex {
                throw SerializationError.unterminatedArray
            } else if jsonString[index] == "]" || isSpace(jsonString[index]) {
                _ = spaceParser(jsonString, index: &index)
                
                guard let _ = endOfArrayParser(jsonString, index: &index) else {
                    throw SerializationError.unterminatedArray
                }
                
                return parsedArray
            } else {
                throw SerializationError.invalidArrayElement
            }
        }
    }
    
    //Parsing elements in Array
    //uses StringParser,numberParser,arrayParser,objectParser and nullParser
    private func elemParser(_ jsonString:String, index: inout String.Index) throws -> Value? {
        guard index != jsonString.endIndex else { throw SerializationError.unexpectedEndOfFile }
        _ = spaceParser(jsonString, index: &index)
        
        if let returnedElem = try stringParser(jsonString, index: &index) {
            return returnedElem
        } else if let returnedElem = try numberParser(jsonString, index: &index) {
            return returnedElem
        } else if let returnedElem = booleanParser(jsonString, index: &index) {
            return returnedElem
        } else if let returnedElem = try arrayParser(jsonString, index: &index) {
            return returnedElem
        } else if let returnedElem = try objectParser(jsonString, index: &index) {
            return returnedElem
        } else if let returnedElem = nullParser(jsonString, index: &index) {
            return returnedElem
        }
        
        return nil
    }
    
    //A function to check end of array
    private func endOfArrayParser(_ jsonString:String, index: inout String.Index) -> Bool? {
        guard index != jsonString.endIndex, jsonString[index] == "]" else { return nil }
        
        index = jsonString.index(after: index)
        
        return true
    }
    
    //method to check space
    private func isSpace(_ c: Character) -> Bool {
        return [" ", "\t", "\n"].contains(c)
    }
    
    //space parser
    //uses isSpace function
    @discardableResult
    private func spaceParser(_ jsonString: String, index: inout String.Index) -> String? {
        guard index != jsonString.endIndex, isSpace(jsonString[index]) else { return nil }
        
        let startingIndex = index
        
        while index != jsonString.endIndex {
            guard isSpace(jsonString[index]) else { break }
            
            index = jsonString.index(after: index)
        }
        
        return String(jsonString[startingIndex ..< index])
    }
    
    //method to check for  number
    func isNumber(_ n: Character) -> Bool {
        return "0" ... "9" ~= n
    }
    
    //method to consume the number
    func consumeNumber(_ jsonString: String, index: inout String.Index) {
        while isNumber(jsonString[index]) {
            guard jsonString.index(after: index) != jsonString.endIndex else { break }
            
            index = jsonString.index(after: index)
        }
    }
    
    //number parser -- This method check all json valid numbers including exponents
    func numberParser(_ jsonString: String, index: inout String.Index) throws -> Value? {
        
        let startingIndex = index
        
        // When number is negative i.e. starts with "-"
        if jsonString[startingIndex] == "-" {
            index = jsonString.index(after: index)
        }
        
        guard isNumber(jsonString[index]) else { return nil }
        
        consumeNumber(jsonString,index: &index)
        
        // For decimal points
        if jsonString[index] == "." {
            guard jsonString.index(after: index) != jsonString.endIndex else { return nil }
            
            index = jsonString.index(after: index)
            
            guard isNumber(jsonString[index]) else {
                throw SerializationError.invalidNumberMissingFractionalElement
            }
            
            consumeNumber(jsonString,index: &index)
        }
        
        //For exponents
        if String(jsonString[index]).lowercased() == "e" {
            
            guard jsonString.index(after: index) != jsonString.endIndex else { return nil }
            
            index = jsonString.index(after: index)
            
            if jsonString[index] == "-" || jsonString[index] == "+" {
                index = jsonString.index(after: index)
            }
            
            guard isNumber(jsonString[index]) else {
                throw SerializationError.invalidNumberMissingExponent
            }
            
            consumeNumber(jsonString,index: &index)
        }
        
        guard let double = Double(jsonString[startingIndex ..< index]) else { return nil }
        
        return (double.truncatingRemainder(dividingBy: 1.0) == 0.0 && double <= Double(Int.max)) ? Int(double) : double
    }
    
    // string parser
    func stringParser(_ jsonString: String, index: inout String.Index) throws -> String? {
        guard index != jsonString.endIndex, jsonString[index] == "\"" else { return nil }
        
        index = jsonString.index(after: index)
        let startingIndex = index
        
        while index != jsonString.endIndex {
            if jsonString[index] == "\\" {
                index = jsonString.index(after: index)
                
                if jsonString[index] == "\"" {
                    index = jsonString.index(after: index)
                } else {
                    continue
                }
            } else if jsonString[index] == "\"" {
                break
            } else {
                index = jsonString.index(after: index)
            }
        }
        
        let parsedString = String(jsonString[startingIndex ..< index])
        
        guard index != jsonString.endIndex else {
            index = startingIndex
            throw SerializationError.unterminatedString
        }
        
        index = jsonString.index(after: index)
        
        return parsedString
    }
    
    //comma parser
    private func commaParser(_ jsonString: String, index: inout String.Index) -> String? {
        guard index != jsonString.endIndex, jsonString[index] == "," else { return nil }
        
        index = jsonString.index(after: index)
        return ","
    }
    
    //boolean parser
    //advances the index by 4 and checks for true or by 5 and checks for false
    private func booleanParser(_ jsonString: String, index: inout String.Index) -> Bool? {
        let startingIndex = index
        
        if let advancedIndex = jsonString.index(index, offsetBy: 4, limitedBy: jsonString.endIndex) {
            index = advancedIndex
        } else {
            return nil
        }
        
        if jsonString[startingIndex ..< index] == "true" {
            return true
        }
        
        if index != jsonString.endIndex {
            index = jsonString.index(after: index)
            
            if jsonString[startingIndex ..< index]  == "false" {
                return false
            }
        }
        
        index = startingIndex
        
        return nil
    }
    
    private func nullParser(_ jsonString: String, index: inout String.Index) -> NULL? {
        let startingIndex = index
        
        if let advancedIndex = jsonString.index(index, offsetBy: 4, limitedBy: jsonString.endIndex) {
            index = advancedIndex
        } else {
            return nil
        }
        
        if jsonString[startingIndex ..< index].lowercased() == "null" {
            return NULL()
        }
        
        index = startingIndex
        
        return nil
    }
}
