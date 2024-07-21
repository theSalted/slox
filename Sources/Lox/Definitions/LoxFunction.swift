//
//  LoxFunction.swift
//  
//
//  Created by Yuhao Chen on 7/15/24.
//

struct LoxFunction: Callable {
    let declaration: Function
    let closure: Environment
    
    var arity: Int {
        return declaration.parameters.count
    }
    
    init(declaration: Function, closure: Environment) {
        self.declaration = declaration
        self.closure = closure
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
            return .success(rawValue)
        }
        
        return result
    }
    
    func binded(_ instance: LoxInstance) -> LoxFunction {
        let environment = Environment(enclosing: closure)
        environment.define(name: "this", value: instance)
        return LoxFunction(declaration: declaration, closure: environment)
    }
    
}

extension LoxFunction: CustomDebugStringConvertible {
    var debugDescription: String {
        return "<fn \(declaration.name.lexeme) >"
    }
}
