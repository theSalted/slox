//
//  Callable.swift
//  
//
//  Created by Yuhao Chen on 7/13/24.
//

protocol Callable {
    var arity: Int { get }
    func call(interpreter: Interpreter, arguments: Array<Any>) -> Interpreter.Value?
}

struct NativeFunction: Callable {
    let arity: Int
    let callAction: (Interpreter, Array<Any>) -> Interpreter.Value?
    
    init(arity: Int, call callAction: @escaping (Interpreter, Array<Any>) -> Interpreter.Value?) {
        self.arity = arity
        self.callAction = callAction
    }
    
    init(call callAction: @escaping (Interpreter) -> Interpreter.Value?) {
        self.arity = 0
        self.callAction = { interpreter, _ in callAction(interpreter) }
    }
    
    func call(interpreter: Interpreter, arguments: Array<Any>) -> Interpreter.Value? {
        return callAction(interpreter, arguments)
    }
}
