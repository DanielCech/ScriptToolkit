//
//  File+VideoProcessing.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Foundation
import Files
import SwiftShell


// MARK: - Video Processing

public extension File {
    /// Video reduction to smaller size and quality
    @discardableResult func reduceVideo(newName: String, overwrite: Bool = true) throws -> File {
        if FileManager.default.fileExists(atPath: newName) {
            if !overwrite { return try File(path: newName) }
            try FileManager.default.removeItem(atPath: newName)
        }

        run(ScriptToolkit.ffmpegPath, "-i", path, "-vf", "scale=iw/2:ih/2", newName)
        return try File(path: newName)
    }
}
