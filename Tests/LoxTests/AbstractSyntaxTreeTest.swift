//
//  File.swift
//  
//
//  Created by Yuhao Chen on 6/15/24.
//

import Testing
@testable import Lox

struct AbstractSyntaxTreeTest {
    @Test("Basic print that covers Unary Literal and Grouping")
    func basicPrint() {
        let minusOneExpr = Unary(
            operator: .init(.bang, lexeme: "-", literal: nil, line: 1),
            rhs: Literal(value: 123))
        let groupingExpr = Grouping(
            expression: Literal(value: 45.67))
        let expression = Binary(
            lhs: minusOneExpr,
            operator: .init(.star, lexeme: "*", literal: nil, line: 1),
            rhs: groupingExpr)
        
        let printer = AbstractSyntaxTreePrinter()
        let result = printer.toPrint(expression)
        #expect(result == "(* (- 123) (group 45.67))")
    }
}
