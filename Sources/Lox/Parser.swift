//
//  Parser.swift
//
//
//  Created by Yuhao Chen on 6/16/24.
//

import Foundation

class Parser {
    let tokens: [Token]
    var currentPosition: Int = 0
    
    private var previousToken: Token {
        return tokens[currentPosition - 1]
    }
    
    private var latestToken: Token {
        return tokens[currentPosition]
    }
    
    // - NOTE: There is no upcomingToken (latestToken is always ahead target)
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    func parse() -> Expression? {
        do {
            return try expression()
        } catch {
            return nil
        }
    }
    
    private func expression() throws -> Expression {
        return try equality()
    }
    
    private func equality() throws -> Expression {
        try leftAssociativeBinary(comparison(), types: .bangEqual, .equalEqual)
    }
    
    private func comparison() throws -> Expression {
        try leftAssociativeBinary(term(), types: .greater, .greaterEqual, .less, .lessEqual)
    }
    
    private func term() throws -> Expression {
        try leftAssociativeBinary(factor(), types: .minus, .plus)
    }
    
    private func factor() throws -> Expression {
        try leftAssociativeBinary(unary(), types: .slash, .star)
    }
    
    private func unary() throws -> Expression {
        if (match(.bang, .minus)) {
            let `operator` = previousToken
            let rhs = try unary()
            return Unary(operator: `operator`, rhs: rhs)
        }
        
        return try primary()
    }
   
    
    private func primary() throws -> Expression {
        if match(.false) {
            return Literal(value: false)
        }
        if match(.true) {
            return Literal(value: true)
        }
        if match(.nil) {
            return Literal(value: nil)
        }
        if match(.number, .string) {
            return Literal(value: previousToken.literal)
        }
        if match(.leftParenthesis) {
            let expression = try expression()
            
            do {
                try consume(.rightParenthesis)
            } catch {
                // error("Expected ')' after expression")
                throw reportError("unexpected ')' after expression", token: latestToken)
            }
            
            return Grouping(expression: expression)
        }
        
        throw reportError("Unexpected expression", token: latestToken)
    }
    
    private func leftAssociativeBinary(
        _ lhs: Expression,
        types: TokenType...
    ) throws -> Expression {
        var expression = lhs
        while match(types) {
            let `operator` = previousToken
            let rhs = try comparison()
            expression = Binary(lhs: lhs, operator: `operator`, rhs: rhs)
        }
        return expression
    }
}


// MARK: Utility methods
/// Helper methods that directly interact with parser while not necessarily part of the grammar
extension Parser {
    
    @discardableResult private func advance() -> Token {
        if (!reachedEOF()) {
            currentPosition += 1
        }
        return previousToken
    }
    
    @discardableResult private func consume(_ type: TokenType) throws -> Token {
        if matchLatest(type) {
            return advance()
        }
        
        throw ParserError.unmatchedConsume
    }
    
    /// Check if latest character matches given token
    private func matchLatest(_ type: TokenType) -> Bool {
        if (reachedEOF()) { return false }
        return latestToken.type == type
    }
    
    private func match(
        _ types: [TokenType],
        advance advanceWhenMatched: Bool = true
    ) -> Bool {
        for type in types {
            if matchLatest(type) && advanceWhenMatched {
                advance()
                return true
            }
        }
        
        return false
    }
    
    private func match(_ types: TokenType...) -> Bool {
        match(types)
    }
    
    /// Wether the parser reached the end
    ///
    /// - Warning: This method check wether latest character is `.eof`, and **not** if currentIndex has reached the length yet
    private func reachedEOF() -> Bool {
        return latestToken.type == .eof
    }
}


extension Parser {
    enum ParserError: Error {
        case unmatchedConsume, runtime, parsingError(message: String)
    }
    
    func reportError(_ message: String, token: Token) -> Error {
        Lox.reportError(message, at: token)
        return ParserError.parsingError(message: message)
    }
    
    /// Attempt to synchronize parser right pass when an recoverable error occurred
    private func synchronize() {
        let targetToken = latestToken
        advance()
        
        while !reachedEOF() {
            if targetToken.type == .semicolon {
               return
            }
            
            switch(latestToken.type) {
            case .class, .fun, .var, .for, .if, .while, .print, .return:
                return
            default:
                advance()
            }
        }
    }
}
