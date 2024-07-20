//
//  LoxClass.swift
//  
//
//  Created by Yuhao Chen on 7/20/24.
//

struct LoxClass: Callable {
    let name: String
    
    init(_ name: String) {
        self.name = name
    }
    
    var arity: Int {
        return 0
    }
    
    func call(interpreter: Interpreter, arguments: Array<Any>) -> Interpreter.Value? {
        let instance = LoxInstance(self)
        
        return .success(instance)
    }
}


extension LoxClass: CustomDebugStringConvertible {
    var debugDescription: String {
        return name
    }
}
