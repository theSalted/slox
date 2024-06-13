// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Lox

@main
struct Slox: ParsableCommand {
    @Argument(help: "The path to operate on", transform: { URL(filePath: $0) })
    var path: URL?
    
    mutating func run() throws {
        if let path {
            try Slox.runFile(path)
        } else {
            try Lox.runPrompt()
//            try Lox.runPrompt()
        }
    }
    
    private static func runFile(_ path: URL) throws {
        let code = try String(contentsOf: path)
        print(code)
        Lox.runCode(code)
//        Lox.runCode(code)
    }
}
