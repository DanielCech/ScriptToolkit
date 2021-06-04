//
//  FolderExtension.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Files
import Foundation
import SwiftShell

public extension Folder {
    static func from(_ text: String) throws -> Folder {
        return try Folder(path: text.withoutEscapes) 
    }
    
    static func folders(from text: String) throws -> [Folder] {
        let paths = text.splittedBySpaces()
        return try paths.map { try Folder(path: $0.withoutEscapes) }
    }
    
    /// Create folder duplicate
    @discardableResult func createDuplicate(withName newName: String, keepExtension: Bool = true) throws -> Folder {
        guard let parent = parent else {
            throw ScriptError.renameFailed(message: newName)
        }

        var newName = newName

        if `extension` != nil {
            if keepExtension {
                if let `extension` = `extension` {
                    let extensionString = ".\(`extension`)"

                    if !newName.hasSuffix(extensionString) {
                        newName += extensionString
                    }
                }
            }
        }

        let newPath = parent.path + newName

        do {
            try FileManager.default.copyItem(atPath: path, toPath: newPath)
            return try Folder(path: newPath)
        }
        catch {
            throw ScriptError.renameFailed(message: newPath)
        }
    }

    // MARK: - Modification date

    /// Get folder modification date
    func modificationDate() throws -> Date {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: path) as [FileAttributeKey: Any]
        let modificationDate = fileAttributes[.modificationDate] as! Date

        return modificationDate
    }

    // MARK: - Tag folder

    /// Tag folder with date/time/version signature
    func tag(copy: Bool) throws {
        let date = try modificationDate()
        let suffix = ScriptToolkit.dateFormatter.string(from: date)
        for letter in "abcdefghijklmnopqrstuvwxyz" {
            let folder = try Folder(path: path)
            let newPath = (folder.parent?.path ?? "./")
            var newName = folder.nameExcludingExtension + "(\(suffix + String(letter)))"

            if let ext = folder.extension {
                newName += "." + ext
            }

            if !FileManager.default.fileExists(atPath: newPath + newName) {
                if copy {
                    try folder.createDuplicate(withName: newName)
                }
                else {
                    try folder.rename(to: newName)
                }
                return
            }
        }
    }

    // MARK: - Flatten folder structure

    /// Make directory structure flat - use longer file names
    func flattenFolderStructure(outputDir: String, move: Bool, overwrite: Bool = true) throws {
        let outputFolder = try Folder(path: outputDir)

        let inputFolderPath = path
        let index = inputFolderPath.index(inputFolderPath.startIndex, offsetBy: inputFolderPath.count)

        try subfolders.recursive.forEach { folder in
            let folderPath = folder.path[index...]
            let folderPrefix = folderPath.replacingOccurrences(of: "/", with: " ").trimmingCharacters(in: .whitespaces)

            for file in folder.files {
                let newName = folderPrefix + " " + file.name
                if !overwrite, FileManager.default.fileExists(atPath: newName) { continue }

                if move {
                    try file.rename(to: newName, keepExtension: true)
                }
                else {
                    let newFile = try file.copy(to: outputFolder)
                    try newFile.rename(to: newName, keepExtension: true)
                }
            }
        }
    }


    // MARK: - Remove Empty Directories

    /// Remove empty subdirectories
    func removeEmptyDirectories() throws {
        for subfolder in subfolders {
            try subfolder.removeEmptyDirectories()
        }

        if subfolders.count() == 0, files.count() == 0 {
            logger.print("removed: \(path)")
            try delete()
        }
    }
    
    func createFolderIfNotExists(named name: String) throws -> Folder {
        if self.containsSubfolder(named: name) {
            return try self.subfolder(named: name)
        }
        else {
            return try self.createSubfolder(named: name)
        }
    }
}
