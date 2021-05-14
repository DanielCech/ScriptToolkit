//
//  File+AudioProcessing.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Foundation
import Files
import SwiftShell


// MARK: - Audio Processing

public extension File {
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
    
}
