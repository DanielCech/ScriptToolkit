//
//  ScriptToolkit.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Foundation
import Files
import SwiftShell

public struct ScriptToolkit {
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()
}

////////////////////////////////////////////////////////////////////////////////
// MARK: - Helpers

public func fileModificationDate(_ file: String) throws -> Date  {

    let fileAttributes = try FileManager.default.attributesOfItem(atPath: file) as [FileAttributeKey: Any]
    let modificationDate = fileAttributes[.modificationDate] as! Date

    return modificationDate
}

func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

////////////////////////////////////////////////////////////////////////////////
// MARK: - Tag file

public func tag(_ item: String, copy: Bool) throws {
    let date = try fileModificationDate(item)
    let suffix = ScriptToolkit.dateFormatter.string(from: date)
    for letter in "abcdefghijklmnopqrstuvwxyz" {

        switch FileManager.default.itemKind(atPath: item)! {

        case .file:
            let file = try File(path: item)
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
            let folder = try Folder(path: item)
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

////////////////////////////////////////////////////////////////////////////////
// Flatten folder structure

public func flattenFolderStructure(inputDir: String, outputDir: String, move: Bool) throws {
    let inputFolder = try Folder(path: inputDir)
    let outputFolder = try Folder(path: outputDir)

    let inputFolderPath = inputFolder.path
    let index = inputFolderPath.index(inputFolderPath.startIndex, offsetBy: inputFolderPath.count)

    try inputFolder.makeSubfolderSequence(recursive: true).forEach { folder in
        print("folder: \(folder), files: \(folder.files)")
        let folderPath = folder.path[index...]
        let folderPrefix = folderPath.replacingOccurrences(of: "/", with: " ")

        for file in folder.files {
            if move {
                try file.rename(to: folderPrefix + " " + file.name, keepExtension: true)
            }
            else {
                let newFile = try file.copy(to: outputFolder)
                try newFile.rename(to: folderPrefix + " " + file.name, keepExtension: true)
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// MARK: - Sort Photos

public func exifTool(inputDir: String, byCameraModel: Bool, processM4V: Bool) throws {
    let inputFolder = try Folder(path: inputDir)

    print("📷 Processing EXIFtool...")

    if byCameraModel {
        // Process JPG dirs using exiftool
        for dir in inputFolder.subfolders {
            run("/usr/local/bin/exiftool","-Directory<Model", "-d", "%Y-%m-%d \(dir.name)", dir.path)
        }

        // Process JPG using exiftool
        for file in inputFolder.files {
            run("/usr/local/bin/exiftool" ,"-Directory<Model", "-d", "%Y-%m-%d", file.path)
        }
        return
    }


    // Process JPG dirs using exiftool
    for dir in inputFolder.subfolders {
        run("/usr/local/bin/exiftool","-Directory<DateTimeOriginal", "-d", "%Y-%m-%d \(dir.name)", dir.path)
    }

    var originalFolders = inputFolder
        .subfolders
        .filter { matches(for: "^\\d\\d\\d\\d-\\d\\d-\\d\\d.*$", in: $0.name).isEmpty }

    originalFolders.append(inputFolder)

    // Support of M4V
    for dir in originalFolders {
        for file in dir.makeFileSequence(recursive: true, includeHidden: true) {

            switch file.extension?.lowercased() ?? "" {
            case "jpg", "jpeg":
                run("/usr/local/bin/exiftool" ,"-Directory<DateTimeOriginal", "-d", "%Y-%m-%d", file.path)

            case "png":
                run("/usr/local/bin/exiftool" ,"-Directory<DateCreated", "-d", "%Y-%m-%d", file.path)

            case "m4v":
                if !processM4V {
                    run("/usr/local/bin/exiftool" ,"-Directory<ContentCreateDate", "-d", "%Y-%m-%d", file.path)
                }

            case "mp4":
                run("/usr/local/bin/exiftool" ,"-Directory<FileAccessDate", "-d", "%Y-%m-%d", file.path)

            case "mov":
                run("/usr/local/bin/exiftool" ,"-Directory<CreationDate", "-d", "%Y-%m-%d", file.path)

            default:
                break
            }
        }
    }
}

func incorporateFile(_ file: File, using folderRecords: [(Folder, [Int])]) throws {
    print("\(file.path)")
    let numberString = file.nameExcludingExtension.replacingOccurrences(of: "IMG_", with: "")
    var lastMaximum: Int?
    if let number = Int(numberString) {

        var moved = false
        for folderRecord in folderRecords {
            if let firstIndex = folderRecord.1.first, let lastIndex = folderRecord.1.last, number >= firstIndex, number <= lastIndex {
                try file.move(to: folderRecord.0)
                //                print("  moved to \(folderRecord.0.path)")
                moved = true
                break
            }

            if let unwrappedLastMaximum = lastMaximum, let firstIndex = folderRecord.1.first, unwrappedLastMaximum <= number, firstIndex >= number {
                try file.move(to: folderRecord.0)
                //                print("  moved to \(folderRecord.0.path)")
                moved = true
                break
            }

            lastMaximum = folderRecord.1.last
        }
        if !moved { print("  unable to process - no appropriate folder") }
    }
    else {
        print("  unable to process")
    }
}

public func organizePhotos(inputDir: String) throws {
    print("📂 Organizing...")

    let inputFolder = try Folder(path: inputDir)
    var folderRecords = [(Folder, [Int])]()

    let sortedSubfolders = inputFolder
        .subfolders
        .filter { !matches(for: "^\\d\\d\\d\\d-\\d\\d-\\d\\d.*$", in: $0.name).isEmpty }
        .sorted { $0.name < $1.name }

    for dir in sortedSubfolders {
        let indexes = dir.files
            .map { $0.nameExcludingExtension.replacingOccurrences(of: "IMG_", with: "") }
            .compactMap { Int($0) }
            .sorted()
        folderRecords.append((dir, indexes))
    }

    var originalFolders = inputFolder
        .subfolders
        .filter { matches(for: "^\\d\\d\\d\\d-\\d\\d-\\d\\d.*$", in: $0.name).isEmpty }

    originalFolders.append(inputFolder)

    for folder in originalFolders {
        for file in folder.makeFileSequence(recursive: true, includeHidden: true) {
            try incorporateFile(file, using: folderRecords)
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// MARK: - Remove Empty Directories

public func removeEmptyDirectories(in folder: Folder) throws {
    for subfolder in folder.subfolders {
        try removeEmptyDirectories(in: subfolder)
    }

    if folder.subfolders.count == 0 && folder.files.count == 0 {
        print("removed: \(folder.path)")
        try folder.delete()
    }
}

////////////////////////////////////////////////////////////////////////////////
// MARK: - Resize image

public func resizeImage(original: String, newName: String, size: CGSize) {
    run("/usr/local/bin/convert", original, "-resize", "\(size.width)x\(size.height)",newName)
}

public func resizeAt123x(_ file: File, width: Int, height: Int, outputDir: Folder) throws {
    print(file.name)

    let res1name = outputDir.path.appendingPathComponent(path: file.name)
    resizeImage(original: file.path, newName: res1name, size: CGSize(width: width, height: height))

    let res2name = outputDir.path.appendingPathComponent(path: file.nameExcludingExtension + "@2x." + (file.extension ?? ""))
    resizeImage(original: file.path, newName: res2name, size: CGSize(width: 2 * width, height: 2 * height))

    let res3name = outputDir.path.appendingPathComponent(path: file.nameExcludingExtension + "@3x." + (file.extension ?? ""))
    resizeImage(original: file.path, newName: res3name, size: CGSize(width: 3 * width, height: 3 * height))
}
