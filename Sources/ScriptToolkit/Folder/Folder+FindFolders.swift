//
//  Folder+FindFolders.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Files
import Foundation
import SwiftShell

// MARK: - Find folders

public extension Folder {

    /// Find first folder with name recursively
    func findFirstFolder(name: String) -> Folder? {
        for folder in subfolders.recursive {
            if folder.name == name {
                return folder
            }
        }

        return nil
    }

    /// Find all folders with name recursively
    func findFolders(name: String) -> [Folder] {
        var foundFolders = [Folder]()
        for folder in subfolders.recursive {
            if folder.name == name {
                foundFolders.append(folder)
            }
        }
        return foundFolders
    }

    /// Find all folders matching the regex recursively
    func findFolders(regex: String) -> [Folder] {
        var foundFolders = [Folder]()
        for folder in subfolders.recursive {
            if !matches(for: regex, in: folder.name).isEmpty {
                foundFolders.append(folder)
            }
        }
        return foundFolders
    }
}
