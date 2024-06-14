//
//  AbstractSyntaxTreePrinter.swift
//
//
//  Created by Yuhao Chen on 6/15/24.
//

import Foundation

/// An unambiguous string representation os AST nodes.
struct AbstractSyntaxTreePrinter: ExpressionVisitor {
    func print(expr: Expression) -> String {
        return expr.accept(visitor: self)
    }
    
    func visit(_ expr: Binary) -> String {
        return parenthesize(name: expr.operator.lexeme, expressions: expr.lhs, expr.rhs)
    }
    
    private func parenthesize(name: String, expressions: Expression...) -> String {
        var output = ""
        
        output.append("(\(name)")
        
        for expression in expressions {
            output.append(" ")
            output.append(expression.accept(visitor: self))
        }
        
        output.append(")")
        
        return output
    }
}
