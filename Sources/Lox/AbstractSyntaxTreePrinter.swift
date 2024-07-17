//
//  AbstractSyntaxTreePrinter.swift
//
//
//  Created by Yuhao Chen on 6/15/24.
//

import Foundation
/// An unambiguous string representation os AST nodes.
struct AbstractSyntaxTreePrinter {
    func toPrint(_ expr: Expression) -> String {
        return expr.accept(visitor: self)
    }
    
    func toPrint(_ stmt: Statement) -> String {
        return stmt.accept(visitor: self)
    }
    
    func toPrint(_ stmts: Array<Statement>) -> String {
        var print = ""
        for stmt in stmts {
            print.append(toPrint(stmt))
            print.append("\n")
        }
        return print
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
    
    private func parenthesize(name: String, parts: Any...) -> String {
            var output = ""

            output.append("(")

            output.append(name)

            for part in parts {
                output.append(" ")

                if let expr = part as? Expr {
                    output.append(expr.accept(visitor: self))
                } else if let stmt = part as? Statement {
                    output.append(stmt.accept(visitor: self))
                } else if let token = part as? Token {
                    output.append(token.lexeme)
                } else {
                    output.append(String(describing: part))
                }
            }

            output.append(")")

            return output
        }
}



extension AbstractSyntaxTreePrinter: StatementVisitor, ExpressionVisitor {
    
    // MARK: Statements
    public func visit(_ stmt: Expr) -> String {
        parenthesize(name: ";", expressions: stmt.expression)
    }
    
    public func visit(_ stmt: Function) -> String {
        var result = "(fun \(stmt.name.lexeme)"
        
        result += "("
        
        for parameter in stmt.parameters {
            result += "\(parameter.lexeme)"
        }
        
        result += ")"
        
        for body in stmt.body {
            result += body.accept(visitor: self)
        }
        
        return result
    }
    
    public func visit(_ stmt: If) -> String {
        guard let `else` = stmt.else else {
            return parenthesize(name: "if", parts: stmt.condition, stmt.then)
        }
        
        return parenthesize(name: "if-else", parts: stmt.condition, stmt.then, `else`)
    }
    
    public func visit(_ stmt: Block) -> String {
        var output = ""
        for statement in stmt.statements {
            output.append(statement.accept(visitor: self))
        }
        return "(block \(output))"
    }
    
    public func visit(_ stmt: Return) -> String {
        guard let value = stmt.value else {
            return "(return)"
        }
        return parenthesize(name: "return", parts: value)
    }
    
    public func visit(_ stmt: Var) -> String {
        guard let initializer = stmt.initializer else {
            return parenthesize(name: "var", parts: stmt.name)
        }

        return parenthesize(name: "var", parts: stmt.name, "=", initializer)
    }
    
    public func visit(_ stmt: Print) -> String {
        return parenthesize(name: "print", expressions: stmt.expression)
    }
    
    // MARK: Expressions
    public func visit(_ expr: Assignment) -> String {
        return parenthesize(name: "=", parts: expr.name.lexeme, expr.value)
    }
    
    public func visit(_ expr: Binary) -> String {
        parenthesize(name: expr.operator.lexeme, expressions: expr.lhs, expr.rhs)
    }
    
    public func visit(_ expr: Call) -> String {
        return parenthesize(name: "call", parts: expr.callee, expr.arguments)
    }
    
    public func visit(_ expr: Grouping) -> String {
        parenthesize(name: "group", expressions: expr.expression)
    }
    
    public func visit(_ expr: Literal) -> String {
        guard let value = expr.value else {
            return "nil"
        }
        return String(describing: value)
    }
    
    public func visit(_ expr: Logical) -> String {
        return "\(expr.lhs) \(expr.rhs) \(expr.operator.lexeme)"
    }
    
    public func visit(_ expr: Unary) -> String {
        parenthesize(name: expr.operator.lexeme, expressions: expr.rhs)
    }
    
    public func visit(_ expr: Variable) -> String {
        expr.name.lexeme
    }
    
    public func visit(_ stmt: While) -> String {
        parenthesize(name: "while", parts: stmt.condition, stmt.body)
    }
}
