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

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Modification date

    /// Get folder modification date
    func modificationDate() throws -> Date {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: path) as [FileAttributeKey: Any]
        let modificationDate = fileAttributes[.modificationDate] as! Date

        return modificationDate
    }

    ////////////////////////////////////////////////////////////////////////////////
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

    ////////////////////////////////////////////////////////////////////////////////
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

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Sort Photos

    /// Get photo metadata
    func exifTool(byCameraModel: Bool, processM4V: Bool) throws {
        let inputFolder = try Folder(path: path)

        print("📷 Processing EXIFtool...")

        if byCameraModel {
            // Process JPG dirs using exiftool
            for dir in inputFolder.subfolders {
                run("/usr/local/bin/exiftool", "-Directory<Model", "-d", "%Y-%m-%d \(dir.name)", dir.path)
            }

            // Process JPG using exiftool
            for file in inputFolder.files {
                run("/usr/local/bin/exiftool", "-Directory<Model", "-d", "%Y-%m-%d", file.path)
            }
            return
        }

        // Process JPG dirs using exiftool
        for dir in inputFolder.subfolders {
            run("/usr/local/bin/exiftool", "-Directory<DateTimeOriginal", "-d", "%Y-%m-%d \(dir.name)", dir.path)
        }

        var originalFolders = inputFolder
            .subfolders
            .filter { matches(for: "^\\d\\d\\d\\d-\\d\\d-\\d\\d.*$", in: $0.name).isEmpty }

        originalFolders.append(inputFolder)

        // Support of M4V
        for folder in originalFolders {
            for file in folder.files.includingHidden {
                switch file.extension?.lowercased() ?? "" {
                case "jpg", "jpeg":
                    run("/usr/local/bin/exiftool", "-Directory<DateTimeOriginal", "-d", "%Y-%m-%d", file.path)

                case "png":
                    run("/usr/local/bin/exiftool", "-Directory<DateCreated", "-d", "%Y-%m-%d", file.path)

                case "m4v":
                    if !processM4V {
                        run("/usr/local/bin/exiftool", "-Directory<ContentCreateDate", "-d", "%Y-%m-%d", file.path)
                    }

                case "mp4":
                    run("/usr/local/bin/exiftool", "-Directory<FileAccessDate", "-d", "%Y-%m-%d", file.path)

                case "mov":
                    run("/usr/local/bin/exiftool", "-Directory<CreationDate", "-d", "%Y-%m-%d", file.path)

                default:
                    break
                }
            }
        }
    }

    /// Organize photos by metadata
    func organizePhotos() throws {
        print("📂 Organizing...")

        var folderRecords = [(Folder, [Int])]()

        let sortedSubfolders = subfolders
            .filter { !matches(for: "^\\d\\d\\d\\d-\\d\\d-\\d\\d.*$", in: $0.name).isEmpty }
            .sorted { $0.name < $1.name }

        for dir in sortedSubfolders {
            let indexes = dir.files
                .map { $0.nameExcludingExtension.replacingOccurrences(of: "IMG_", with: "") }
                .compactMap { Int($0) }
                .sorted()
            folderRecords.append((dir, indexes))
        }

        var originalFolders = subfolders
            .filter { matches(for: "^\\d\\d\\d\\d-\\d\\d-\\d\\d.*$", in: $0.name).isEmpty }

        originalFolders.append(self)

        for folder in originalFolders {
            for file in folder.files.includingHidden {
                try file.incorporateFile(using: folderRecords)
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Remove Empty Directories

    /// Remove empty subdirectories
    func removeEmptyDirectories() throws {
        for subfolder in subfolders {
            try subfolder.removeEmptyDirectories()
        }

        if subfolders.count() == 0, files.count() == 0 {
            print("removed: \(path)")
            try delete()
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Find files

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

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Find folders

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
