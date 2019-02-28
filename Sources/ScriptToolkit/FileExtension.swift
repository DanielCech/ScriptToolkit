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
    // MARK: - Modification date

    public func modificationDate() throws -> Date  {

        let fileAttributes = try FileManager.default.attributesOfItem(atPath: path) as [FileAttributeKey: Any]
        let modificationDate = fileAttributes[.modificationDate] as! Date

        return modificationDate
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Tag file

    public func tag(copy: Bool) throws {
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

    @discardableResult public func resizeImage(newName: String, size: CGSize, overwrite: Bool = true) throws -> File {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return try File(path: newName) }
        run(ScriptToolkit.convertPath, path, "-resize", "\(Int(size.width))x\(Int(size.height))",newName)
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

    @discardableResult public func slowDownAudio(newName: String, percent: Float, overwrite: Bool = true) throws -> File {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return try File(path: newName) }
        run(ScriptToolkit.soxPath, path, newName, "tempo", "-s", String(percent))
        return try File(path: newName)
    }

    @discardableResult public func convertToWav(newName: String, overwrite: Bool = true) throws -> File {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return try File(path: newName) }
        run(ScriptToolkit.ffmpegPath, "-i", path, "-sample_rate", "44100", newName.deletingPathExtension + ".wav")
        return try File(path: newName)
    }

    @discardableResult public func convertToM4A(newName: String, overwrite: Bool = true) throws -> File {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return try File(path: newName) }
        run(ScriptToolkit.ffmpegPath, "-i", path, "-sample_rate", "44100", newName.deletingPathExtension + ".m4a")
        return try File(path: newName)
    }

    @discardableResult public func addSilence(newName: String, overwrite: Bool = true) throws -> File {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return try File(path: newName) }
        run(ScriptToolkit.soxPath, ScriptToolkit.silenceFilePath, path, newName)
        return try File(path: newName)
    }

    func prepareSongForPractise(outputFolder: Folder) throws {
        print(name + ":")

        let originalWavFile: File
        if let ext = `extension`, ext.lowercased() != "wav" {
            print("  Converting to wav")
            originalWavFile = try convertToWav(newName: "wav-file.wav")
        }
        else {
            originalWavFile = self
        }

        print("  Converting to 75% speed")
        let file75 = try originalWavFile.slowDownAudio(newName: "tempo-75.wav", percent: 0.75)
        print("  Converting to 90% speed")
        let file90 = try originalWavFile.slowDownAudio(newName: "tempo-90.wav", percent: 0.9)

        print("  Adding initial silence to 75% speed file")
        let silencedFile75 = try file75.addSilence(newName: "silence-75.wav")
        print("  Adding initial silence to 90% speed file")
        let silencedFile90 = try file90.addSilence(newName: "silence-90.wav")
        print("  Adding initial silence to 100% speed file")
        let silencedFile100 = try originalWavFile.addSilence(newName: "silence-100.wav")

        print("  Converting to M4A")
        let silencedM4AFile75 = try silencedFile75.convertToM4A(newName: nameExcludingExtension + "@75.m4a")
        let silencedM4AFile90 = try silencedFile90.convertToM4A(newName: nameExcludingExtension + "@90.m4a")
        let silencedM4AFile100 = try silencedFile100.convertToM4A(newName: nameExcludingExtension + "@100.m4a")

        // Move result to output dir
        print("  Moving to destination folder")
        try silencedM4AFile75.move(to: outputFolder)
        try silencedM4AFile90.move(to: outputFolder)
        try silencedM4AFile100.move(to: outputFolder)

        // Clean up
        try originalWavFile.delete()
        try file75.delete()
        try file90.delete()
        try silencedFile75.delete()
        try silencedFile90.delete()
        try silencedFile100.delete()
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - PDF

    @discardableResult public func cropPDF(newName: String, insets: NSEdgeInsets, overwrite: Bool = true) throws -> File {
        if !overwrite && FileManager.default.fileExists(atPath: newName) { return try File(path: newName) }
        run(ScriptToolkit.pdfCropPath, "--margins", insets.left, insets.top, insets.right, insets.bottom, path, newName)
        return try File(path: newName)
    }

}
