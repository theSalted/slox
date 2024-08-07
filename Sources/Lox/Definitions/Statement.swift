//
// Statement.swift
//
//
// Generated by SyntaxDefinitionGenerator on 07/22/24
//


public protocol Statement {
    func accept<V: StatementVisitor, R>(visitor: V) -> R where R == V.StatementVisitorReturn
}

public protocol StatementVisitor {
    associatedtype StatementVisitorReturn

    func visit(_ stmt: Expr) -> StatementVisitorReturn
    func visit(_ stmt: Function) -> StatementVisitorReturn
    func visit(_ stmt: If) -> StatementVisitorReturn
    func visit(_ stmt: Block) -> StatementVisitorReturn
    func visit(_ stmt: Class) -> StatementVisitorReturn
    func visit(_ stmt: LoxReturn) -> StatementVisitorReturn
    func visit(_ stmt: Var) -> StatementVisitorReturn
    func visit(_ stmt: While) -> StatementVisitorReturn
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

public struct Function: Statement {
    let name: Token
    let parameters: Array<Token>
    let body: Array<Statement>

    init(name: Token, parameters: Array<Token>, body: Array<Statement>) {
        self.name = name
        self.parameters = parameters
        self.body = body
    }

    public func accept<V: StatementVisitor, R>(visitor: V) -> R where R == V.StatementVisitorReturn {
        return visitor.visit(self)
    }
}

public struct If: Statement {
    let condition: Expression
    let then: Statement
    let `else`: Statement?

    init(condition: Expression, then: Statement, `else`: Statement?) {
        self.condition = condition
        self.then = then
        self.`else` = `else`
    }

    public func accept<V: StatementVisitor, R>(visitor: V) -> R where R == V.StatementVisitorReturn {
        return visitor.visit(self)
    }
}

public struct Block: Statement {
    let statements: Array<Statement>

    init(statements: Array<Statement>) {
        self.statements = statements
    }

    public func accept<V: StatementVisitor, R>(visitor: V) -> R where R == V.StatementVisitorReturn {
        return visitor.visit(self)
    }
}

public struct Class: Statement {
    let name: Token
    let superclass: Variable?
    let methods: Array<Function>

    init(name: Token, superclass: Variable?, methods: Array<Function>) {
        self.name = name
        self.superclass = superclass
        self.methods = methods
    }

    public func accept<V: StatementVisitor, R>(visitor: V) -> R where R == V.StatementVisitorReturn {
        return visitor.visit(self)
    }
}

public struct LoxReturn: Statement {
    let keyword: Token
    let value: Expression?

    init(keyword: Token, value: Expression?) {
        self.keyword = keyword
        self.value = value
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

public struct While: Statement {
    let condition: Expression
    let body: Statement

    init(condition: Expression, body: Statement) {
        self.condition = condition
        self.body = body
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
