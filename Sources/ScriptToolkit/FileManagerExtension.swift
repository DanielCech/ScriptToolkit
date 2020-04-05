//
//  FileManagerExtension.swift
//  ScriptToolkit
//
//  Created by Daniel Cech on 05/04/2020.
//

import Foundation
import Files

public extension FileManager {
    func locationExists(path: String, kind: LocationKind) -> Bool {
        var isFolder: ObjCBool = false

        guard fileExists(atPath: path, isDirectory: &isFolder) else {
            return false
        }

        switch kind {
        case .file: return !isFolder.boolValue
        case .folder: return isFolder.boolValue
        }
    }
    
    func locationKind(for path: String) -> LocationKind {
        var isFolder: ObjCBool = false

        guard fileExists(atPath: path, isDirectory: &isFolder) else {
            return .file
        }
        
        return .folder
    }
}
