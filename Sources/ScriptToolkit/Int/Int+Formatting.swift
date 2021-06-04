//
//  Int+Formatting.swift
//  Toolkit
//
//  Created by Daniel Cech on 23.05.2021.
//

import Foundation

public extension Int {
    func uniformString(digits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = digits
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
