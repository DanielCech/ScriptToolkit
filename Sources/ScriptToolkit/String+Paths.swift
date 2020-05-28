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
        return (self as NSString).lastPathComponent
    }

    var pathExtension: String {
        return (self as NSString).pathExtension
    }

    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }

    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }

    var pathComponents: [String] {
        return (self as NSString).pathComponents
    }

    func appendingPathComponent(path: String) -> String {
        let nsString = self as NSString
        return nsString.appendingPathComponent(path)
    }

    func appendingPathExtension(ext: String) -> String? {
        let nsString = self as NSString
        return nsString.appendingPathExtension(ext)
    }
}
