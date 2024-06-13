//
//  Expression.swift
//
//
//  Created by Yuhao Chen on 6/14/24.
//

import Foundation


protocol Expression {
    
}

struct Binary: Expression {
    let lhs: Expression
    let `operator`: Token
    let right: Expression
    
    init(lhs: Expression, operator: Token, right: Expression) {
        self.lhs = lhs
        self.`operator` = `operator`
        self.right = right
    }
}


