//
//  DefinitionGenerator.swift
//
//
//  Created by Yuhao Chen on 6/15/24.
//

import ArgumentParser
import Foundation


/// Command-line interface for the SyntaxDefinitionGenerator.
@main
struct DefinitionGenerator: ParsableCommand {
    /// The path of the source JSON to generate code from.
    @Option(help: "The path of source json to generate code on", transform: { URL(filePath: $0) })
    var sourceDirectory: URL?
    
    /// The path to save the generated code.
    @Argument(help: "The path to save generated code to", transform: { URL(filePath: $0) })
    var outputDirectory: URL?
    
    /// Executes the command to generate the abstract syntax tree code.
    mutating func run() throws {
        var definitions: [Definition] = []
        if let sourceDirectory {
            let data = try Data(contentsOf: sourceDirectory)
            let decoder = JSONDecoder()
            let tree = try decoder.decode(Definition.self, from: data)
            definitions.append(tree)
        } else {
            print("--source-directory not provided, default to bundled JSONs")
            let decoder = JSONDecoder()
            if let expressionJson = Bundle.module.url(forResource: "expression", withExtension: "json") {
                let expressionData = try Data(contentsOf: expressionJson)
                let expressionTree = try decoder.decode(Definition.self, from: expressionData)
                definitions.append(expressionTree)
            }else {
                print("expression.json does not exist, please provide source JSON manually")
            }
            
            if let statementJson = Bundle.module.url(forResource: "statement", withExtension: "json") {
                let statementData = try Data(contentsOf: statementJson)
                let statementTree = try decoder.decode(Definition.self, from: statementData)
                definitions.append(statementTree)
            }else {
                print("statement.json does not exist, please provide source JSON manually")
            }
        }
        
        guard !definitions.isEmpty else {
            fatalError("No tree to be generated")
        }
        
        for definition in definitions {
            let generator = SyntaxDefinitionGenerator(definition, path: outputDirectory)
            print(String(repeating: "-", count: 5) + "\(definition.baseName).swift" + String(repeating: "-", count: 5))
            generator.writeTree()
        }
    }
}
