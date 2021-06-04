//
//  TimeInterval+Formatting.swift
//  Toolkit
//
//  Created by Daniel Cech on 21.05.2021.
//

import Foundation

extension TimeInterval {
    static let intervalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    var shortString: String {
        TimeInterval.intervalFormatter.string(from: self) ?? ""
    }
}
