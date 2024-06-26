//
//  Token.swift
//
//
//  Created by Yuhao Chen on 6/11/24.
//

import Foundation

/// An enumeration representing the various types of tokens that can be encountered in the Lox language.
public enum TokenType: String {
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
    
    /// Returns the token character if it exists.
    ///
    /// - Warning: if a token doesn't have a matching character `\0` is returned instead.
    var character: Character {
        rawValue.count == 1 ? Character(rawValue) : "\0"
    }
}

/// A structure representing a token in the Lox language.
public struct Token: CustomStringConvertible {
    let type: TokenType
    let lexeme: String
    let literal: Any?
    let line: Int
    
    /// Initializes a new token with the specified type, lexeme, literal, and line number.
    /// - Parameters:
    ///   - type: The type of the token.
    ///   - lexeme: The lexeme (text) of the token.
    ///   - literal: The literal value of the token, if any.
    ///   - line: The line number where the token is found.
    init(_ type: TokenType, lexeme: String, literal: Any?, line: Int) {
        self.type = type
        self.lexeme = lexeme
        self.literal = literal
        self.line = line
    }
    
    /// A textual description of the token, including its type, lexeme, and literal value if present.
    public var description: String {
        let literalText: String
        if let literal {
            literalText = " -> '\(literal)'"
        } else {
            literalText = ""
        }
        
        return "\(type) \(lexeme) \(literalText)"
    }
}
