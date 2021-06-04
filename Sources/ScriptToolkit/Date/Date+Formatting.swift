//
//  Date+Formatting.swift
//  Toolkit
//
//  Created by Daniel Cech on 21.05.2021.
//

import Foundation

extension Date {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var shortString: String {
        Date.dateFormatter.string(from: self)
    }
}
