//
//  Lox.swift
//
//
//  Created by Yuhao Chen on 6/10/24.
//

import Foundation

/// A structure representing the Lox interpreter.
public struct Lox {
    
    /// Runs the interpreter on the given source code.
    /// - Parameter source: The source code to run.
    public static func run(_ source: String) {
        let scanner = Scanner(source)
        let tokens = scanner.scanTokens()
        for token in tokens { print(token) }
    }
    
    /// Runs the interpreter on the given code string.
    /// - Parameter code: The code string to run.
    public static func runCode(_ code: String) {
        run(code)
        
        if hadError {
            exit(65)
        }
    }
    
    /// Runs the interpreter in interactive prompt mode.
    /// This method will continually prompt the user for input until the program is terminated.
    public static func runPrompt() throws {
        while true {
            print("> ", terminator: "")
            guard let code = readLine() else { continue }
            run(code)
            
            hadError = false
        }
    }
    
    // - MARK: Error handling properties
    
    /// Indicates whether an error has occurred during interpretation.
    static var hadError = false
    
    // - MARK: Error handling
    
    /// Reports an error with optional location information.
    /// - Parameters:
    ///   - message: The error message.
    ///   - where: The location description where the error occurred.
    ///   - line: The line number where the error occurred.
    static func reportError(_ message: String, at where: String? = nil, on line: Int) {
        var stderr = FileHandle.standardError
        var whereText = ""
        if let `where` {
            whereText = " \(`where`)"
        }
        print("[line \(line)] Error\(whereText): \(message)", to: &stderr)
        hadError = true
    }
    
    static func reportError(_ message: String, token: Token) {
        if token.type == .eof {
            reportError(message, at: " at end", on: token.line)
        } else {
            reportError(message, at: " at \(token.lexeme)", on: token.line)
        }
    }
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        write(data)
    }
}
