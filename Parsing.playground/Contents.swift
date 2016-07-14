import UIKit

enum ParsingError : ErrorType {
  case RequiredField(String)
}

struct Person : Parsable {
  let name: String
  let age: Int?
  let address: Address?

  init(dict: [String : AnyObject]) throws {
    name = try "name" <- dict
    age = "age" <~ dict
    address = "addr" <~ dict
  }
}

infix operator <- { associativity left precedence 150 }
infix operator <~ { associativity left precedence 150 }

protocol Decodable {
  static func decode(anyObject: AnyObject) -> Self?
}

extension Decodable {
  static func decode(anyObject: AnyObject) -> Self? {
    return anyObject as? Self
  }
}

extension String : Decodable { }
extension Int : Decodable { }

struct Address : Parsable {
  let houseNumber: String?
  let street: String
  let city: String

  init(dict: [String : AnyObject]) throws {
    houseNumber = "houseNo" <~ dict
    street = try "street" <- dict
    city = try "city" <- dict
  }
}

protocol Parsable : Decodable {
  init(dict: [String : AnyObject]) throws
}

extension Parsable {
  static func decode(anyObject: AnyObject) -> Self? {
    guard let dict = anyObject as? [String : AnyObject] else {
      return nil
    }

    do {
      return try Self.init(dict: dict)
    } catch {
      return nil
    }
  }
}




func <-<T : Decodable> (key: String, dict: [String : AnyObject]) throws -> T {
  guard let anyObject = dict[key] else {
    throw ParsingError.RequiredField("missing field \(key)")
  }
  guard let value = T.decode(anyObject) else {
    throw ParsingError.RequiredField("missing field \(key)")
  }
  return value
}

func <~<T : Decodable> (key: String, dict: [String : AnyObject]) -> T? {
  guard let anyObject = dict[key] else {
    return nil
  }
  return T.decode(anyObject)
}


let person = try! Person(dict: ["name": "Tapan","age":27, "addr" : ["street" : "MG road","city" : "Pune" ]])





