//
//  Resolver.swift
//  
//
//  Created by Yuhao Chen on 7/18/24.
//

import Foundation

public final class Resolver: ExpressionVisitor, StatementVisitor {
    public typealias ExpressionVisitorReturn = Void
    public typealias StatementVisitorReturn = Void
    
    private let interpreter: Interpreter
    private var scopes: Array<Dictionary<String, Bool>> = []
    private var currentClassType: ClassType = .none
    private var currentFunctionType: FunctionType = .none
    
    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }
    
    public func resolve(_ statements: Array<Statement>) {
        for statement in statements {
            resolve(statement)
        }
    }
    
    private func resolve(_ statement: Statement) {
        statement.accept(visitor: self)
    }
    
    private func resolve(_ expr: Expression) {
        expr.accept(visitor: self)
    }
    
    // - MARK: Statement
    public func visit(_ stmt: Block) -> Void {
        beginScope()
        resolve(stmt.statements)
        endScope()
    }
    
    public func visit(_ stmt: Class) -> Void {
        declare(stmt.name)
        define(stmt.name)
        
        let enclosingClassType = currentClassType
        defer { currentClassType = enclosingClassType }
        currentClassType = .class
        
        beginScope()
        scopes[scopes.count - 1]["this"] = true
        
        for method in stmt.methods {
            var declaration = FunctionType.method
            if method.name.lexeme == "init" {
                declaration = .initializer
            }
            resolveFunction(method, type: declaration)
        }
        
        endScope()
    }
    
    public func visit(_ stmt: Var) -> Void {
        declare(stmt.name)
        if let initializer = stmt.initializer  {
            resolve(initializer)
        }
        define(stmt.name)
    }
    
    public func visit(_ stmt: Expr) -> Void {
        resolve(stmt.expression)
    }
    
    public func visit(_ stmt: Function) -> Void {
        declare(stmt.name)
        define(stmt.name)
        
        resolveFunction(stmt)
    }
    
    public func visit(_ stmt: If) -> Void {
        resolve(stmt.condition)
        resolve(stmt.then)
        if let `else` = stmt.else {
            resolve(`else`)
        }
    }
    
    public func visit(_ stmt: LoxReturn) -> Void {
        if currentFunctionType == .none {
            Lox.reportError("Can't return from top-level code.", at: stmt.keyword)
        }
        
        if let value = stmt.value {
            if currentFunctionType == .initializer {
                Lox.reportError("Can't return a value from an initializer", at: stmt.keyword)
            }
            resolve(value)
        }
    }
    
    public func visit(_ stmt: While) -> Void {
        resolve(stmt.condition)
        resolve(stmt.body)
    }
    
    public func visit(_ stmt: Print) -> Void {
        resolve(stmt.expression)
    }
    
    // - MARK: Expression
    public func visit(_ expr: Variable) -> Void {
        if !scopes.isEmpty && scopes.last?[expr.name.lexeme] == false {
            Lox.reportError("Can't read local variable in its own initializer", at: expr.name)
        }
        
        resolveLocal(expr, expr.name)
    }
    
    public func visit(_ expr: Assignment) -> Void {
        resolve(expr.value)
        resolveLocal(expr, expr.name)
    }
    
    public func visit(_ expr: Binary) -> Void {
        resolve(expr.lhs)
        resolve(expr.rhs)
    }
    
    public func visit(_ expr: Call) -> Void {
        resolve(expr.callee)
        for argument in expr.arguments {
            resolve(argument)
        }
    }
    
    public func visit(_ expr: Get) -> Void {
        resolve(expr.object)
    }
    
    public func visit(_ expr: Set) -> Void {
        resolve(expr.value)
        resolve(expr.object)
    }
    
    public func visit(_ expr: This) -> Void {
        if currentClassType == .none {
            Lox.reportError("Can't use 'this' outside of a class", at: expr.keyword)
        }
        resolveLocal(expr, expr.keyword)
    }
    
    public func visit(_ expr: Grouping) -> Void {
        resolve(expr.expression)
    }
    
    public func visit(_ expr: Literal) -> Void {}
    
    public func visit(_ expr: Logical) -> Void {
        resolve(expr.lhs)
        resolve(expr.rhs)
    }
    
    public func visit(_ expr: Unary) -> Void {
        resolve(expr.rhs)
    }
}

extension Resolver {
    private func declare(_ name: Token) {
        if scopes.isEmpty {
            return
        }
        if scopes[scopes.endIndex - 1][name.lexeme] != nil {
            Lox.reportError("Variable with this name already declared in this scope", at: name)
        }
        scopes[scopes.endIndex - 1][name.lexeme] = false
    }
    
    private func define(_ name: Token) {
        if scopes.isEmpty {
            return
        }
        scopes[scopes.endIndex - 1][name.lexeme] = true
    }
    
    private func resolveLocal(_ expr: Expression, _ name: Token){
        for (i, scope) in zip(0 ... scopes.count, scopes).reversed() {
            if scope[name.lexeme] != nil {
                let numOfScopes = scopes.count - 1 - i
                interpreter.resolve(expr, depth: numOfScopes)
                return
            }
        }
    }
    
    private func resolveFunction(
        _ function: Function,
        type: FunctionType = .function
    ) {
        let enclosingFunctionType = currentFunctionType
        currentFunctionType = type
        defer { currentFunctionType = enclosingFunctionType }
        
        beginScope()
        for param in function.parameters {
            declare(param)
            define(param)
        }
        resolve(function.body)
        endScope()
    }
    
    private func beginScope() {
        scopes.append([:])
    }
    
    private func endScope() {
        if !scopes.isEmpty {
            scopes.removeLast()
        }
    }
    
    private enum FunctionType {
        case none, function, initializer, method
    }
    
    private enum ClassType {
        case none, `class`
    }
}
