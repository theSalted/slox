//
//  TreeGenerator.swift
//
//
//  Created by Yuhao Chen on 6/15/24.
//

import ArgumentParser
import Foundation


/// Command-line interface for the AbstractSyntaxTreeGenerator.
@main
struct TreeGenerator: ParsableCommand {
    /// The path of the source JSON to generate code from.
    @Option(help: "The path of source json to generate code on", transform: { URL(filePath: $0) })
    var sourceDirectory: URL?
    
    /// The path to save the generated code.
    @Argument(help: "The path to save generated code to", transform: { URL(filePath: $0) })
    var outputDirectory: URL?
    
    /// Executes the command to generate the abstract syntax tree code.
    mutating func run() throws {
        var trees: [Tree] = []
        if let sourceDirectory {
            let data = try Data(contentsOf: sourceDirectory)
            let decoder = JSONDecoder()
            let tree = try decoder.decode(Tree.self, from: data)
            trees.append(tree)
        } else {
            print("--source-directory not provided, default to bundled JSONs")
            let decoder = JSONDecoder()
            guard let expressionJson = Bundle.module.url(forResource: "expression", withExtension: "json") else {
                fatalError("expression.json does not exist, please provide source JSON manually")
            }
            let expressionData = try Data(contentsOf: expressionJson)
            let expressionTree = try decoder.decode(Tree.self, from: expressionData)
            trees.append(expressionTree)
        }
        
        guard !trees.isEmpty else {
            fatalError("No tree to be generated")
        }
        
        for tree in trees {
            let generator = AbstractSyntaxTreeGenerator(tree, path: outputDirectory)
            print(String(repeating: "-", count: 5) + "\(tree.baseName).swift" + String(repeating: "-", count: 5))
            generator.writeTree()
        }
    }
}
