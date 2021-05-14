//
//  File.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import AppKit
import Files
import Foundation
import SwiftShell

public extension File {
    static func from(_ text: String) throws -> File {
        return try File(path: text.withoutEscapes)
    }
    
    static func files(from text: String) throws -> [File] {
        let paths = text.splittedBySpaces()
        return try paths.map { try File(path: $0.withoutEscapes) }
    }
    
    /// Appending suffix to file name
    func nameWithSuffix(_ suffix: String) -> String {
        if let unwrappedExtension = `extension` {
            return nameExcludingExtension + suffix + "." + unwrappedExtension
        }
        else {
            return nameExcludingExtension + suffix
        }
    }

    /// Create file duplicate
    @discardableResult func createDuplicate(withName newName: String, keepExtension: Bool = true, overwrite: Bool = true) throws -> File? {
        if !overwrite, FileManager.default.fileExists(atPath: newName) { return nil }

        guard let parent = parent else {
            throw ScriptError.renameFailed(message: newName)
        }

        var newName = newName

        if keepExtension {
            if let `extension` = `extension` {
                let extensionString = ".\(`extension`)"

                if !newName.hasSuffix(extensionString) {
                    newName += extensionString
                }
            }
        }

        let newPath = parent.path + newName

        do {
            try FileManager.default.copyItem(atPath: path, toPath: newPath)
            return try File(path: newPath)
        }
        catch {
            throw ScriptError.renameFailed(message: newPath)
        }
    }

    /// File modification date
    func modificationDate() throws -> Date {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: path) as [FileAttributeKey: Any]
        let modificationDate = fileAttributes[.modificationDate] as! Date

        return modificationDate
    }

    /// Tag file with date/time/version signature
    func tag(copy: Bool) throws {
        let date = try modificationDate()
        let suffix = ScriptToolkit.dateFormatter.string(from: date)
        for letter in "abcdefghijklmnopqrstuvwxyz" {
            let file = try File(path: path)
            let newPath = (file.parent?.path ?? "./")
            let newName = file.nameExcludingExtension + "(\(suffix + String(letter)))" + "." + (file.extension ?? "")

            if !FileManager.default.fileExists(atPath: newPath + newName) {
                if copy {
                    try file.createDuplicate(withName: newName)
                }
                else {
                    try file.rename(to: newName)
                }
                return
            }
        }
    }    
}
    

    
