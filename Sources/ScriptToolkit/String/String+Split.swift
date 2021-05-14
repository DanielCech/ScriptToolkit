//
//  String+Split.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Foundation

public extension String {
    func splittedBySpaces() -> [String] {
        var output = [String]()
        var currentString = ""

        for index in 0 ..< count {
            if self[index] == " " {
                if index > 0, self[index - 1] != "\\" {
                    output.append(currentString.replacingOccurrences(of: "\\", with: ""))
                    currentString = ""
                    continue
                }
            }

            currentString += String(self[index])
        }

        if !currentString.isEmpty {
            output.append(currentString.replacingOccurrences(of: "\\", with: ""))
        }

        return output
    }
    

    func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()

        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }

        return results.map { String($0) }
    }
}
