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

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Photo Processing

    /// Moving file to appropriate folder during photo processing
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

    /// Image resizing
    @discardableResult func resizeImage(newName: String, size: CGSize, overwrite _: Bool = true) throws -> File {
        let image: NSImage? = NSImage(contentsOfFile: path)
        let newImage = image.map { try? $0.copy(size: size) } ?? nil
        if let unwrappedNewImage = newImage {
            try unwrappedNewImage.savePNGRepresentationToURL(url: URL(fileURLWithPath: newName))
        }

        return try File(path: newName)
    }

    /// Create three sizes of image for iOS asset
    func resizeAt123x(width: Int, height: Int, outputDir: Folder, overwrite: Bool = true) throws {
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

    /// Slow down audio
    @discardableResult func slowDownAudio(newName: String, percent: Float, overwrite: Bool = true) throws -> File {
        if FileManager.default.fileExists(atPath: newName) {
            if !overwrite { return try File(path: newName) }
            try FileManager.default.removeItem(atPath: newName)
        }

        runAndDebug(ScriptToolkit.soxPath, path, newName, "tempo", "-s", String(percent))
        return try File(path: newName)
    }

    /// Conversion to .wav
    @discardableResult func convertToWav(newName: String, overwrite: Bool = true) throws -> File {
        if FileManager.default.fileExists(atPath: newName) {
            if !overwrite { return try File(path: newName) }
            try FileManager.default.removeItem(atPath: newName)
        }

        runAndDebug(ScriptToolkit.ffmpegPath, "-i", path, "-sample_rate", "44100", newName.deletingPathExtension + ".wav")
        return try File(path: newName)
    }

    /// Sample rate normalization
    @discardableResult func normalizeSampleRate(newName: String, overwrite: Bool = true) throws -> File {
        if FileManager.default.fileExists(atPath: newName) {
            if !overwrite { return try File(path: newName) }
            try FileManager.default.removeItem(atPath: newName)
        }

        runAndDebug(ScriptToolkit.soxPath, path, "-r", "44100", "--channels", "2", newName)
        return try File(path: newName)
    }

    /// Conversion to .m4a
    @discardableResult func convertToM4A(newName: String, overwrite: Bool = true) throws -> File {
        if FileManager.default.fileExists(atPath: newName) {
            if !overwrite { return try File(path: newName) }
            try FileManager.default.removeItem(atPath: newName)
        }

        runAndDebug(ScriptToolkit.ffmpegPath, "-i", path, "-sample_rate", "44100", newName.deletingPathExtension + ".m4a")
        return try File(path: newName)
    }

    /// Add a 5s silence and the begining of audio file
    @discardableResult func addSilence(newName: String, overwrite: Bool = true) throws -> File {
        if FileManager.default.fileExists(atPath: newName) {
            if !overwrite { return try File(path: newName) }
            try FileManager.default.removeItem(atPath: newName)
        }

        runAndDebug(ScriptToolkit.soxPath, ScriptToolkit.silenceFilePath, path, newName)
        return try File(path: newName)
    }

    /// Prepare song for practise - generate audio in 50%, 75%, 90% and 100% speed
    func prepareSongForPractise(outputFolder: Folder, overwrite: Bool = true) throws {
        let inputFolder = parent!

        let fileName50 = nameExcludingExtension + "@50.m4a"
        let fileName75 = nameExcludingExtension + "@75.m4a"
        let fileName90 = nameExcludingExtension + "@90.m4a"
        let fileName100 = nameExcludingExtension + "@100.m4a"

        if !overwrite {
            let outputPath = outputFolder.path
            if FileManager.default.fileExists(atPath: outputPath.appendingPathComponent(path: fileName50)),
                FileManager.default.fileExists(atPath: outputPath.appendingPathComponent(path: fileName75)),
                FileManager.default.fileExists(atPath: outputPath.appendingPathComponent(path: fileName90)),
                FileManager.default.fileExists(atPath: outputPath.appendingPathComponent(path: fileName100)) { return }
        }

        print(name + ":")

        let originalWavFile: File
        if let ext = `extension`, ext.lowercased() != "wav" {
            print("  Converting to wav")
            originalWavFile = try convertToWav(newName: inputFolder.path.appendingPathComponent(path: "wav-file.wav"))
        }
        else {
            originalWavFile = self
        }

        print("  Normalizing sample rate")
        let normWavFile = try originalWavFile.normalizeSampleRate(newName: inputFolder.path.appendingPathComponent(path: "wav-file-norm.wav"))

        print("  Converting to 50% speed")
        let file50 = try normWavFile.slowDownAudio(newName: inputFolder.path.appendingPathComponent(path: "tempo-50.wav"), percent: 0.5)
        print("  Converting to 75% speed")
        let file75 = try normWavFile.slowDownAudio(newName: inputFolder.path.appendingPathComponent(path: "tempo-75.wav"), percent: 0.75)
        print("  Converting to 90% speed")
        let file90 = try normWavFile.slowDownAudio(newName: inputFolder.path.appendingPathComponent(path: "tempo-90.wav"), percent: 0.9)

        print("  Adding initial silence to 50% speed file")
        let silencedFile50 = try file50.addSilence(newName: inputFolder.path.appendingPathComponent(path: "silence-50.wav"))
        print("  Adding initial silence to 75% speed file")
        let silencedFile75 = try file75.addSilence(newName: inputFolder.path.appendingPathComponent(path: "silence-75.wav"))
        print("  Adding initial silence to 90% speed file")
        let silencedFile90 = try file90.addSilence(newName: inputFolder.path.appendingPathComponent(path: "silence-90.wav"))
        print("  Adding initial silence to 100% speed file")
        let silencedFile100 = try normWavFile.addSilence(newName: inputFolder.path.appendingPathComponent(path: "silence-100.wav"))

        print("  Converting to M4A")
        let silencedM4AFile50 = try silencedFile50.convertToM4A(newName: inputFolder.path.appendingPathComponent(path: fileName50))
        let silencedM4AFile75 = try silencedFile75.convertToM4A(newName: inputFolder.path.appendingPathComponent(path: fileName75))
        let silencedM4AFile90 = try silencedFile90.convertToM4A(newName: inputFolder.path.appendingPathComponent(path: fileName90))
        let silencedM4AFile100 = try silencedFile100.convertToM4A(newName: inputFolder.path.appendingPathComponent(path: fileName100))

        // Move result to output dir
        print("  Moving to destination folder")
        try silencedM4AFile50.move(to: outputFolder)
        try silencedM4AFile75.move(to: outputFolder)
        try silencedM4AFile90.move(to: outputFolder)
        try silencedM4AFile100.move(to: outputFolder)

        // Clean up
        try originalWavFile.delete()
        try file50.delete()
        try file75.delete()
        try file90.delete()
        try silencedFile50.delete()
        try silencedFile75.delete()
        try silencedFile90.delete()
        try silencedFile100.delete()
        try normWavFile.delete()
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Video Processing

    /// Video reduction to smaller size and quality
    @discardableResult func reduceVideo(newName: String, overwrite: Bool = true) throws -> File {
        if FileManager.default.fileExists(atPath: newName) {
            if !overwrite { return try File(path: newName) }
            try FileManager.default.removeItem(atPath: newName)
        }

        run(ScriptToolkit.ffmpegPath, "-i", path, "-vf", "scale=iw/2:ih/2", newName)
        return try File(path: newName)
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - PDF

    /// Crop margins from PDF
    @discardableResult func cropPDF(newName: String, insets: NSEdgeInsets, overwrite: Bool = true) throws -> File {
        if FileManager.default.fileExists(atPath: newName) {
            if !overwrite { return try File(path: newName) }
            try FileManager.default.removeItem(atPath: newName)
        }

        let left = Int(insets.left)
        let top = Int(insets.top)
        let bottom = Int(insets.bottom)
        let right = Int(insets.right)

        main.currentdirectory = parent!.path
        run(bash: "\(ScriptToolkit.pdfCropPath) --margins '\(left) \(top) \(right) \(bottom)' \"\(name)\" \"\(newName)\"")

        return try File(path: newName)
    }
}
