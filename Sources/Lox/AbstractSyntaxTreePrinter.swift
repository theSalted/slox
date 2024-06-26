//
//  AbstractSyntaxTreePrinter.swift
//
//
//  Created by Yuhao Chen on 6/15/24.
//

import Foundation

/// An unambiguous string representation os AST nodes.
public struct AbstractSyntaxTreePrinter: ExpressionVisitor {
    
    func toString(expr: Expression) -> String {
        return expr.accept(visitor: self)
    }
    
    public func visit(_ expr: Literal) -> String {
        guard let value = expr.value else {
            return "nil"
        }
        return String(describing: value)
    }
    
    public func visit(_ expr: Binary) -> String {
        return parenthesize(name: expr.operator.lexeme, expressions: expr.lhs, expr.rhs)
    }
    
    public func visit(_ expr: Grouping) -> String {
        return parenthesize(name: "group", expressions: expr.expression)
    }
    
    public func visit(_ expr: Unary) -> String {
        parenthesize(name: expr.operator.lexeme, expressions: expr.rhs)
    }
    
    public func parenthesize(name: String, expressions: Expression...) -> String {
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
