import Foundation
import Files

public struct ScriptToolkit {
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()
}

public extension File {
    public func createDuplicate(withName newName: String, keepExtension: Bool = true) throws {
        guard let parent = parent else {
            throw OperationError.renameFailed(self)
        }

        var newName = newName

        if keepExtension {
            if let `extension` = `extension` {
                let extensionString = ".\(`extension`)"

                if !newName.hasSuffix(extensionString) {
                    newName += extensionString
                }
            }
        }

        let newPath = parent.path + newName

        do {
            try FileManager.default.copyItem(atPath: path, toPath: newPath)
        } catch {
            throw OperationError.renameFailed(self)
        }
    }
}

func fileModificationDate(_ file: String) throws -> Date  {

    let fileAttributes = try FileManager.default.attributesOfItem(atPath: file) as [FileAttributeKey: Any]
    let modificationDate = fileAttributes[.modificationDate] as! Date

    return modificationDate
}

public func tag(_ item: String, copy: Bool) throws {
    let date = try fileModificationDate(item)
    let suffix = ScriptToolkit.dateFormatter.string(from: date)
    for letter in "abcdefghijklmnopqrstuvwxyz" {
        let file = try File(path: item)
        let newPath = (file.parent?.path ?? "./")
        let newName = file.nameExcludingExtension + "(\(suffix + String(letter)))" + "." + (file.extension ?? "")

        if !FileManager.default.fileExists(atPath: newPath + newName) {
            if copy {
                try file.createDuplicate(withName: newName)
            }
            else {
                try file.rename(to: newName)
            }
            return
        }
    }
}
