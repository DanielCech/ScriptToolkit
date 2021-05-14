//
//  File+PDF.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Foundation
import Files
import SwiftShell


// MARK: - PDF

public extension File {
    /// Open PDF file
    func openPDF(pdfPage: Int?) {
        let scriptSource: String
        
        if let unwrappedPdfPage = pdfPage {
            scriptSource =
                """
                tell application "Adobe Acrobat Reader DC"
                    open POSIX file "{{file}}" options "page={{page}}"
                end tell
                """
                .replacingOccurrences(of: "{{file}}", with: self.path)
                .replacingOccurrences(of: "{{page}}", with: String(unwrappedPdfPage))
        }
        else {
            scriptSource =
                """
                tell application "Adobe Acrobat Reader DC"
                    open POSIX file "{{file}}"
                end tell
                """
                .replacingOccurrences(of: "{{file}}", with: self.path)
        }
        
        let script = NSAppleScript(source: scriptSource)
        script?.executeAndReturnError(nil)
    }
    
    
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
