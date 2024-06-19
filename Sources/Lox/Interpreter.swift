//
//  Interpreter.swift
//  
//
//  Created by Yuhao Chen on 6/19/24.
//

import OSLog

public final class Interpreter: ExpressionVisitor {
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
    
    func visit(_ expr: Binary) -> Value? {
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
            return .failure(InterpreterError.runtime(message: "Operand can't be evaluated", onLine: `operator`.line, locationDescription: nil))
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
    
    func visit(_ expr: Grouping) -> Value? {
        evaluate(expr.expression)
    }
    
    func visit(_ expr: Literal) -> Value? {
        guard let value = expr.value else {
            return nil
        }
        return .success(value)
    }
    
    func visit(_ expr: Unary) -> Value? {
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
    
    typealias Value = Result<Any, InterpreterError>
    typealias ExpressionVisitorReturn = Value?
}

extension Interpreter {
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

    private func evaluate(_ expr: Expression) -> Value? {
        return expr.accept(visitor: self)
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
