//
//  ScriptToolkit.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Foundation
import Files
import SwiftShell

public struct ScriptToolkit {
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()
}

////////////////////////////////////////////////////////////////////////////////
// MARK: - Helpers

@discardableResult public func runAndDebug(_ executable: String, _ args: Any ..., combineOutput: Bool = false) -> RunOutput {
    let stringargs = args.flatten().map(String.init(describing:))
    print(executable, String(describing: stringargs))
    return run(executable, args, combineOutput: combineOutput)
}

func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}



