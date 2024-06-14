//
//  Scanner.swift
//
//
//  Created by Yuhao Chen on 6/12/24.
//

import Foundation
#if canImport(OSLog)
import OSLog
#endif

/// A class responsible for scanning and tokenizing source code for the Lox interpreter.
class Scanner {
    private let source: String
    private var tokens: [Token] = []
    private var startIndex: String.Index
    private var _currentIndex: String.Index
    
    private var currentIndex: String.Index {
        get { self._currentIndex }
        set {
            if newValue < source.endIndex && source[newValue] == "\n" {
                line += 1 // Auto advance line
            }
            self._currentIndex = newValue
        }
    }
    
    private var line: Int = 1
    
    /// Initializes a new scanner with the given source code.
    /// - Parameter source: The source code to scan.
    init(_ source: String) {
        self.source = source
        self.startIndex = source.startIndex
        self._currentIndex = startIndex
    }
    
    /// The character at the current index position.
    private var latestCharacter: Character {
        if reachedEnd() {
            return "\0"
        }
        return source[currentIndex]
    }
    
    /// The upcoming character without advancing the current index.
    private var upcomingCharacter: Character {
        let next = source.index(after: currentIndex)
        guard next < source.endIndex else {
            return "\0"
        }
        return source[next]
    }
    
    /// Scans the source code and returns a list of tokens.
    /// - Returns: An array of tokens.
    func scanTokens() -> [Token] {
        while !reachedEnd() {
            startIndex = currentIndex
            scanToken()
        }
        
        let finalToken = Token(.eof, lexeme: "", literal: nil, line: line)
        tokens.append(finalToken)
        
        return tokens
    }
    
    /// Scans a single token and adds it to the list of tokens.
    func scanToken() {
        let targetCharacter: Character = latestCharacter
        advance()
        
        typealias T = TokenType // Define a temp alias for convenience
        switch targetCharacter {
        case T.leftParenthesis.character:
            addToken(.leftParenthesis)
        case T.rightParenthesis.character:
            addToken(.rightParenthesis)
        case T.leftBrace.character:
            addToken(.leftBrace)
        case T.rightBrace.character:
            addToken(.rightBrace)
        case T.comma.character:
            addToken(.comma)
        case T.dot.character:
            addToken(.dot)
        case T.minus.character:
            addToken(.minus)
        case T.plus.character:
            addToken(.plus)
        case T.semicolon.character:
            addToken(.semicolon)
        case T.star.character:
            addToken(.star)
        case T.equal.character:
            if matchThenAdvance(Character(T.equal.rawValue)) { addToken(.equalEqual) }
            else { addToken(.equal) }
        case T.bang.character:
            if matchThenAdvance(Character(T.equal.rawValue)) { addToken(.bangEqual) }
            else { addToken(.bang) }
        case T.less.character:
            if matchThenAdvance(T.equal.character) { addToken(.lessEqual) }
            else { addToken(.less) }
        case T.greater.character:
            if matchThenAdvance(T.equal.character) { addToken(.greaterEqual) }
            else { addToken(.greater) }
        case T.slash.character:
            switch latestCharacter {
            case T.slash.character:
                repeat { advance() }
                while latestCharacter != "\n" && !reachedEnd()
            case T.star.character:
                repeat { advance() }
                while latestCharacter != T.star.character && upcomingCharacter != T.slash.character && !reachedEnd()
            default: addToken(.slash)
            }
        case T.doubleQuote.character:
            scanString()
        case _ where targetCharacter.isDecimalDigit:
            scanNumber()
        case _ where targetCharacter.isLetter || targetCharacter == T.underScore.character:
            scanKeywordAndIdentifier()
        case " ", "\r", "\t": break // Ignore whitespace characters
        default: Lox.error("Unexpected character: '\(targetCharacter)'", on: line)
        }
    }
    
    /// Recursively scans a string literal.
    private func scanString() {
        guard !reachedEnd() else {
            Lox.error("Unterminated string.", on: line)
            addToken(.doubleQuote)
            return
        }
        guard latestCharacter != TokenType.doubleQuote.character else {
            advance()
            let afterStart = source.index(after: startIndex)
            let beforeCurrent = source.index(before: currentIndex)
            let value = String(source[afterStart..<beforeCurrent])
            addToken(.string, literal: value)
            return
        }
        advance()
        scanString()
    }
    
    /// Scans a number literal.
    private func scanNumber() {
        while latestCharacter.isDecimalDigit {
            advance()
        }
        
        if latestCharacter == TokenType.dot.character && upcomingCharacter.isDecimalDigit {
            advance()
        }
        
        while latestCharacter.isDecimalDigit {
            advance()
        }
        
        let numberString = String(source[startIndex..<currentIndex])
        guard let number = Double(numberString) else {
            Lox.error("Fatal Error: scanner can't assemble digits while parsing numbers", on: line)
            return
        }
        addToken(.number, literal: number)
    }
    
    /// Scans keywords and identifiers.
    private func scanKeywordAndIdentifier() {
        while latestCharacter.isDecimalDigit || latestCharacter.isLetter || latestCharacter == TokenType.underScore.character {
            advance()
        }
        
        let text = String(source[startIndex..<currentIndex])
        let type = TokenType(rawValue: text) ?? .identifier
        addToken(type)
    }
    
    /// Advances the current index by one and returns the advanced character.
    /// - Returns: The character at the new current index.
    @discardableResult func advance() -> Character {
        currentIndex = source.index(after: currentIndex)
        return currentIndex < source.endIndex ? source[currentIndex] : "\0"
    }
    
    /// Adds a token to the list of tokens.
    /// - Parameters:
    ///   - type: The type of the token.
    ///   - literal: The literal value of the token, if any.
    private func addToken(_ type: TokenType, literal: Any? = nil) {
        let text = String(source[startIndex..<currentIndex])
        let token = Token(type, lexeme: text, literal: literal, line: line)
        tokens.append(token)
    }
    
    /// Matches the expected character and advances the current index if it matches.
    /// - Parameter expected: The expected character.
    /// - Returns: A Boolean value indicating whether the expected character was matched.
    private func matchThenAdvance(_ expected: Character) -> Bool {
        guard !reachedEnd() else { return false }
        
        let isExpected = source[currentIndex] == expected
        if isExpected {
            advance()
        }
        return isExpected
    }
    
    /// Checks whether the current index has reached the end of the source.
    /// - Returns: A Boolean value indicating whether the end of the source has been reached.
    private func reachedEnd() -> Bool {
        if currentIndex < source.endIndex { return false }
        if currentIndex > source.endIndex {
            #if canImport(OSLog)
            logger.error("Scanner has gone beyond the source's end index, this should never happen.")
            #else
            print("Scanner has gone beyond the source's end index, this should never happen.")
            #endif
        }
        return true
    }
}

extension Character {
    /// Checks whether the character is a decimal digit.
    var isDecimalDigit: Bool {
        let digits = CharacterSet.decimalDigits
        guard let s = String(self).unicodeScalars.first else {
             return false
        }
        return digits.contains(s)
    }
}

#if canImport(OSLog)
fileprivate let logger = Logger(subsystem: "Lox", category: "Scanner")
#endif
