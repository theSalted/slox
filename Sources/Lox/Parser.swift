//
//  Parser.swift
//
//
//  Created by Yuhao Chen on 6/16/24.
//

import Foundation

public class Parser {
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
    
    func parse() -> Array<Statement> {
        var statements = Array<Statement>()
        while !reachedEOF() {
            if let declaration = declaration() {
                statements.append(declaration)
            }
        }
        return statements
    }
    
    func parse() -> Expression? {
        do {
            return try expression()
        } catch {
            return nil
        }
    }
    
    
    // MARK: Statements
    private func declaration() -> Statement? {
        do {
            if (match(.var)) { return try variableDeclaration() }
            return try statement()
        } catch {
            synchronize()
            return nil
        }
    }
    
    private func statement() throws -> Statement {
        if match(.for) { return try forStatement() }
        if match(.if) { return try ifStatement() }
        if match(.print) { return try printStatement() }
        if match(.while) { return try whileStatement() }
        if match(.leftBrace) {
            return Block(statements: try block())
        }
        
        return try expressionStatement()
    }
    
    private func forStatement() throws -> Statement {
        do { try consume(.leftParenthesis) }
        catch { throw reportError("Expect '(' after for 'for'.", token: latestToken) }
        
        let initializer: Statement?
        if match(.semicolon) {
            initializer = nil
        } else if match(.var) {
            initializer = try variableDeclaration()
        } else {
            initializer = try expressionStatement()
        }
        
        let condition: Expression = matchLatest(.semicolon) ? Literal(value: true) : try expression()
        do { try consume(.semicolon) }
        catch { throw reportError("Expect ';' after loop condition.", token: latestToken) }
        
        let increment: Expression? = matchLatest(.rightParenthesis) ? nil : try expression()
        do { try consume(.rightParenthesis) }
        catch { throw reportError("Expect ')' after for clauses.", token: latestToken) }
        
        var body = try statement()
        
        if let increment {
            body = Block(statements: [body, Expr(expression: increment)])
        }
        
        body = While(condition: condition, body: body)
        
        if let initializer {
            body = Block(statements: [initializer, body])
        }
        
        return body
    }
    
    private func whileStatement() throws -> Statement {
        do { try consume(.leftParenthesis) }
        catch { throw reportError("Expect '(' after 'while'.", token: latestToken) }
        
        let condition = try expression()
        
        do { try consume(.rightParenthesis) }
        catch { throw reportError("Expect ')' after condition.", token: latestToken) }
        
        let body = try statement()
        
        return While(condition: condition, body: body)
    }
    
    private func variableDeclaration() throws -> Statement {
        let name: Token
        do { name = try consume(.identifier) }
        catch { throw reportError("Expect variable name", token: latestToken) }
        
        var initializer: Expression? = nil
        if match(.equal) {
            initializer = try expression()
        }
        
        do { try consume(.semicolon) }
        catch { throw reportError("Expect ';' after variable deceleration", token: latestToken) }
        
        return Var(name: name, initializer: initializer)
        
    }
    
    private func expressionStatement() throws -> Statement {
        let expression = try expression()
        
        do {
            try consume(.semicolon)
        } catch {
            throw reportError("Expect ';' after value", token: latestToken)
        }
        
        return Expr(expression: expression)
    }
    
    private func ifStatement() throws -> Statement {
        do { try consume(.leftParenthesis) }
        catch { throw reportError("Expect '(' after 'if'.", token: latestToken) }
        
        let condition = try expression()
        
        do { try consume(.rightParenthesis) }
        catch { throw reportError("Expect ')' after if condition.", token: latestToken) }
        
        let then = try statement()
        let `else`: Statement?
        if match(.else) { `else` = try statement() }
        else { `else` = nil }
        
        return If(condition: condition, then: then, else: `else`)
    }
    
    private func block() throws -> Array<Statement> {
        var statements = Array<Statement>()
        
        while !matchLatest(.rightBrace) && !reachedEOF() {
            if let declaration = declaration() {
                statements.append(declaration)
            }
        }
        
        do {
            try consume(.rightBrace)
        } catch {
            throw reportError("Expect '}' after block.", token: latestToken)
        }
        
        return statements
    }
    
    private func printStatement() throws -> Statement {
        let value = try expression()
        do {
            try consume(.semicolon)
        } catch {
            throw reportError("Expect ';' after value", token: latestToken)
        }
        
        return Print(expression: value)
    }
    
    
    // MARK: Expressions
    private func expression() throws -> Expression {
        return try assignment()
    }
    
    private func assignment() throws -> Expression {
        let expression = try or()
        
        if match(.equal) {
            let equals = previousToken
            let value = try assignment()
            
            if let variable = expression as? Variable  {
                let name = variable.name
                return Assignment(name: name, value: value)
            }
            
            throw reportError("Invalid assignment target", token: equals)
        }
        
        return expression
    }
    
    private func or() throws -> Expression {
        var expression = try and()
        
        while match(.or) {
            let op = previousToken
            let rhs = try and()
            expression = Logical(lhs: expression, operator: op, rhs: rhs)
        }
        
        return expression
    }
    
    private func and() throws -> Expression {
        var expression = try equality()
        
        while match(.and) {
            let op = previousToken
            let rhs = try equality()
            expression = Logical(lhs: expression, operator: op, rhs: rhs)
        }
        
        return expression
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
        if match(.identifier) {
            return Variable(name: previousToken)
        }
        if match(.leftParenthesis) {
            let expression = try expression()
            
            do {
                try consume(.rightParenthesis)
            } catch {
                // error("Expected ')' after expression")
                throw reportError("Unexpected ')' after expression", token: latestToken)
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
public extension Parser {
    
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
        if reachedEOF() { return false }
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


public extension Parser {
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
