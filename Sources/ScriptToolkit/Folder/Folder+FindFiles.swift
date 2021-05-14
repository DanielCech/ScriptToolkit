//
//  Folder+FindFiles.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Files
import Foundation
import SwiftShell

// MARK: - Find files

public extension Folder {
    /// Find first file with name recursively
    func findFirstFile(name: String) -> File? {
        for file in files.recursive {
            if file.name == name {
                return file
            }
        }
        return nil
    }

    /// Find all files with name recursively
    func findFiles(name: String) -> [File] {
        var foundFiles = [File]()
        for file in files.recursive {
            if file.name == name {
                foundFiles.append(file)
            }
        }
        return foundFiles
    }

    /// Find all files matching the regex recursively
    func findFiles(regex: String) -> [File] {
        var foundFiles = [File]()
        for file in files.recursive {
            if !matches(for: regex, in: file.name).isEmpty {
                foundFiles.append(file)
            }
        }
        return foundFiles
    }
}
