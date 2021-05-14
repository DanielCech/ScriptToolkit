//
//  File+PhotoProcessing.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Foundation
import Files
import SwiftShell


// MARK: - Photo Processing

public extension File {
    /// Moving file to appropriate folder during photo processing
    func incorporateFile(using folderRecords: [(Folder, [Int])]) throws {
        print("\(path)")
        let numberString = nameExcludingExtension.replacingOccurrences(of: "IMG_", with: "")
        var lastMaximum: Int?
        if let number = Int(numberString) {
            var moved = false
            for folderRecord in folderRecords {
                if let firstIndex = folderRecord.1.first, let lastIndex = folderRecord.1.last, number >= firstIndex, number <= lastIndex {
                    try move(to: folderRecord.0)
                    moved = true
                    break
                }

                if let unwrappedLastMaximum = lastMaximum, let firstIndex = folderRecord.1.first, unwrappedLastMaximum <= number, firstIndex >= number {
                    try move(to: folderRecord.0)
                    moved = true
                    break
                }

                lastMaximum = folderRecord.1.last
            }
            if !moved { print("  unable to process - no appropriate folder") }
        }
        else {
            print("  unable to process")
        }
    }
}
