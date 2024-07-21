//
//  LoxFunction.swift
//  
//
//  Created by Yuhao Chen on 7/15/24.
//

struct LoxFunction: Callable {
    let declaration: Function
    let closure: Environment
    let isInitializer: Bool
    
    var arity: Int {
        return declaration.parameters.count
    }
    
    init(declaration: Function,
         closure: Environment,
         isInitializer: Bool = false) {
        self.declaration = declaration
        self.closure = closure
        self.isInitializer = isInitializer
    }
    
    func call(interpreter: Interpreter, arguments: Array<Any>) -> Interpreter.Value? {
        let environment = Environment(enclosing: closure)
        
        for (i, param) in declaration.parameters.enumerated() {
            environment.define(name: param.lexeme, value: arguments[i])
        }
        
        let result = interpreter.executeBlock(statements: declaration.body, environment: environment)
        if case let .success(value) = result,
           let returnValue = value as? InterpreterReturn,
           let rawValue = returnValue.value
        {
            if isInitializer {
                do {
                    return .success(try closure.get("this", at: 0))
                } catch {
                    return .failure(
                        error as? InterpreterError ??
                        InterpreterError.runtime(
                            message: "Unknown issue occurred initializer return statement.",
                            onLine: declaration.name.line,
                            locationDescription: nil)
                    )
                }
            }
            return .success(rawValue)
        }
        
        return result
    }
    
    func binded(_ instance: LoxInstance) -> LoxFunction {
        let environment = Environment(enclosing: closure)
        environment.define(name: "this", value: instance)
        return LoxFunction(declaration: declaration, closure: environment, isInitializer: isInitializer)
    }
    
}

extension LoxFunction: CustomDebugStringConvertible {
    var debugDescription: String {
        return "<fn \(declaration.name.lexeme) >"
    }
}
