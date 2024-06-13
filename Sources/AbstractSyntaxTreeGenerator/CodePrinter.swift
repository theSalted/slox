//
//  CodePrinter.swift
//  
//
//  Created by Yuhao Chen on 6/14/24.
//

import OSLog

class CodePrinter {
    private var output = ""
    private var indentCount = 0
    let indentString = "    "
    
    func addFileHeader(fileName: String, creatorInfo: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let header = """
        //
        // \(fileName)
        //
        //
        // \(creatorInfo) on \(dateFormatter.string(from: Date.now))
        //
        """
        output += header
    }
    
    func emptyLine() {
        print("", to: &output)
    }
    
    func writeLine(_ line: String) {
        let indentation = String(repeating: indentString, count: indentCount)
        print(indentation + line, to: &output)
    }
    
    func indent() {
        indentCount += 1
    }
    
    func detent() {
        guard indentCount > 0 else {
            logger.warning("Indent count dipped below zero")
            return
        }
        indentCount -= 1
    }
    
    func print(to path: URL) {
        do {
            try output.write(to: path, atomically: true, encoding: .utf8)
        } catch {
            logger.error("CodePrinter failed when trying write to \(path.description)")
        }
    }
}

fileprivate let logger = Logger(subsystem: "AbstractSyntaxTreeGenerator", category: "CodePrinter")
