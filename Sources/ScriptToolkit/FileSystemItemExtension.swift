//
//  FileSystemItemExtension.swift
//  ScriptToolkit
//
//  Created by Dan on 15.02.2019.
//

import Foundation
import Files
import SwiftShell

public extension FileSystem.Item {

    public func modificationDate() throws -> Date  {

        let fileAttributes = try FileManager.default.attributesOfItem(atPath: path) as [FileAttributeKey: Any]
        let modificationDate = fileAttributes[.modificationDate] as! Date

        return modificationDate
    }

    ////////////////////////////////////////////////////////////////////////////////

    public func tag(copy: Bool) throws {
        let date = try modificationDate()
        let suffix = ScriptToolkit.dateFormatter.string(from: date)
        for letter in "abcdefghijklmnopqrstuvwxyz" {

            switch FileManager.default.itemKind(atPath: path)! {

            case .file:
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

            case .folder:
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
    }


}
