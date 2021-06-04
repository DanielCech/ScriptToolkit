//
//  FileManagerExtension.swift
//  ScriptToolkit
//
//  Created by Daniel Cech on 05/04/2020.
//

import Files
import Foundation

public extension FileManager {
    /// Does the location exist?
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

    /// Type of location in path
    func locationKind(for path: String) -> LocationKind? {
        var isFolder: ObjCBool = false

        guard fileExists(atPath: path, isDirectory: &isFolder) else {
            return nil
        }

        if isFolder.boolValue {
            return .folder
        }
        else {
            return .file
        }
    }
    
    /// Test for folder existence with URL parameter
    func directoryExists(atUrl url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    /// Test for folder existence with path parameter
    func directoryExists(atPath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: atPath, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    /// Test for folder existence with URL parameter
    func fileExists(atUrl url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue
    }

    /// Test for folder existence with path parameter
    func fileExists(atPath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: atPath, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue
    }
}
