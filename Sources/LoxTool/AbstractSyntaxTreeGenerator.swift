//
//  AbstractSyntaxTreeGenerator.swift
//  
//
//  Created by Yuhao Chen on 6/14/24.
//

import Lox
import Foundation
import ArgumentParser

struct AbstractSyntaxTreeGenerator: ParsableCommand {
    @Argument(help: "The path to operate on", transform: { URL(filePath: $0) })
    var outPutDirectory: URL
    
    mutating func run() throws {
    }
}
