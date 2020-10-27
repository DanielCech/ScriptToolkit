//
//  ScriptError.swift
//  ScriptToolkit
//
//  Created by Dan on 06.03.2019.
//

import Foundation
import Moderator

public protocol PrintableError {
    var errorDescription: String { get }
}

public enum ScriptError: Error {
    case generalError(message: String)
    case fileExists(message: String)
    case fileNotFound(message: String)
    case folderExists(message: String)
    case folderNotFound(message: String)
    case argumentError(message: String)
    case moreInfoNeeded(message: String)
    case renameFailed(message: String)
}

extension ScriptError: PrintableError {
    public var errorDescription: String {
        let prefix = "💥 error: "
        var errorDescription = ""

        switch self {
        case let .generalError(message):
            errorDescription = message

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

        case let .renameFailed(message):
            errorDescription = "rename failed: \(message)"
        }

        return prefix + errorDescription
    }
}

extension ArgumentError: PrintableError {
    public var errorDescription: String {
        "💥 error: \(errormessage)"
    }
}
