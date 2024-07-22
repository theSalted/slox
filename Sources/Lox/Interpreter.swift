//
//  Interpreter.swift
//  
//
//  Created by Yuhao Chen on 6/19/24.
//

import OSLog

public final class Interpreter: StatementVisitor, ExpressionVisitor {
    var globals = Environment()
    private var environment: Environment
    private var locals: Dictionary<HashableExpression, Int> = [:]
    
    init() {
        environment = globals
        
        globals.define(name: "clock", value: NativeFunction { _ in
            return .success(Double(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000)
        })
    }
    
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
        case .failure(let error):
            Lox.reportError(error)
        default:
            break
        }
    }
    
    // MARK: Statements
    public func visit(_ stmt: Expr) -> Value? {
        switch evaluate(stmt.expression) {
            
        case .success(_), .none:
            return .success(NilAny)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func visit(_ stmt: Function) -> Value? {
        let function = LoxFunction(declaration: stmt, closure: environment)
        environment.define(name: stmt.name.lexeme, value: function)
        return .success(NilAny)
    }
    
    public func visit(_ stmt: If) -> Value? {
        if determineTruthy(evaluate(stmt.condition)) {
            let result = execute(stmt.then)
            
            switch result {
            case .success(let value) where value is InterpreterReturn:
                return .success(value)
            case .failure(let error):
                return .failure(error)
            default: break
            }
        } else if let `else` = stmt.else {
            let result = execute(`else`)
            
            switch result {
            case .success(let value) where value is InterpreterReturn:
                return .success(value)
            case .failure(let error):
                return .failure(error)
            default: break
            }
        }
        
        return .success(NilAny)
    }
    
    public func visit(_ stmt: Block) -> Value? {
        let result = executeBlock(statements: stmt.statements, environment: Environment(enclosing: environment))
        return result
    }
    
    public func visit(_ stmt: Class) -> Value? {
        environment.define(name: stmt.name.lexeme, value: NilAny)
        
        // Construct inheritance
        var superclass: LoxClass? = nil
        if let superclassVariable = stmt.superclass {
            switch evaluate(superclassVariable) {
            case .success(let value):
                guard let `class` = value as? LoxClass else {
                    return .failure(InterpreterError.runtime(
                        message: "Superclass must be a class",
                        onLine: superclassVariable.name.line,
                        locationDescription: nil))
                }
                superclass = `class`
                
                environment = Environment(enclosing: environment)
                environment.define(name: "super", value: value)
                
            case .failure(let error):
                return .failure(error)
            case .none:
                return .failure(InterpreterError.runtime(
                    message: "Superclass evaluated to nil",
                    onLine: superclassVariable.name.line,
                    locationDescription: nil))
            }
            
        }
        
        // Construct methods
        var methods = Dictionary<String, LoxFunction>()
        
        for method in stmt.methods {
            let function = LoxFunction(declaration: method, closure: environment, isInitializer: method.name.lexeme == "init")
            methods[method.name.lexeme] = function
        }
        
        // Class assembly
        let `class` = LoxClass(stmt.name.lexeme, superclass: superclass, methods: methods)
        do {
            try environment.assign(name: stmt.name, value: `class`)
            
            if superclass != nil {
                guard let enclosing = environment.enclosing else {
                    throw InterpreterError.runtime( /*This should never happen*/
                        message: "Something went wrong while declaring your class with proper environment",
                        onLine: stmt.name.line,
                        locationDescription: nil)
                }
                
                environment = enclosing
            }
        }
        catch { return .failure(
            error as? InterpreterError ??
            InterpreterError.runtime( /*This should never happen*/
                message: "Something went wrong while declaring your class",
                onLine: stmt.name.line,
                locationDescription: nil)
        )}
        
        return .success(NilAny)
    }
    
    public func visit(_ stmt: LoxReturn) -> Value? {
        guard let value = stmt.value, let evaluatedValue = evaluate(value)
        else { return .success(InterpreterReturn(NilAny)) }
        
        if case let .failure(error) = evaluatedValue {
            return .failure(error)
        }
        
        guard case let .success(extractedValue) = evaluatedValue
        else { return .success(InterpreterReturn(NilAny)) }
        
        return .success(InterpreterReturn(extractedValue))
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
                    message: "Variable must be initialized",
                    onLine: stmt.name.line,
                    locationDescription: nil
                ))
                /* return NilAny */
            }
        } else {
            return .failure(InterpreterError.runtime(
                message: "Variable must be initialized",
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
            return .success(NilAny)
        case .failure(let error):
            return .failure(error)
        case .none:
            print(toString(nil))
            return .success(NilAny)
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
                    message: "Expression after = must not be nil",
                    onLine: name.line,
                    locationDescription: nil))
        }
        
        if let distance = locals[expr.hashable] {
            do { try environment.assign(
                name: expr.name,
                value: value,
                at: distance)}
            catch { return .failure(
                error as? InterpreterError ??
                InterpreterError.runtime(
                    message: "Something went wrong while assigning variable '\(name.lexeme)' to environment.",
                    onLine: name.line,
                    locationDescription: nil)
                )}
        } else {
            do { try globals.assign(
                name: expr.name,
                value: value)}
            catch { return .failure(
                error as? InterpreterError ??
                InterpreterError.runtime(
                    message: "Something went wrong while assigning variable '\(name.lexeme)' to environment.",
                    onLine: name.line,
                    locationDescription: nil)
                )}
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
    
    public func visit(_ expr: Call) -> Value? {
        let calleeResult = evaluate(expr.callee)
            
        if case .failure(_) = calleeResult {
            // If calleeResult already has an error, propagate this one instead of creating a new one in the next lines.
            // Is probably a "variable not found" error because the function hasn't been declared yet.
            return calleeResult
        }
        
        guard case let .success(callee) = calleeResult, let function = callee as? Callable else {
            return .failure(InterpreterError.runtime(
                message: "Can only call functions and classes",
                onLine: expr.paren.line, locationDescription: nil))
        }

        var evaluatedArguments: Array<Any> = []
        
        for argument in expr.arguments {
            let result = evaluate(argument)
            guard case let .success(value) = result else {
                return result
            }
            evaluatedArguments.append(value)
        }
        
        guard evaluatedArguments.count == function.arity else {
            return .failure(InterpreterError.runtime(
                message: "Expected \(function.arity) arguments but got \(evaluatedArguments.count).", onLine: expr.paren.line, locationDescription: nil))
        }
        
        return function.call(interpreter: self, arguments: evaluatedArguments)
    }
    
    public func visit(_ expr: Get) -> Value? {
        let evaluatedObject = evaluate(expr.object)
        
        let object: Any
        
        switch evaluatedObject {
        case .success(let value):
            object = value
        case .failure(let error):
            return .failure(error)
        case .none:
            return .failure(InterpreterError.runtime(
                message: "Object evaluated to nil.",
                onLine: expr.name.line,
                locationDescription: nil))
        }
        
        guard let instance = object as? LoxInstance else {
            return .failure(InterpreterError.runtime(
                message: "Only instances have properties.",
                onLine: expr.name.line,
                locationDescription: nil))
        }
        
        let field = instance.get(expr.name)
        return field
    }
    
    public func visit(_ expr: Set) -> Value? {
        let object = evaluate(expr.object)
        
        let objectValue: Any
        switch object {
        case .success(let value):
            objectValue = value
        case .failure(let error):
            return .failure(error)
        case .none:
            return .failure(InterpreterError.runtime(message: "Object evaluated to nil.", onLine: expr.name.line, locationDescription: nil))
        }
        
        guard let instance = objectValue as? LoxInstance else {
            return .failure(InterpreterError.runtime(message: "Only instances have filed.", onLine: expr.name.line, locationDescription: nil))
        }
        
        let value: Value
        switch evaluate(expr.value) {
        case .success(let result):
            value = .success(result)
        case .failure(let error):
            return .failure(error)
        case .none:
            value = .success(NilAny)
        }
        
        instance.set(expr.name, value: value)
        return .success(value)
    }
    
    public func visit(_ expr: Super) -> Value? {
        guard let distance = locals[expr.hashable] else {
            return .failure(InterpreterError.runtime(
                message: "Can't find '\(TokenType.super.rawValue)' in environment.", onLine: expr.keyword.line, locationDescription: nil))
        }
        
        guard let superclass = try? environment.get("\(TokenType.super.rawValue)", at: distance) as? LoxClass else {
            return .failure(InterpreterError.runtime(
                message: "'\(TokenType.super.rawValue)' must be a class.", onLine: expr.keyword.line, locationDescription: nil))
        }
        
        guard let object = try? environment.get("\(TokenType.this.rawValue)", at: distance - 1) as? LoxInstance else {
            return .failure(InterpreterError.runtime(
                message: "'\(TokenType.super.rawValue)' must be an instance.", onLine: expr.keyword.line, locationDescription: nil))
        }
        
        guard let method = superclass.findMethod(name: expr.method.lexeme) else {
            return .failure(InterpreterError.runtime(
                message: "Undefined property'\(expr.method.lexeme)'.", onLine: expr.method.line, locationDescription: nil))
        }
        
        return .success(method.binded(object))
    }
    
    public func visit(_ expr: This) -> Value? {
        do {
            let value = try lookUpVariable(expr.keyword, expr: expr)
            return .success(value)
        } catch {
            return .failure(
                error as? InterpreterError ??
                InterpreterError.runtime(
                    message: "Something went wrong while looking up variable",
                    onLine: expr.keyword.line,
                    locationDescription: nil)
            )
        }
    }
    
    public func visit(_ expr: Grouping) -> Value? {
        evaluate(expr.expression)
    }
    
    public func visit(_ expr: Literal) -> Value? {
        guard let value = expr.value else {
            return .success(NilAny)
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
        if let value = try? lookUpVariable(name, expr: expr) {
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
        return .success(NilAny)
    }
    
    public typealias Value = Result<Any, InterpreterError>
    public typealias ExpressionVisitorReturn = Value?
    public typealias StatementVisitorReturn = Value?
}

extension Interpreter {
    
    func resolve(_ expr: Expression, depth: Int) {
        locals[expr.hashable] = depth
    }
    
    func executeBlock(statements: Array<Statement>, environment: Environment) -> Value? {
        let previous = self.environment
        self.environment = environment
        
        defer { self.environment = previous }
        
        for statement in statements {
            let result = execute(statement)
            switch result {
            case .success(let value) where value is InterpreterReturn:
                return .success(value)
            case .failure(let error):
                return .failure(error)
            default:
                break
            }
        }
        return .success(NilAny)
    }
    
    private func execute(_ stmt: Statement) -> Value? {
        let value = stmt.accept(visitor: self)
        return value
    }
    
    private func evaluate(_ expr: Expression) -> Value? {
        return expr.accept(visitor: self)
    }
    
    private func lookUpVariable(_ name: Token, expr: Expression) throws -> Any {
        if let distance = locals[expr.hashable] {
            return try environment.get(name, at: distance)
        } else {
            return try globals.get(name)
        }
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
}

public struct InterpreterReturn {
    let value: Any?
    
    init(_ value: Any?) {
        self.value = value
    }
    
    init() {
        self.value = nil
    }
    
}

public enum InterpreterError: Error {
    case runtime(message: String, onLine: Int, locationDescription: String? = nil)
}

fileprivate let logger = Logger(subsystem: "Lox", category: "Interpreter")
