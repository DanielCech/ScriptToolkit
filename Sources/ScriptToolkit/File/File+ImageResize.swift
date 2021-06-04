//
//  File+ImageResize.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import AppKit
import Files
import Foundation
import SwiftShell

// MARK: - Resize image

public extension File {
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
        logger.print(name)

        let res1name = outputDir.path.appendingPathComponent(path: name)
        try resizeImage(newName: res1name, size: CGSize(width: width, height: height), overwrite: overwrite)

        let res2name = outputDir.path.appendingPathComponent(path: nameExcludingExtension + "@2x." + (self.extension ?? ""))
        try resizeImage(newName: res2name, size: CGSize(width: 2 * width, height: 2 * height), overwrite: overwrite)

        let res3name = outputDir.path.appendingPathComponent(path: nameExcludingExtension + "@3x." + (self.extension ?? ""))
        try resizeImage(newName: res3name, size: CGSize(width: 3 * width, height: 3 * height), overwrite: overwrite)
    }
}


