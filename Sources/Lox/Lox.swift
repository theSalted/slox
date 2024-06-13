//
//  File.swift
//  
//
//  Created by Yuhao Chen on 6/10/24.
//

import Foundation

public struct Lox {
    public static func run(_ source: String) {
        let scanner = Scanner(source)
        let tokens = scanner.scanTokens()
        for token in tokens { print(token) }
    }
    
    public static func runCode(_ code: String) {
        run(code)
        
        if hadError {
            exit(65)
        }
    }
    
    public static func runPrompt() throws {
        while true {
            print("> ", terminator: "")
            guard let code = readLine() else { continue }
            run(code)
            
            hadError = false
        }
    }
    
    // - MARK: Error handling properties
    static var hadError = false
    
    // - MARK: Error handling
    static func error(_ message: String, on line: Int) {
        report(message, on: line)
    }
    
    private static func report(_ message: String, at where: String? = nil, on line: Int) {
        var stderr = FileHandle.standardError
        var whereText = ""
        if let `where` {
            whereText = " \(`where`)"
        }
        print("[line \(line)] Error\(whereText): \(message)", to: &stderr)
        hadError = true;
    }
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        write(data)
    }
}
