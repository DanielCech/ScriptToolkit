//
//  ScriptToolkit.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Foundation
import Files
import SwiftShell
import Moderator

public struct ScriptToolkit {

    // MARK: - Setup of absolute paths
    
    /// PDFCrop - part of TeXlive distribution
    public static let pdfCropPath = "/usr/local/bin/pdfcrop"
    
    /// FFMPEG toolkit
    public static let ffmpegPath = "/usr/local/bin/ffmpeg"
    
    /// Sound eXchange tool for sound manipulation
    public static let soxPath = "/usr/local/bin/sox"
    
    /// ImageMagick
    public static let convertPath = "/usr/local/bin/convert"
    
    /// Short audio with silence
    public static let silenceFilePath = "/Users/dan/Documents/[Development]/[Projects]/SwiftScripts/practise/silence.wav"


    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()
}

////////////////////////////////////////////////////////////////////////////////
// MARK: - Helpers

/// Running command line tool with debug logs
@discardableResult public func runAndDebug(_ executable: String, _ args: Any ..., combineOutput: Bool = false) -> RunOutput {
    let stringargs = args.map(String.init(describing:))
    print(executable, String(describing: stringargs.joined(separator: " • ")))
    return run(executable, args, combineOutput: combineOutput)
}

/// A list of regular expression matches
public func matches(for regex: String, in text: String) -> [String] {
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

/// Run shell command in bash
@discardableResult public func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    return output
}



