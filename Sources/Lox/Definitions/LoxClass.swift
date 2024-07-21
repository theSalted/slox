//
//  LoxClass.swift
//  
//
//  Created by Yuhao Chen on 7/20/24.
//

struct LoxClass: Callable {
    let name: String
    let methods: Dictionary<String, LoxFunction>
    
    init(_ name: String, methods: Dictionary<String, LoxFunction>) {
        self.name = name
        self.methods = methods
    }
    
    var arity: Int {
        return 0
    }
    
    func call(interpreter: Interpreter, arguments: Array<Any>) -> Interpreter.Value? {
        let instance = LoxInstance(self)
        
        return .success(instance)
    }
    
    func findMethod(name: String) -> LoxFunction? {
        return methods[name]
    }
}


extension LoxClass: CustomDebugStringConvertible {
    var debugDescription: String {
        return name
    }
}
