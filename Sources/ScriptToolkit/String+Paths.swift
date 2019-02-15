//
//  String+Paths.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Foundation

public extension String {

    public var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }

    public var pathExtension: String {
        return (self as NSString).pathExtension
    }

    public var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }

    public var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }

    public var pathComponents: [String] {
        return (self as NSString).pathComponents
    }

    public func appendingPathComponent(path: String) -> String {
        let nsString = self as NSString
        return nsString.appendingPathComponent(path)
    }

    public func appendingPathExtension(ext: String) -> String? {
        let nsString = self as NSString
        return nsString.appendingPathExtension(ext)
    }
}
