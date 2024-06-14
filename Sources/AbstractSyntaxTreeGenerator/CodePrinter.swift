//
//  CodePrinter.swift
//
//
//  Created by Yuhao Chen on 6/14/24.
//

import OSLog

/// A utility class for generating and managing code output with proper indentation and formatting.
class CodePrinter {
    private var output = ""
    private var indentCount = 0
    let indentString = "    "
    
    /// Adds a file header to the generated code.
    /// - Parameters:
    ///   - fileName: The name of the file.
    ///   - creatorInfo: Information about the creator of the file.
    func addFileHeader(fileName: String, creatorInfo: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YY"
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
    
    /// Adds an empty line to the generated code.
    func emptyLine() {
        print("", to: &output)
    }
    
    /// Writes a line of code with proper indentation.
    /// - Parameter line: The line of code to write.
    func writeLine(_ line: String) {
        let indentation = String(repeating: indentString, count: indentCount)
        print(indentation + line, to: &output)
    }
    
    /// Increases the indentation level.
    func indent() {
        indentCount += 1
    }
    
    /// Decreases the indentation level.
    func detent() {
        guard indentCount > 0 else {
            logger.warning("Indent count dipped below zero")
            return
        }
        indentCount -= 1
    }
    
    /// Saves the generated code to a specified path.
    /// - Parameter path: The file path to save the code to.
    func save(to path: URL?) {
        guard let path else {
            print("No file path provided")
            print("Printing generated code instead: ")
            print("``")
            print(output)
            print("``")
            return
        }
        
        do {
            if indentCount != 0 {
                logger.warning("Indent count (\(self.indentCount)) is not restored to zero by the EOF.")
            }
            print("Saving file to \(path.absoluteString)")
            try output.write(to: path, atomically: true, encoding: .utf8)
        } catch {
            logger.error("CodePrinter failed when trying write to \(path.description)")
        }
    }
}

fileprivate let logger = Logger(subsystem: "AbstractSyntaxTreeGenerator", category: "CodePrinter")
