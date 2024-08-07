//
//  LoxInstance.swift
//  
//
//  Created by Yuhao Chen on 7/20/24.
//

class LoxInstance {
    private let `class`: LoxClass
    private var fields = Dictionary<String, Interpreter.Value>()
    
    init(_ `class`: LoxClass) {
        self.class = `class`
    }
    
    func get(_ name: Token) -> Interpreter.Value {
        if let field = fields[name.lexeme] {
            return field
        }
        
        if let method = `class`.findMethod(name: name.lexeme) {
            let test = method.binded(self)
            return .success(test)
        }
        
        return .failure(InterpreterError.runtime(
            message: "Undefined property '\(name.lexeme)'", onLine: name.line, locationDescription: nil))
    }
    
    func set(_ name: Token, value: Interpreter.Value) {
        fields[name.lexeme] = value
    }
}

extension LoxInstance: CustomDebugStringConvertible {
    var debugDescription: String {
        return  "< \(self.class.name) instance>"
    }
}
