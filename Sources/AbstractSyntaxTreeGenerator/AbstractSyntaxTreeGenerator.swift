//
//  AbstractSyntaxTreeGenerator.swift
//
//
//  Created by Yuhao Chen on 6/14/24.
//

import Lox
import Foundation

/// Generates Swift code for an abstract syntax tree.
struct AbstractSyntaxTreeGenerator {
    let tree: Tree
    let outputDirectory: URL?
    let printer = CodePrinter()
    
    /// Initializes a new generator.
    init(_ tree: Tree, path outputDirectory: URL? = nil) {
        self.outputDirectory = outputDirectory
        self.tree = tree
    }
    
    /// Writes the tree structure to Swift code.
    func writeTree() {
        printer.addFileHeader(
            fileName: tree.baseName + ".swift",
            creatorInfo: "Generated by AbstractSyntaxTreeGenerator")
        printer.emptyLine()
        printer.emptyLine()
        printer.emptyLine()
        
        writeProtocol()
        
        printer.emptyLine()
        
        writeVisitorProtocol()
        
        printer.emptyLine()
        
        for type in tree.types {
            writeType(type.name, parameterField: type.parameterField)
            printer.emptyLine()
        }
        
        printer.save(to: outputDirectory)
    }
    
    /// Writes the base protocol for the tree.
    private func writeProtocol() {
        printer.writeLine("protocol \(tree.baseName) {")
        
        printer.indent()
        
        printer.writeLine(acceptFunctionDefinition())
        
        printer.detent()
        
        printer.writeLine("}")
    }
    
    /// Writes the code for a specific type in the tree.
    private func writeType(_ name: String, parameterField: String) {
        printer.writeLine("struct \(name): \(tree.baseName) {")
        
        let parameters = parameterField.components(separatedBy: ", ").filter({ $0.isEmpty == false })
        
        printer.indent()
        
        for parameter in parameters {
            printer.writeLine("let \(parameter)")
        }
        
        printer.emptyLine()
        
        if !parameters.isEmpty {
            printer.writeLine("init(\(parameterField)) {")
            
            printer.indent()
            
            for parameter in parameters {
                let name = parameter.components(separatedBy: ": ")[0].trimmingCharacters(in: .whitespaces)
                
                printer.writeLine("self.\(name) = \(name)")
            }
            
            printer.detent()
            
            printer.writeLine("}")
        }
        
        printer.emptyLine()
        
        printer.writeLine(acceptFunctionDefinition() + " {")
        
        printer.indent()
        
        printer.writeLine("return visitor.visit(self)")
        
        printer.detent()
        
        printer.writeLine("}")
        
        printer.detent()
        
        printer.writeLine("}")
    }
    
    /// Writes the visitor protocol for the tree.
    private func writeVisitorProtocol() {
        printer.writeLine("protocol \(visitorProtocolName()) {")
        
        printer.indent()
       
        let returnName = associatedtypeName()
        printer.writeLine("associatedtype \(returnName)")
        
        printer.emptyLine()
        
        for type in tree.types {
            printer.writeLine("func visit(_ expr: \(type.name)) -> \(returnName)")
        }
        
        printer.detent()
        
        printer.writeLine("}")
    }
    
    /// Returns the definition of the accept function for the tree's base protocol.
    private func acceptFunctionDefinition() -> String {
        return "func accept<V: \(visitorProtocolName()), R>(visitor: V) -> R where R == V.\(associatedtypeName())"
    }
    
    /// Returns the name of the associated type for the visitor protocol.
    private func associatedtypeName() -> String {
        return "\(visitorProtocolName())Return"
    }
    
    /// Returns the name of the visitor protocol for the tree.
    private func visitorProtocolName() -> String {
        return "\(tree.baseName)Visitor"
    }
}

/// Represents an abstract syntax tree.
struct Tree: Codable {
    let baseName: String
    let types: [TypeDefinition]
}

/// Represents a type definition within an abstract syntax tree.
struct TypeDefinition: Codable {
    let name: String
    let parameterField: String
    init(name: String, parameterField: String) {
        self.name = name
        self.parameterField = parameterField
    }
}
