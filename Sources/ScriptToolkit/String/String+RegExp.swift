//
//  String+RegExp.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Foundation

// MARK: - Regular expressions

public extension String {
    /// Regular expression matches
    func regExpMatches(lineRegExp: String) throws -> [NSTextCheckingResult] {
        let nsrange = NSRange(startIndex..<endIndex, in: self)
        let regex = try NSRegularExpression(pattern: lineRegExp, options: [.anchorsMatchLines])
        let matches = regex.matches(in: self, options: [], range: nsrange)
        return matches
    }

    /// Regular expression matches
    func regExpStringMatches(lineRegExp: String) throws -> [String] {
        let matches = try regExpMatches(lineRegExp: lineRegExp)

        let ranges = matches.compactMap { Range($0.range, in: self) }
        let substrings = ranges.map { self[$0] }
        let strings = substrings.map { String($0) }
        return strings
    }

    /// Regular expression substitutions
    func stringByReplacingMatches(pattern: String, withTemplate template: String) throws -> String {
        let regex = try NSRegularExpression(pattern: pattern)
        return regex.stringByReplacingMatches(
            in: self,
            options: .reportCompletion,
            range: NSRange(location: 0, length: count),
            withTemplate: template
        )
    }
    
    func stringLookupMatch(text: String) throws -> Bool {
        let textPart = Array(text)
            .map { String($0) }
            .joined(separator: ".*")
        let regExp = "^.*" + textPart + ".*$"
        
        print(regExp)
        
        return try !regExpMatches(lineRegExp: regExp).isEmpty
    }
}
