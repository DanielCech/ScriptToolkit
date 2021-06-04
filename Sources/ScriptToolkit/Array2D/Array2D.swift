//
//  Array2D.swift
//  Toolkit
//
//  Created by Daniel Cech on 28.05.2021.
//

import Foundation

public struct Array2D {
    
    var columns: Int
    var rows: Int
    var matrix: [Int]
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        matrix = Array(repeating:0, count:columns*rows)
    }
    
    subscript(column: Int, row: Int) -> Int {
        
        get {
            return matrix[columns * row + column]
        }
        
        set {
            matrix[columns * row + column] = newValue
        }
        
    }
    
    func columnCount() -> Int {
        return self.columns
    }
    
    func rowCount() -> Int {
        return self.rows
    }
}
