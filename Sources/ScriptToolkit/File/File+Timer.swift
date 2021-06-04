//
//  File+Timer.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Foundation
import Files
import SwiftShell

// MARK: - Video Processing

public extension File {
    func openMediaInVLC() {
        let scriptSource =
            """
            tell application "VLC"
                OpenURL "file://{{file}}"
                delay 5
                play
            end tell
            """
            .replacingOccurrences(of: "{{file}}", with: self.path.replacingOccurrences(of: " ", with: "%20"))
        
        let script = NSAppleScript(source: scriptSource)
        script?.executeAndReturnError(nil)
    }
    
    func open() {
        shell("open \"\(self.path)\"")
    }
}
