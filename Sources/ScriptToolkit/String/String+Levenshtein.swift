//
//  String+Levenshtein.swift
//  Toolkit
//
//  Created by Daniel Cech on 28.05.2021.
//

// Based on: https://github.com/TheDarkCode/SwiftyLevenshtein/blob/master/Pod/Classes/SwiftyLevenshtein.swift

import Foundation

public extension String {
    
    func levenshteinDistance(target: String) -> Int {
        
        let sourceArray = Array(unicodeScalars)
        let targetArray = Array(target.unicodeScalars)
        
        let (sourceArrayLength, targetArrayLength) = (sourceArray.count, targetArray.count)
        
        var distance = Array2D(columns: sourceArrayLength + 1, rows: targetArrayLength + 1)
        
        for x in 1...sourceArrayLength {
            distance[x, 0] = x
        }
        
        for y in 1...targetArrayLength {
            distance[0, y] = y
        }
        
        for x in 1...sourceArrayLength {
            for y in 1...targetArrayLength {
                
                if sourceArray[x - 1] == targetArray[y - 1] {
                    // no difference
                    distance[x, y] = distance[x - 1, y - 1]
                } else {
                    distance[x, y] = min3(
                        // deletions
                        a: distance[x - 1, y] + 1,
                        // insertions
                        b: distance[x, y - 1] + 1,
                        // substitutions
                        c: distance[x - 1, y - 1] + 1
                        
                    )
                }
            }
        }
        
        return distance[sourceArray.count, targetArray.count]
    }
}
