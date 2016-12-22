//: Playground - noun: a place where people can play

import Cocoa

let expression = "124+569"

struct Parser<A> {
    typealias Stream = String.CharacterView
    let parse: (Stream) -> (A, Stream)?
}

func characterParser(_ function: @escaping (Character) -> Bool) -> Parser<Character> {
    return Parser<Character> { stream in
        guard let char = stream.first, function(char) else { return nil }
        return (char, stream.dropFirst())
    }
}

extension Parser {
    func debug(_ str: String) -> (A, String)? {
        guard let (result, remainder) = self.parse(str.characters) else { return nil }
        return (result, String(remainder))
    }
}

let aAlphaParser = characterParser({ "a" == $0 })

let parseResult = aAlphaParser.debug("abcd")

let singleDigitParser = characterParser({ Int(String($0)) != nil })

singleDigitParser.debug("12345")


extension Parser {

    func many() -> Parser<[A]> {
        return Parser<[A]> { stream in
            var elements: [A] = []
            var remainder = stream
            while let (result, newRemainder) = self.parse(remainder) {
                elements.append(result)
                remainder = newRemainder
            }
            return (elements, remainder)
        }
    }
}

let digitParser = singleDigitParser.many()
digitParser.debug("12346567abcd")

extension Parser {

    func map<B>(_ function: @escaping (A) -> B) -> Parser<B> {
        return Parser<B> { stream in
            guard let (result, remainder) = self.parse(stream) else { return nil }
            return (function(result), remainder)
        }
    }
}

let integerParser = digitParser.map({ Int(String($0))! })
integerParser.debug("1213223abc")

let operatorParser =  characterParser({ $0 == "+" })

extension Parser {

    func followedBy<B>(_ otherParser: Parser<B>) -> Parser<(A,B)> {
        return Parser<(A,B)> { stream in
            guard let (result1, remainder1) = self.parse(stream) else { return nil }
            guard let (result2, remainder2) = otherParser.parse(remainder1) else { return nil }
            return ((result1, result2), remainder2)
        }
    }
}

func calculate(_ number1: Int, _ op: Character, _ number2: Int) -> Int {
    switch op {
    case "+":
        return number1 + number2
    default:
        return 0
    }
}

func calculateCurried (_ number1: Int) -> (_ op: Character) -> (_ number2: Int) -> Int {
    return { op in
        return { number2 in
            return calculate(number1, op, number2)
        }
    }
}



calculate(213, "+", 56)

calculateCurried(213)("+")(56)

precedencegroup CombinatorGroup {
    associativity: left
}


infix operator <*> : CombinatorGroup
infix operator <^> : CombinatorGroup
// ( A <*> B ) <*> C

func <*><A,B> (_ lhsParser: Parser<(A) -> B> , rhsParser: Parser<A>) -> Parser<B> {
    return lhsParser.followedBy(rhsParser).map ({f,x in f(x)})
}

func <^> <A,B> (_ lhs: @escaping (A) -> B, rhs: Parser<A>) -> Parser<B> {
    return rhs.map({a in lhs(a)} )
}

public func curry<A, B, C, D>(_ function: @escaping (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    return { (a: A) -> (B) -> (C) -> D in { (b: B) -> (C) -> D in { (c: C) -> D in function(a, b, c) } } }
}

let curriedFunction = curry(calculate)
curriedFunction(4)("+")(5)


//let expressionParser = integerParser.map({ return calculateCurried($0)})
//                    .followedBy(integerParser).map({f,x in f(x) })


//let expressionParser =  integerParser.map({ return calculateCurried($0)}) <*> operatorParser <*> integerParser

let expressionParser =  calculateCurried <^> integerParser <*> operatorParser <*> integerParser


let expressionResult = expressionParser.debug("1234+456")
print(expressionResult)