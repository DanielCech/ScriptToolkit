//
//  Interaction.swift
//  Toolkit
//
//  Created by Daniel Cech on 28.05.2021.
//

import Foundation

public let interaction = Interaction()

public class Interaction {
    
    // MARK: - Bool
    
    public func getBoolValue(
        text: String,
        defaultValue: Bool? = nil,
        prompt: String? = nil
    ) -> Bool {
        
        while true {
            var line = "\(prompt ?? "▶️")  \(text)"
            
            if let unwrappedDefaultValue = defaultValue {
                if unwrappedDefaultValue {
                    line += " [Y|n] ▷ "
                }
                else {
                    line += " [y|N] ▷ "
                }
            }
            else {
                line += " [y|n] ▷ "
            }
            
            logger.print(line, terminator: "")
            print("")
            if let input = textInput(defaultValue: nil)?.trimmingCharacters(in: .whitespaces).lowercased() {
                
                switch input {
                case "y":
                    return true
                case "n":
                    return false
                case "":
                    if let unwrappedDefaultValue = defaultValue {
                        return unwrappedDefaultValue
                    }
                    continue
                default:
                    continue
                }
            }
        }
    }
    
    public func getBoolOptionalValue(
        text: String,
        defaultValue: Bool? = nil,
        prompt: String? = nil
    ) -> Bool? {
        while true {
            var line = "\(prompt ?? "▶️")  \(text)"
            
            if let unwrappedDefaultValue = defaultValue {
                if unwrappedDefaultValue {
                    line += " [Y|n|*] ▷ "
                }
                else {
                    line += " [y|N|*] ▷ "
                }
            }
            else {
                line += " [y|n|*] ▷ "
            }
            
            logger.print(line, terminator: "")
            print("")
            if let input = textInput(defaultValue: nil)?.trimmingCharacters(in: .whitespaces).lowercased() {
                
                switch input {
                case "y":
                    return true
                case "n":
                    return false
                case "-":
                    return nil
                case "":
                    if let unwrappedDefaultValue = defaultValue {
                        return unwrappedDefaultValue
                    }
                    continue
                default:
                    continue
                }
            }
        }
    }
    
    // MARK: - Int
    
    public func getIntValue(
        text: String,
        defaultValue: Int? = nil,
        prompt: String? = nil
    ) -> Int {
        while true {
            var line = "\(prompt ?? "▶️")  \(text)"
            
            if let unwrappedDefaultValue = defaultValue {
                line += " [\(unwrappedDefaultValue)] ▷ "
            }
            else {
                line += " ▷ "
            }
            
            logger.print(line, terminator: "")
            print("")
            if let input = textInput(defaultValue: nil)?.trimmingCharacters(in: .whitespaces) {
                if let intValue = Int(input) {
                    return intValue
                }
                else if input == "" {
                    if let unwrappedDefaultValue = defaultValue {
                        return unwrappedDefaultValue
                    }
                }
            }
        }
    }
    
    public func getIntOptionalValue(
        text: String,
        defaultValue: Int? = nil,
        prompt: String? = nil
    ) -> Int? {
        while true {
            var line = "\(prompt ?? "▶️")  \(text)"
            
            if let unwrappedDefaultValue = defaultValue {
                line += " [\(unwrappedDefaultValue)|*] ▷ "
            }
            else {
                line += " ▷ "
            }
            
            logger.print(line, terminator: "")
            print("")
            if let input = textInput(defaultValue: nil)?.trimmingCharacters(in: .whitespaces) {
                if input == "-" {
                    return nil
                }
                else if input == "" {
                    if let unwrappedDefaultValue = defaultValue {
                        return unwrappedDefaultValue
                    }
                }
                else if let intValue = Int(input) {
                    return intValue
                }                
            }
        }
    }
    
    // MARK: - String
    
    public func getStringValue(
        text: String,
        options: [String]? = nil,
        defaultValue: String? = nil,
        prompt: String? = nil
    ) throws -> String {
        while true {
            var line = "\(prompt ?? "▶️")  \(text)"
            
            var suggestions = [String]()
            
            if let unwrappedDefaultValue = defaultValue {
                suggestions.append(unwrappedDefaultValue)
            }
            
            if let unwrappedOptions = options, !unwrappedOptions.isEmpty {
                suggestions.append("?")
            }
            
            if suggestions.isEmpty {
                line += " ▷ "
            }
            else {
                line += " [\(suggestions.joined(separator: "|"))] ▷ "
            }
            
            logger.print(line, terminator: "")
            print("")
            if let input = textInput(defaultValue: nil)?.trimmingCharacters(in: .whitespaces) {
                if input == "" {
                    if let unwrappedDefaultValue = defaultValue {
                        return unwrappedDefaultValue
                    }
                    else {
                        continue
                    }
                }
                
                if input == "?" {
                    if let unwrappedOptions = options {
                        let result = selectStringValueFromOptions(text: "", options: unwrappedOptions)
                        if result.selected, let unwrappedValue = result.value {
                            return unwrappedValue
                        }
                    }
                    else {
                        continue
                    }
                }
                
                if let unwrappedOptions = options {
                    if unwrappedOptions.contains(input) {
                        return input
                    }
                    else {
                        let result = try selectStringValueFromOptions(text: text, options: unwrappedOptions.filter( { try $0.stringLookupMatch(text: text) }))
                        if result.selected, let unwrappedValue = result.value {
                            return unwrappedValue
                        }
                    }
                }
                else {
                    return input
                }
            }
        }
    }
    
    public func getStringOptionalValue(text: String, prompt: String? = nil) -> String? {
        return nil
    }
    
    // MARK: - Text Input
    
    public func textInput(defaultValue: String? = nil) -> String? {
        if amIBeingDebugged() {
            // Delete file contents
            try? (defaultValue ?? "").write(toFile: FileConstants.interactionFile, atomically: true, encoding: .utf8)
            shell("\"\(FileConstants.sublPath)\" \(FileConstants.interactionFile) --wait")
            return (try? String(contentsOfFile: FileConstants.interactionFile)) ?? ""
        }
        else {
            if let input = readLine(), !input.isEmpty {
                return input
            }
            return defaultValue
        }
    }
    
}

private extension Interaction {
    func selectStringValueFromOptions(text: String, options: [String], optional: Bool = false) -> (selected: Bool, value: String?) {
        for (index, option) in options.enumerated() {
            logger.print("#\(index+1). \(option)")
        }
        
        while true {
            logger.print(prompt: "#️⃣", text: "Select Index ▷ ", terminator: "")
            print("")
            if let input = textInput(defaultValue: nil)?.trimmingCharacters(in: .whitespaces) {
                if input == "" {
                    return (selected: false, value: nil)
                }
                if optional, input == "-" {
                    return (selected: true, value: nil)
                }
                
                if let inputInt = Int(input) {
                    if 1 ..< options.count ~= inputInt {
                        return (selected: true, value: options[inputInt])
                    }
                    else {
                        logger.print(prompt: "⚠️", text: "Error: invalid value")
                    }
                }
            }
        }
    }
}

private enum FileConstants {
    static let interactionFile = "/Users/dan/interaction.txt"
    static let sublPath = "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl"
}
