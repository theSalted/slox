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
public final class Scanner {
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
        
        /* NOTE: Notice here we assign targetCharacter and immediately advance scanner?
         * This help avoid some nasty infinite loop. So technically currentIndex is often
         * one character ahead of character being scanned. Which can gets confusing.
         *
         * This is the reason why I decided against implementing methods like peek() which
         * return source[currentIndex] and peekNext() which return source[currentIndex + 1].
         *
         * Also, rename target to previous is also bad because sometime we skip characters
         * and 'previous' immediate became inapplicable.
         */
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
            if match(Character(T.equal.rawValue)) { addToken(.equalEqual) }
            else { addToken(.equal) }
        case T.bang.character:
            if match(Character(T.equal.rawValue)) { addToken(.bangEqual) }
            else { addToken(.bang) }
        case T.less.character:
            if match(T.equal.character) { addToken(.lessEqual) }
            else { addToken(.less) }
        case T.greater.character:
            if match(T.equal.character) { addToken(.greaterEqual) }
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
        case " ", "\r", "\t", "\n": break // Ignore whitespace characters
        default: Lox.reportError("Unexpected character: '\(targetCharacter)'", on: line)
        }
    }
    
    /// Recursively scans a string literal.
    private func scanString() {
        guard !reachedEnd() else {
            Lox.reportError("Unterminated string.", on: line)
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
            Lox.reportError("Fatal Error: scanner can't assemble digits while parsing numbers", on: line)
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
    
    /// Adds a token to the list of tokens.
    /// - Parameters:
    ///   - type: The type of the token.
    ///   - literal: The literal value of the token, if any.
    private func addToken(_ type: TokenType, literal: Any? = nil) {
        let text = String(source[startIndex..<currentIndex])
        let token = Token(type, lexeme: text, literal: literal, line: line)
        tokens.append(token)
    }
}

// MARK: Utility methods
/// Helper methods that directly interact with parser while not necessarily part of scanning rulea
public extension Scanner {
    /// Advances the current index by one and returns the advanced character.
    /// - Returns: The character at the new current index.
    @discardableResult func advance() -> Character {
        currentIndex = source.index(after: currentIndex)
        return currentIndex < source.endIndex ? source[currentIndex] : "\0"
    }
    
    /// Matches the expected character, and by default **advances** the current index if it matches.
    ///
    /// - Parameters:
    ///     - expected: The expected character.
    ///     - advanceWhenMatched: Wether auto advance when matched
    /// - Returns: A Boolean value indicating whether the expected character was matched.
    private func match(
        _ expected: Character,
        advance advanceWhenMatched: Bool = true
    ) -> Bool {
        guard !reachedEnd() else { return false }
        
        let isExpected = source[currentIndex] == expected
        if isExpected && advanceWhenMatched {
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

public extension Character {
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
