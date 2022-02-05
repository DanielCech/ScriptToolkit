//
//  Folder+PhotoProcessing.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Files
import Foundation
import SwiftShell

// MARK: - Photo Processing

public extension Folder {
    
    /// Get photo metadata
    func exifTool(byCameraModel: Bool, processM4V: Bool) throws {
        let inputFolder = try Folder(path: path)

        logger.print(prompt: "📷", text: "Processing EXIFtool...")

        if byCameraModel {
            // Process JPG dirs using exiftool
            for dir in inputFolder.subfolders {
                run(ScriptToolkit.exifToolPath, "-Directory<Model", "-d", "%Y-%m-%d \(dir.name)", dir.path)
            }

            // Process JPG using exiftool
            for file in inputFolder.files {
                run(ScriptToolkit.exifToolPath, "-Directory<Model", "-d", "%Y-%m-%d", file.path)
            }
            return
        }

        // Process JPG dirs using exiftool
        for dir in inputFolder.subfolders {
            run(ScriptToolkit.exifToolPath, "-Directory<DateTimeOriginal", "-d", "%Y-%m-%d \(dir.name)", dir.path)
        }

        var originalFolders = inputFolder
            .subfolders
            .filter { matches(for: "^\\d\\d\\d\\d-\\d\\d-\\d\\d.*$", in: $0.name).isEmpty }

        originalFolders.append(inputFolder)

        // Support of M4V
        for folder in originalFolders {
            for file in folder.files.includingHidden {
                switch file.extension?.lowercased() ?? "" {
                case "jpg", "jpeg":
                    run(ScriptToolkit.exifToolPath, "-Directory<DateTimeOriginal", "-d", "%Y-%m-%d", file.path)

                case "png":
                    run(ScriptToolkit.exifToolPath, "-Directory<DateCreated", "-d", "%Y-%m-%d", file.path)

                case "m4v":
                    if !processM4V {
                        run(ScriptToolkit.exifToolPath, "-Directory<ContentCreateDate", "-d", "%Y-%m-%d", file.path)
                    }

                case "mp4":
                    run(ScriptToolkit.exifToolPath, "-Directory<FileAccessDate", "-d", "%Y-%m-%d", file.path)

                case "mov":
                    run(ScriptToolkit.exifToolPath, "-Directory<CreationDate", "-d", "%Y-%m-%d", file.path)

                default:
                    break
                }
            }
        }
    }

    /// Organize photos by metadata
    func organizePhotos() throws {
        logger.print(prompt: "📂", text: "Organizing...")

        var folderRecords = [(Folder, [Int])]()

        let sortedSubfolders = subfolders
            .filter { !matches(for: "^\\d\\d\\d\\d-\\d\\d-\\d\\d.*$", in: $0.name).isEmpty }
            .sorted { $0.name < $1.name }

        for dir in sortedSubfolders {
            let indexes = dir.files
                .map { $0.nameExcludingExtension.replacingOccurrences(of: "IMG_", with: "") }
                .compactMap { Int($0) }
                .sorted()
            folderRecords.append((dir, indexes))
        }

        var originalFolders = subfolders
            .filter { matches(for: "^\\d\\d\\d\\d-\\d\\d-\\d\\d.*$", in: $0.name).isEmpty }

        originalFolders.append(self)

        for folder in originalFolders {
            for file in folder.files.includingHidden {
                try file.incorporateFile(using: folderRecords)
            }
        }
    }
}
