// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation

@main
struct Slox: ParsableCommand {
    @Argument(help: "The path to operate on")
    var path: String?
    
    mutating func run() throws {
        if let path {
            try Slox.runFile(path)
        } else {
            try Lox.runPrompt()
        }
    }
    
    private static func runFile(_ path: String) throws {
        let url = URL(filePath: path)
        let code = try String(contentsOf: url)
        print(code)
        Lox.runCode(code)
    }
}
