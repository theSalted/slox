//
// Statement.swift
//
//
// Generated by SyntaxDefinitionGenerator on 06/26/24
//


public protocol Statement {
    func accept<V: StatementVisitor, R>(visitor: V) -> R where R == V.StatementVisitorReturn
}

public protocol StatementVisitor {
    associatedtype StatementVisitorReturn

    func visit(_ stmt: Expr) -> StatementVisitorReturn
    func visit(_ stmt: Var) -> StatementVisitorReturn
    func visit(_ stmt: Print) -> StatementVisitorReturn
}

public struct Expr: Statement {
    let expression: Expression

    init(expression: Expression) {
        self.expression = expression
    }

    public func accept<V: StatementVisitor, R>(visitor: V) -> R where R == V.StatementVisitorReturn {
        return visitor.visit(self)
    }
}

public struct Var: Statement {
    let name: Token
    let initializer: Expression?

    init(name: Token, initializer: Expression?) {
        self.name = name
        self.initializer = initializer
    }

    public func accept<V: StatementVisitor, R>(visitor: V) -> R where R == V.StatementVisitorReturn {
        return visitor.visit(self)
    }
}

public struct Print: Statement {
    let expression: Expression

    init(expression: Expression) {
        self.expression = expression
    }

    public func accept<V: StatementVisitor, R>(visitor: V) -> R where R == V.StatementVisitorReturn {
        return visitor.visit(self)
    }
}