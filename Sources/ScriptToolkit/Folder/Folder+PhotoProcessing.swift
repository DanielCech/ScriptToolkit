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

        print("📷 Processing EXIFtool...")

        if byCameraModel {
            // Process JPG dirs using exiftool
            for dir in inputFolder.subfolders {
                run("/usr/local/bin/exiftool", "-Directory<Model", "-d", "%Y-%m-%d \(dir.name)", dir.path)
            }

            // Process JPG using exiftool
            for file in inputFolder.files {
                run("/usr/local/bin/exiftool", "-Directory<Model", "-d", "%Y-%m-%d", file.path)
            }
            return
        }

        // Process JPG dirs using exiftool
        for dir in inputFolder.subfolders {
            run("/usr/local/bin/exiftool", "-Directory<DateTimeOriginal", "-d", "%Y-%m-%d \(dir.name)", dir.path)
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
                    run("/usr/local/bin/exiftool", "-Directory<DateTimeOriginal", "-d", "%Y-%m-%d", file.path)

                case "png":
                    run("/usr/local/bin/exiftool", "-Directory<DateCreated", "-d", "%Y-%m-%d", file.path)

                case "m4v":
                    if !processM4V {
                        run("/usr/local/bin/exiftool", "-Directory<ContentCreateDate", "-d", "%Y-%m-%d", file.path)
                    }

                case "mp4":
                    run("/usr/local/bin/exiftool", "-Directory<FileAccessDate", "-d", "%Y-%m-%d", file.path)

                case "mov":
                    run("/usr/local/bin/exiftool", "-Directory<CreationDate", "-d", "%Y-%m-%d", file.path)

                default:
                    break
                }
            }
        }
    }

    /// Organize photos by metadata
    func organizePhotos() throws {
        print("📂 Organizing...")

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
