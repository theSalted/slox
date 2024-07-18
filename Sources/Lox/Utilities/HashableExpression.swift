//
//  HashableExpression.swift
//  
//
//  Created by Yuhao Chen on 7/18/24.
//

public struct HashableExpression: Hashable {
    private let expression: Expression

    init(_ expression: Expression) {
        self.expression = expression
    }

    public static func == (lhs: HashableExpression, rhs: HashableExpression) -> Bool {
        return lhs.expression === rhs.expression
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(expression))
    }
}


extension Expression {
    var hashable: HashableExpression {
        return HashableExpression(self)
    }
}
