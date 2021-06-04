//
//  Collection+Optional.swift
//  Toolkit
//
//  Created by Daniel Cech on 17.05.2021.
//

import Foundation

extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}
