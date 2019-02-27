//
//  FileManagerExtension.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 27.02.2019.
//

import Foundation
import Files

public extension FileManager {
    func itemKind(atPath path: String) -> FileSystem.Item.Kind? {
        var objCBool: ObjCBool = false

        guard fileExists(atPath: path, isDirectory: &objCBool) else {
            return nil
        }

        if objCBool.boolValue {
            return .folder
        }

        return .file
    }
}

public extension FileSystem.Item {
    enum Kind {
        case file
        case folder
    }
}
