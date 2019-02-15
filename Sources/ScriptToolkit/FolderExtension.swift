//
//  FolderExtension.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Foundation
import Files

public extension Folder {
    @discardableResult public func createDuplicate(withName newName: String, keepExtension: Bool = true) throws -> Folder {
        guard let parent = parent else {
            throw OperationError.renameFailed(self)
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
        } catch {
            throw OperationError.renameFailed(self)
        }
    }
}

