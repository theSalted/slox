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
    @Test
    func basicExpression() {
        let tokens = Scanner("1 + 2.0 * (-2.0 + 0.555) ").scanTokens()
        
        let parser = Parser(tokens: tokens)
        
        
        guard let expression = parser.parse() else {
            Issue.record("Parser failed")
            return
        }
        
        
        let printer = AbstractSyntaxTreePrinter()
        
        let result = printer.toString(expr: expression)
        
        #expect(!Lox.hadError)
        
        #expect(result == "(+ 1.0 (* 2.0 (group (+ (- 2.0) 0.555))))")
    }
}
