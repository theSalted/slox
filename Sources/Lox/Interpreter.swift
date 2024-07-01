//
//  Interpreter.swift
//  
//
//  Created by Yuhao Chen on 6/19/24.
//

import OSLog

public final class Interpreter: StatementVisitor, ExpressionVisitor {
    private var environment = Environment()
    
    func interpret(_ statements: Array<Statement>) {
        for statement in statements {
            let result = execute(statement)
            if case let .failure(error) = result {
                Lox.reportError(error)
            }
        }
    }
    
    func intercept(_ expr: Expression) {
        switch evaluate(expr) {
        case .success(let result):
            print(toString(result))
        case .failure(let error):
            Lox.reportError(error)
        case .none:
            break
        }
    }
    
    // MARK: Statements
    public func visit(_ stmt: Expr) -> Value? {
        switch evaluate(stmt.expression) {
            
        case .success(_), .none:
            return nil
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func visit(_ stmt: If) -> Value? {
        if determineTruthy(evaluate(stmt.condition)) {
            if case .failure(let error) = execute(stmt.then) {
                return .failure(error)
            }
        } else if let `else` = stmt.else {
            if case .failure(let error) = execute(`else`) {
                return .failure(error)
            }
        }
        
        return nil
    }
    
    public func visit(_ stmt: Block) -> Value? {
        let result = executeBlock(statements: stmt.statements, environment: Environment(enclosing: environment))
        return result
    }
    
    public func visit(_ stmt: Var) -> Value? {
        let value: Any
        if let initializer = stmt.initializer {
            let result = evaluate(initializer)
            switch result {
            case .success(let res):
                value = res
            case .failure(let error):
                return .failure(error)
            case .none:
                return .failure(InterpreterError.runtime(
                    message: "variable must be initialized",
                    onLine: stmt.name.line,
                    locationDescription: nil
                ))
                /* return NilAny */
            }
        } else {
            return .failure(InterpreterError.runtime(
                message: "variable must be initialized",
                onLine: stmt.name.line,
                locationDescription: nil
            ))
            /* return NilAny */
        }
        
        environment.define(name: stmt.name.lexeme, value: value)
        return .success(value)
    }
    
    public func visit(_ stmt: Print) -> Value? {
        switch evaluate(stmt.expression) {
            
        case .success(let value):
            print(toString(value))
            return nil
        case .failure(let error):
            return .failure(error)
        case .none:
            print(toString(nil))
            return nil
        }
    }
    
    // MARK: Expressions
    public func visit(_ expr: Assignment) -> Value? {
        let result = evaluate(expr.value)
        let name = expr.name
        let value: Any
        switch result {
            
        case .success(let _value):
            value = _value
        case .failure(let error):
            return .failure(error)
        case .none:
            return .failure(
                InterpreterError.runtime(
                    message: "Assignment can't be resolved",
                    onLine: name.line,
                    locationDescription: nil))
        }
        do { try environment.assign(name: expr.name, value: value) }
        catch {
            return .failure(error as? InterpreterError ??
                            InterpreterError.runtime(
                                message: "Undefined variable '\(name.lexeme)'.", 
                                onLine: name.line,
                                locationDescription: nil))
        }
        return .success(value)
    }
    
    public func visit(_ expr: Binary) -> Value? {
        // MARK: Preparing operands, and operator
        let `operator` = expr.operator
        let line = `operator`.line

        let lhs = evaluate(expr.lhs)
        let rhs = evaluate(expr.rhs)
        
        switch `operator`.type {
        case .bangEqual:
            return .success(!determineEqualish(lhs, rhs))
        case .equalEqual:
            return .success(determineEqualish(lhs, rhs))
        default:
            break
        }

        guard let lhs, let rhs else {
            logger.error("Operand returned nil after evaluation")
            return .failure(
                InterpreterError
                    .runtime(message: "Operand can't be evaluated", 
                             onLine: `operator`.line, 
                             locationDescription: nil))
        }

        // If either lhs or rhs are failures,
        guard case let .success(lhs) = lhs else {
            return lhs
        }

        guard case let .success(rhs) = rhs else {
            return rhs
        }
        
        // Handle Double type
        if let lhs = lhs as? Double, let rhs = rhs as? Double {
            switch `operator`.type {
            case .minus:
                return .success(lhs - rhs)
            case .slash:
                return .success(lhs / rhs)
            case .star:
                return .success(lhs * rhs)
            case .plus:
                return .success(lhs + rhs)
            case .greater:
                return .success(lhs > rhs)
            case .greaterEqual:
                return .success(lhs >= rhs)
            case .less:
                return .success(lhs < rhs)
            case .lessEqual:
                return .success(lhs <= rhs)
            default:
                break
            }
        }
        
        // Handle String type
        if let lhs = lhs as? String, let rhs = rhs as? String {
            switch `operator`.type {
            case .plus:
                return .success(lhs + rhs)
            default:
                break
            }
        }
        
        return .failure(InterpreterError.runtime(
            message: "An internal error occurred - \(`operator`.type.rawValue) is not an unary, please submit a report",
            onLine: line,
            locationDescription: "at \(`operator`.lexeme)"
        ))
    }
    
    public func visit(_ expr: Grouping) -> Value? {
        evaluate(expr.expression)
    }
    
    public func visit(_ expr: Literal) -> Value? {
        guard let value = expr.value else {
            return nil
        }
        return .success(value)
    }
    
    public func visit(_ expr: Logical) -> Value? {
        let lhs = evaluate(expr.lhs)
        
        if expr.operator.type == TokenType.or {
            if determineTruthy(lhs) { return lhs }
        } else {
            if !determineTruthy(lhs) { return lhs }
        }
        
        return evaluate(expr.rhs)
    }
    
    public func visit(_ expr: Unary) -> Value? {
        let `operator` = expr.operator
        let line = `operator`.line
        let rhs = evaluate(expr.rhs)
        
        guard case let .success(rhs) = rhs else {
            return rhs
        }
        
        switch `operator`.type {
        case .bang:
            return .success(!determineTruthy(rhs))
        case .minus:
            guard let rhs = rhs as? Double else {
                return.failure(InterpreterError.runtime(message: "Operand must be number", onLine: line))
            }
            return .success(-rhs)
        default:
            return .failure(InterpreterError.runtime(
                message: "\(`operator`.type.rawValue) is not an unary",
                onLine: line,
                locationDescription: "at \(`operator`.lexeme)"))
        }
    }
    
    public func visit(_ expr: Variable) -> Value? {
        let name = expr.name
        if let value = try? environment.get(name) {
            return .success(value)
        } else {
            return .failure(InterpreterError.runtime(
                                message: "Undefined variable '\(name.lexeme)'.",
                                onLine: name.line,
                                locationDescription: nil))
        }
    }
    
    public func visit(_ stmt: While) -> Value? {
        while determineTruthy(evaluate(stmt.condition)) {
            
            if case .failure(let error) = execute(stmt.body) {
                return .failure(error)
            }
        }
        return nil
    }
    
    public typealias Value = Result<Any, InterpreterError>
    public typealias ExpressionVisitorReturn = Value?
    public typealias StatementVisitorReturn = Value?
}

extension Interpreter {
    private func execute(_ stmt: Statement) -> Value? {
        let value = stmt.accept(visitor: self)
        return value
    }
    
    private func executeBlock(statements: Array<Statement>, environment: Environment) -> Value? {
        let previous = self.environment
        self.environment = environment
        
        defer {
            self.environment = previous
        }
        
        for statement in statements {
            let result = execute(statement)
            if case let .failure(error) = result {
                return .failure(error)
            }
        }
        
        return nil
    }
    
    private func evaluate(_ expr: Expression) -> Value? {
        return expr.accept(visitor: self)
    }
    
    private func toString(_ value: Any?) -> String {
        guard let value = value else { return "nil" }

        // Hack. Work around Swift adding ".0" to integer-valued doubles.
        if value is Double {
            var text = String(describing: value)
            if text.hasSuffix(".0") {
                text = String(text[..<text.index(text.endIndex, offsetBy: -2)])
            }
            return text
        }

        return String(describing: value)
    }
    
    private func determineEqualish(_ lhs: Value?, _ rhs: Value?) -> Bool {
        if lhs == nil && rhs == nil {
            return true
        }
        guard let lhs, let rhs else {
            return false
        }
        
        guard case let .success(lhs) = lhs else {
            return false
        }

        guard case let .success(rhs) = rhs else {
            return false
        }
        
        if let lhs = lhs as? String, let rhs = rhs as? String {
            return lhs == rhs
        }

        if let lhs = lhs as? Bool, let rhs = rhs as? Bool {
            return lhs == rhs
        }

        if let lhs = lhs as? Double, let rhs = rhs as? Double {
            return lhs == rhs
        }
            
        guard type(of: lhs) == type(of: rhs) else {
            return false
        }
        
        return false
    }
    
    private func determineTruthy(_ value: Value?) -> Bool {
        if value == nil {
            return false
        }
        
        switch value {
        case .success(let object):
            return determineTruthy(object)
        default:
            return false
        }
    }
    
    private func determineTruthy(_ object: Any?) -> Bool {
        if object == nil {
            return false
        }
        if let boolean = object as? Bool {
            return boolean
        }
        return true
    }
}

public enum InterpreterError: Error {
    case runtime(message: String, onLine: Int, locationDescription: String? = nil)
}

fileprivate let logger = Logger(subsystem: "Lox", category: "Interpreter")
