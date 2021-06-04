//
//  String+Optional.swift
//  Minted
//
//  Created by Daniel Cech on 13/11/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        (self ?? "").isEmpty
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
