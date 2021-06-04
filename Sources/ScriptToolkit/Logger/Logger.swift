//
//  Logger.swift
//  Toolkit
//
//  Created by Daniel Cech on 22.05.2021.
//

import Foundation

public let logger = Logger()

public class Logger {
    public var indent = 0
    
    public let columns: Int
    
    public init() {
        // Get screen dimensions
        columns = Int(shell("tput cols")) ?? 80
    }
    
    // MARK: - Normal print
    
    public func print(_ text: String, separator: String = " ", terminator: String = "\n", indent: Int? = nil) {
        
        let wrappedText = format(
            text,
            indent: indent
        )
        
        Swift.print(wrappedText, separator: separator, terminator: terminator)
    }
    
    public func format(_ text: String, indent: Int? = nil) -> String {
        return wordWrap(
            lines: text.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) },
            indent: indent
        )
    }
    
    // MARK: - Print with prompt
    
    public func print(prompt: String, text: String, separator: String = " ", terminator: String = "\n", indent: Int? = nil) {
        let wrappedText = format(
            prompt: prompt,
            text: text,
            indent: indent
        )
        
        Swift.print(wrappedText, separator: separator, terminator: terminator)
    }
    
    public func format(prompt: String, text: String, indent: Int? = nil) -> String {
        let currentIndent = indent ?? self.indent
        var modifiedText = "\u{1B}[1000D"
        
        if currentIndent > 0 {
            modifiedText += "\u{1B}[\(currentIndent * 3)C"
        }
            
        modifiedText += prompt + "\u{1B}[1000D\u{1B}[\(currentIndent * 3 + 3)C" + text
        
        return wordWrap(
            lines: modifiedText.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) },
            indent: indent
        )
    }
    
    // MARK: - Indentation
    
    public func indentText(_ line: String, indent: Int? = nil) -> String {
        let indentString =  String(repeating: " ", count: (indent ?? self.indent) * 3)
        return indentString + line
    }
    
    public func wordWrap(lines: [String], indent: Int? = nil) -> String {
        let array = lines.flatMap { [weak self] line -> [String] in
            guard let self = self else {
                return []
            }
            
            return self.wrapLine(indentText(line, indent: indent), indent: indent)
        }
        
        return array.joined(separator: "\n")
    }
    
    public func wrapLine(_ line: String, indent: Int? = nil) -> [String] {
        if line.count <= columns {
            return [line]
        }
        else {
            var lastSpaceIndex = 0
            for index in 0 ..< line.count {
                if index >= columns - 1 {
                    var head: String
                    var tail: String
                    
                    if lastSpaceIndex > 0 {
                        head = String(line.prefix(lastSpaceIndex))
                        tail = String(line.suffix(line.count - lastSpaceIndex - 1))
                    }
                    else {
                        head = String(line.prefix(columns))
                        tail = String(line.suffix(line.count - columns - 1))
                    }
                    
                    var list = [head]
                    list.append(contentsOf: wrapLine(indentText(tail, indent: indent), indent: indent))
                    
                    return list
                }
                
                if line[index] == " " {
                    lastSpaceIndex = index
                }
            }
        }
        
        return []
    }
}
