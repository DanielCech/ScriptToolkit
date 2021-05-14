//
//  Path.swift
//  Toolkit
//
//  Created by Daniel Cech on 14/05/2021.
//

import Foundation

public typealias Path = String

public extension Path {
    static func from(_ text: String) -> Path {
        return text.withoutEscapes
    }
    
    static func paths(form text: String) throws -> [Path] {
        return text.splittedBySpaces().map { $0.withoutEscapes }
    }
}
