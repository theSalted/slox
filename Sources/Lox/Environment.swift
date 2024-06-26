//
//  Environment.swift
//  
//
//  Created by Yuhao Chen on 6/27/24.
//

/// This is a hack to make Swift useful when working with Any and Optional.
/// You can't know, not even at runtime, if an Any is an Optional (it always says yes).
/// So to store Any (including nil) in the environment we just use Any instead of Any? and use this value
/// to denote nil.
/// Otherwise you start having Optional nested many times that will break the stringify output and probably
/// any other execution that tries to use it.
///
/// Source: alexito4/slox/
let NilAny: Any = Optional<Any>.none as Any

public final class Environment {
    private var values = Dictionary<String, Any>()
    
    func define(name: String, value: Any) {
        assert(!(value is Result<Any, InterpreterError>), "You should not store a result, please store its value instead")
        values[name] = value
    }
    
    func get(_ name: Token) throws -> Any {
        if values.contains(where: { key, value in key == name.lexeme }) {
            if let unwrapped = values[name.lexeme] {
                return unwrapped
            }
            return NilAny
        }
        
        throw InterpreterError.runtime(message: "Undefined variable \(name.lexeme).", onLine: name.line, locationDescription: nil)
    }
}
