//
//  String+Paths.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Foundation

/// Path manipulation methods that are available for NSString
public extension String {
    var lastPathComponent: String {
        (self as NSString).lastPathComponent
    }

    var pathExtension: String {
        (self as NSString).pathExtension
    }

    var deletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }

    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }

    var pathComponents: [String] {
        (self as NSString).pathComponents
    }
    
    var isAbsolutePath: Bool {
        (self as NSString).isAbsolutePath
    }
    
    var withoutEscapes: String {
        replacingOccurrences(of: "\\", with: "")
    }

    func appendingPathComponent(path: String) -> String {
        let nsString = self as NSString
        return nsString.appendingPathComponent(path)
    }

    func appendingPathExtension(ext: String) -> String? {
        let nsString = self as NSString
        return nsString.appendingPathExtension(ext)
    }
    
    /// Returns the path without trailing slash
    func withoutSlash() -> String {
        if last == "/" {
            return String(prefix(count - 1))
        }
        return self
    }
}
