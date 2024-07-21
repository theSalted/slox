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
        guard let initializer = findMethod(name: "init") else {
            return 0
        }
        return initializer.arity
    }
    
    func call(interpreter: Interpreter, arguments: Array<Any>) -> Interpreter.Value? {
        let instance = LoxInstance(self)
        
        if let initializer = findMethod(name: "init") {
            let result = initializer
                .binded(instance)
                .call(interpreter: interpreter, arguments: arguments)
            
            if case let .failure(error) = result {
                return .failure(error)
            }
        }
        
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
