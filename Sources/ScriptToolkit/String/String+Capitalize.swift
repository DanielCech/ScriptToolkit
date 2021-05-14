//
//  String+Capitalize.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Foundation

public extension String {
   /// Conversion to PascalCase
    func capitalized() -> String {
        let first = String(prefix(1)).uppercased()
        let other = String(dropFirst())
        return first + other
    }

    /// Conversion to PascalCase
    mutating func capitalize() {
        self = capitalized()
    }

    /// Conversion to camelCase
    func decapitalized() -> String {
        let first = String(prefix(1)).lowercased()
        let other = String(dropFirst())
        return first + other
    }

    /// Conversion to camelCase
    mutating func decapitalize() {
        self = decapitalized()
    }
}
