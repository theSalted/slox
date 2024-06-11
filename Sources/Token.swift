//
//  Token.swift
//
//
//  Created by Yuhao Chen on 6/11/24.
//

import Foundation

enum TokenType: String {
    // Single-character tokens
    case leftParenthesis = "("
    case rightParenthesis = ")"
    case leftBrace = "{"
    case rightBrace = "}"
    case comma = ","
    case dot = "."
    case minus = "-"
    case plus = "+"
    case semicolon = ";"
    case slash = "/"
    case star = "*"
    case doubleQuote = "\""
    case underScore = "_"
    
    // One or two character tokens
    case bang = "!"
    case bangEqual = "!="
    case equal = "="
    case equalEqual = "=="
    case greater = ">"
    case greaterEqual = ">="
    case less = "<"
    case lessEqual = "<="
    
    // Literals
    case identifier
    case string
    case number
    
    // Keywords
    case and
    case `class`
    case `else`
    case `false`
    case fun
    case `for`
    case `if`
    case `nil`
    case or
    case print
    case `return`
    case `super`
    case this
    case `true`
    case `var`
    case `while`
    case `eof`
    
    /// Return token character if it exists
    var character: Character {
        rawValue.count == 1 ? Character(rawValue) : "\0"
    }
}

struct Token: CustomStringConvertible {
    let type: TokenType
    let lexeme: String
    let literal: Any?
    let line: Int
    
    init(_ type: TokenType, lexeme: String, literal: Any?, line: Int) {
        self.type = type
        self.lexeme = lexeme
        self.literal = literal
        self.line = line
    }
    
    var description: String {
        let literalText: String
        if let literal {
            literalText = " -> '\(literal)'"
        } else {
            literalText = ""
        }
        
        return "\(type) \(lexeme) \(literalText)"
    }
    
}
