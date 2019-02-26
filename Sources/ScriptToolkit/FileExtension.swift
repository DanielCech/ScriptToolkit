//
//  File.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Foundation
import Files
import SwiftShell

public extension File {

    public func nameWithSuffix(_ suffix: String) -> String {
        if let unwrappedExtension = `extension` {
            return nameExcludingExtension + suffix + "." + unwrappedExtension
        }
        else {
            return nameExcludingExtension + suffix
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Duplication

    @discardableResult public func createDuplicate(withName newName: String, keepExtension: Bool = true, overwrite: Bool = true) throws -> File? {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return nil }

        guard let parent = parent else {
            throw OperationError.renameFailed(self)
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
        } catch {
            throw OperationError.renameFailed(self)
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Photo Processing

    func incorporateFile(using folderRecords: [(Folder, [Int])]) throws {
        print("\(path)")
        let numberString = nameExcludingExtension.replacingOccurrences(of: "IMG_", with: "")
        var lastMaximum: Int?
        if let number = Int(numberString) {

            var moved = false
            for folderRecord in folderRecords {
                if let firstIndex = folderRecord.1.first, let lastIndex = folderRecord.1.last, number >= firstIndex, number <= lastIndex {
                    try move(to: folderRecord.0)
                    moved = true
                    break
                }

                if let unwrappedLastMaximum = lastMaximum, let firstIndex = folderRecord.1.first, unwrappedLastMaximum <= number, firstIndex >= number {
                    try move(to: folderRecord.0)
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

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Resize image

    @discardableResult public func resizeImage(newName: String, size: CGSize, overwrite: Bool = true) throws -> File? {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return nil }
        run("/usr/local/bin/convert", path, "-resize", "\(size.width)x\(size.height)",newName)
        return try File(path: newName)
    }

    public func resizeAt123x(width: Int, height: Int, outputDir: Folder, overwrite: Bool = true) throws {
        print(name)

        let res1name = outputDir.path.appendingPathComponent(path: name)
        try resizeImage(newName: res1name, size: CGSize(width: width, height: height), overwrite: overwrite)

        let res2name = outputDir.path.appendingPathComponent(path: nameExcludingExtension + "@2x." + (self.extension ?? ""))
        try resizeImage(newName: res2name, size: CGSize(width: 2 * width, height: 2 * height), overwrite: overwrite)

        let res3name = outputDir.path.appendingPathComponent(path: nameExcludingExtension + "@3x." + (self.extension ?? ""))
        try resizeImage(newName: res3name, size: CGSize(width: 3 * width, height: 3 * height), overwrite: overwrite)
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Audio Processing

    @discardableResult public func slowDownAudio(newName: String, percent: Float, overwrite: Bool = true) throws -> File? {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return nil }
        run(ScriptToolkit.soxPath, path, newName, "tempo", "-s", String(percent))
        return try File(path: newName)
    }

    @discardableResult public func convertToWav(newName: String, overwrite: Bool = true) throws -> File? {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return nil }
        run(ScriptToolkit.ffmpegPath, "-i", path, "-sample_rate", "44100", newName.deletingPathExtension + ".wav")
        return try File(path: newName)
    }

    @discardableResult public func convertToM4A(newName: String, overwrite: Bool = true) throws -> File? {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return nil }
        run(ScriptToolkit.ffmpegPath, "-i", path, "-sample_rate", "44100", newName.deletingPathExtension + ".m4a")
        return try File(path: newName)
    }

    @discardableResult public func addSilence(newName: String, overwrite: Bool = true) throws -> File? {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return nil }
        run(ScriptToolkit.soxPath, ScriptToolkit.silenceFilePath, path, newName)
        return try File(path: newName)
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - PDF

    @discardableResult public func cropPDF(newName: String, insets: NSEdgeInsets, overwrite: Bool = true) throws -> File? {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return nil }
        run(ScriptToolkit.pdfCropPath, "--margins", insets.left, insets.top, insets.right, insets.bottom, path, newName)
        return try File(path: newName)
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Find files

    public func findFirstFile(name: String, root: Folder) -> File? {
        for file in root.makeFileSequence(recursive: true) {
            if file.name == name {
                return file
            }
        }
        return nil
    }

    public func findFiles(name: String, root: Folder) -> [File] {
        var foundFiles = [File]()
        for file in root.makeFileSequence(recursive: true) {
            if file.name == name {
                foundFiles.append(file)
            }
        }
        return foundFiles
    }

    public func findFiles(regex: String, root: Folder) -> [File] {
        var foundFiles = [File]()
        for file in root.makeFileSequence(recursive: true) {
            if !matches(for: regex, in: file.name).isEmpty {
                foundFiles.append(file)
            }
        }
        return foundFiles
    }
}
