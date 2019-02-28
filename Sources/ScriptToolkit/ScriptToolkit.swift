//
//  ScriptToolkit.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Foundation
import Files
import SwiftShell

public enum ScriptError: Error, CustomStringConvertible {
    case fileExists(message: String)
    case fileNotFound(message: String)
    case folderExists(message: String)
    case folderNotFound(message: String)
    case argumentError(message: String)
    case moreInfoNeeded(message: String)

    public var description: String {
        let prefix = "💥 error: "
        var errorDescription = ""

        switch self {
        case let .fileExists(message):
            errorDescription = "file exists: \(message)"

        case let .fileNotFound(message):
            errorDescription = "file not found: \(message)"

        case let .folderExists(message):
            errorDescription = "folder exists: \(message)"

        case let .folderNotFound(message):
            errorDescription = "folder not found: \(message)"

        case let .argumentError(message):
            errorDescription = "invalid argument: \(message)"

        case let .moreInfoNeeded(message):
            errorDescription = "more info needed: \(message)"

        default:
            errorDescription = "general failure"

        }

        return prefix + errorDescription
    }
}

public struct ScriptToolkit {

    // Setup of absolute paths
    public static let pdfCropPath = "/usr/local/bin/pdfcrop"
    public static let ffmpegPath = "/usr/local/bin/ffmpeg"
    public static let soxPath = "/usr/local/bin/sox"
    public static let convertPath = "/usr/local/bin/convert"
    public static let compositePath = "/usr/local/bin/composite"
    public static let silenceFilePath = "/Users/dan/Documents/[Development]/[Projects]/SwiftScripts/practise/silence.wav"


    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()
}

////////////////////////////////////////////////////////////////////////////////
// MARK: - Helpers

@discardableResult public func runAndDebug(_ executable: String, _ args: Any ..., combineOutput: Bool = false) -> RunOutput {
    let stringargs = args.map(String.init(describing:))
    print(executable, String(describing: stringargs.joined(separator: " ")))
    return run(executable, args, combineOutput: combineOutput)
}

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



