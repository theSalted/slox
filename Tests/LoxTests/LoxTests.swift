//
//  File.swift
//  
//
//  Created by Yuhao Chen on 6/13/24.
//

import Testing
@testable import Lox

struct ScannerTest {
    @Test("Check character tokens one at a time",
          arguments: [
            TokenType.leftParenthesis,
            .rightParenthesis,
            .leftBrace,
            .rightBrace,
            .comma,
            .dot,
            .minus,
            .plus,
            .semicolon,
            .slash,
            .star,
            .doubleQuote,
            .underScore,
            .bang,
            .bangEqual,
            .equal,
            .equalEqual,
            .greater,
            .greaterEqual,
            .less,
            .lessEqual
          ]
    )
    func singleCharacter(character: TokenType) {
        let scanner = Scanner(character.rawValue)
        let scannedTokens = scanner.scanTokens()
        let expectedTokens: [Token] = [
            .init(character, lexeme: character.rawValue, literal: nil, line: 1),
            .init(.eof, lexeme: "", literal: nil, line: 1)
        ]
        
        #expect(
            scannedTokens == expectedTokens
        )
    }
    
    @Test("Check keyword tokens one at a time",
          arguments: [
            TokenType.and,
            .class,
            .else,
            .false,
            .fun,
            .for,
            .if,
            .nil,
            .or,
            .print,
            .return,
            .super,
            .this,
            .true,
            .var,
            .while
          ]
    )
    func singleKeyword(keyword: TokenType) {
        let scanner = Scanner(keyword.rawValue)
        let scannedTokens = scanner.scanTokens()
        let expectedTokens: [Token] = [
            .init(keyword, lexeme: keyword.rawValue, literal: nil, line: 1),
            .init(.eof, lexeme: "", literal: nil, line: 1)
        ]
        
        #expect(
            scannedTokens == expectedTokens
        )
    }
    
    @Test("Check single double quoted string",
          arguments:[
            "Hello"
          ]
    )
    func singleIdentity(identifier: String) {
        let scanner = Scanner(identifier)
        let scannedTokens = scanner.scanTokens()
        
        let expectedTokens: [Token] = [
            .init(.identifier, lexeme: identifier, literal: nil, line: 1),
            .init(.eof, lexeme: "", literal: nil, line: 1)
        ]
        
        #expect(
            scannedTokens == expectedTokens
        )
    }

    
    @Test("Check single double quoted string",
          arguments:[
            "Hello",
            "Hello, World",
            "+-*/",
            "\t\t\t",
            "\0\r\t",
            "''",
            "_abc def ghi"
          ]
    )
    func simpleString(string: String) {
        let doubleQuoted = "\"\(string)\""
        let scanner = Scanner(doubleQuoted)
        let scannedTokens = scanner.scanTokens()
        
        let expectedTokens: [Token] = [
            .init(.string, lexeme: doubleQuoted, literal: string, line: 1),
            .init(.eof, lexeme: "", literal: nil, line: 1)
        ]
        
        #expect(
            scannedTokens == expectedTokens
        )
    }
    
    @Test("Check newlines in string",
          arguments: [
            ("Hello \n World", 1),
            ("Brave \n New \n World", 2),
            ("Hi! \n My Friend, \n I miss you. \n <3", 3),
            ("\n\n\n\n", 4)
          ]
    )
    func newlineInString(string: String, numberOfNewlines: Int) {
        let doubleQuoted = "\"\(string)\""
        
        let scanner = Scanner(doubleQuoted)
        let scannedTokens = scanner.scanTokens()
        
        let expectedLines = 1 + numberOfNewlines
        let expectedTokens: [Token] = [
            .init(.string, lexeme: doubleQuoted, literal: string, line: expectedLines),
            .init(.eof, lexeme: "", literal: nil, line: expectedLines)
        ]
        
        #expect(
            scannedTokens == expectedTokens
        )
    }
    
    @Test("Simple Number",
          arguments: [
            ("0.0", 0.0),
            ("3.1415926", 3.1415926),
            ("0.1111", 0.1111),
            ("1111.0", 1111.0),
            ("1234.0000", 1234.0),
            ("1234", 1234.0),
          ]
    )
    func simpleNumber(string: String, double: Double) {
        let scanner = Scanner(string)
        let scannedTokens = scanner.scanTokens()
        
        let expectedTokens: [Token] = [
            .init(.number, lexeme: string, literal: double, line: 1),
            .init(.eof, lexeme: "", literal: nil, line: 1)
        ]
        
        #expect(
            scannedTokens == expectedTokens
        )
    }
    
    @Test
    func emptySource() {
        let scanner = Scanner("")
        let scannedTokens = scanner.scanTokens()
        let expectedTokens: [Token] = [
            .init(.eof, lexeme: "", literal: nil, line: 1)
        ]
        
        #expect(
            scannedTokens == expectedTokens
        )
    }
    
}



extension Token: Equatable  { 
    public static func == (lhs: Token, rhs: Token) -> Bool {
        switch lhs.type {
        case .string:
            guard
                let lhsString = lhs.literal as? String,
                let rhsString = rhs.literal as? String
            else {
                return false
            }
            if lhsString != rhsString {
                return false
            }
        case .number:
            guard
                let lhsNumber = lhs.literal as? Double,
                let rhsNumber = rhs.literal as? Double
            else {
                return false
            }
            if lhsNumber != rhsNumber {
                return false
            }
        default: break
        }
        
        let lhsLiteralIsNotNil = lhs.literal != nil
        let rhsLiteralIsNotNil = rhs.literal != nil
        
        return lhs.type == rhs.type &&
               lhs.lexeme == rhs.lexeme &&
               lhs.line == rhs.line &&
               lhsLiteralIsNotNil == rhsLiteralIsNotNil
    }
}

