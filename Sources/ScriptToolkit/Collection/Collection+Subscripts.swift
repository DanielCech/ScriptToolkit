//
//  Collection+Subscripts.swift
//  Toolkit
//
//  Created by Daniel Cech on 16.05.2021.
//

import Foundation

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
