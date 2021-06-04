//
//  Array+Chunked.swift
//  Toolkit
//
//  Created by Daniel Cech on 23.05.2021.
//

import Foundation

public extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
