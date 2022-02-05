//
//  ScriptToolkit.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Files
import Foundation
import Moderator
import SwiftShell
import AppKit

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
    
    /// EXIFtool
    public static let exifToolPath = "/opt/homebrew/bin/exiftool"

    /// Short audio with silence
    public static let silenceFilePath = "/Users/dan/Documents/[Development]/[Projects]/SwiftScripts/practise/silence.wav"

    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()
    
    public static let inDebugger = amIBeingDebugged()
}

// MARK: - Helpers

/// Running command line tool with debug logs
@discardableResult public func runAndDebug(_ executable: String, _ args: Any ..., combineOutput: Bool = false) -> RunOutput {
    let stringargs = args.map(String.init(describing:))
    logger.print(executable + String(describing: stringargs.joined(separator: " • ")))
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
    }
    catch {
        logger.print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

/// Minimize 3
public func min3(a: Int, b: Int, c: Int) -> Int {
    return min( min(a, c), min(b, c))
}

/// Run shell command in bash
@discardableResult public func shell(_ command: String) -> String {
    let task = Process()
//    let pipe = Pipe()

    task.standardInput = FileHandle.standardInput
    task.standardOutput = FileHandle.standardOutput//pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
    task.waitUntilExit()
    
    return ""

//    let data = pipe.fileHandleForReading.readDataToEndOfFile()
//    let output = String(data: data, encoding: .utf8)!
//
//    return output
}

/// Detailed debug in string
public func dumpString(_ something: Any) -> String {
    var dumped = String()
    dump(something, to: &dumped)
    return dumped
}

/// Is this code running from Xcode?
func amIBeingDebugged() -> Bool {
    var info = kinfo_proc()
    var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    assert(junk == 0, "sysctl failed")
    return (info.kp_proc.p_flag & P_TRACED) != 0
}

public func input() -> String {
    let keyboard = FileHandle.standardInput
    let inputData = keyboard.availableData
    return NSString(data: inputData, encoding:String.Encoding.utf8.rawValue)! as String
}

public func getLine() -> String {
    var buf = String()
    var c = getchar()
    // 10 is ascii code for newline
    while c != EOF && c != 10 {
        buf.append(Character(UnicodeScalar(UInt32(c))!))
        c = getchar()
    }
    return buf
}

public func getStringFromAlert(title: String, question: String, defaultValue: String?) -> String {
    let msg = NSAlert()
    msg.addButton(withTitle: "OK")      // 1st button
    msg.addButton(withTitle: "Cancel")  // 2nd button
    msg.messageText = title
    msg.informativeText = question

    let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    txt.stringValue = defaultValue ?? ""

    msg.accessoryView = txt
    let response: NSApplication.ModalResponse = msg.runModal()

    sleep(500)
        
    if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
        return txt.stringValue
    } else {
        return ""
    }
    
    
}
