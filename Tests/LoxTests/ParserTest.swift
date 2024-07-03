//
//  Parser.swift
//
//
//  Created by Yuhao Chen on 6/16/24.
//

import Foundation
import Testing
@testable import Lox

struct ParserTest {
    @Test("Basic expression", arguments: [
        ("1 + 2", "(+ 1.0 2.0)"),
        ("1 + 2 * 3", "(+ 1.0 (* 2.0 3.0))"),
        ("1 + 2.0 * (-2.0 + 0.555)", "(+ 1.0 (* 2.0 (group (+ (- 2.0) 0.555))))"),
        ("1 + (2 + 3) * 4 - (1 / 5.0)", "(+ 1.0 (* (group (+ 2.0 3.0)) (- 4.0 (group (/ 1.0 5.0)))))")
    ])
    func basicExpression(source: String, expectedPrint: String) {
        let tokens = Scanner(source).scanTokens()
        
        let parser = Parser(tokens: tokens)
        
        
        guard let expression = parser.parse() else {
            Issue.record("Parser failed")
            return
        }
        
        let printer = AbstractSyntaxTreePrinter()
        
        let result = printer.toPrint(expression)
        
        #expect(!Lox.hadError)
        
        #expect(result == expectedPrint)
    }
}
