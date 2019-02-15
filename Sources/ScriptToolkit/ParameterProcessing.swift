//
//  ParameterProcessing.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 15.02.2019.
//

import Foundation
import SwiftShell
import Moderator

public protocol StringAssignable {
    mutating func assign(value: String) throws
}

extension Int: StringAssignable {
    public mutating func assign(value: String) throws {
        if let intValue = Int(value) {
            self = intValue
        }
        else {
            throw ArgumentError(errormessage: "Argument is not integer")
        }
    }
}

extension Optional: StringAssignable where Wrapped == String {
    public mutating func assign(value: String) throws {
        self = value
    }
}


public protocol OptionalyHavingValue {
    func hasValue() -> Bool
}

extension Int: OptionalyHavingValue {
    public func hasValue() -> Bool {
        return true
    }
}

extension Optional: OptionalyHavingValue where Wrapped == String {
    public func hasValue() -> Bool {
        return self != .none
    }
}

public func askForMissingParams<T: StringAssignable & OptionalyHavingValue>(_ params: [(Argument<T>, FutureValue<T>)]) throws {
    for paramItem in params {
        // Skip already assigned parameters
        if paramItem.1.value.hasValue() { continue }

        let paramTitle = paramItem.0.usage?.title ?? ""
        print("\(paramTitle):")
        let input = readLine() ?? ""
        try paramItem.1.value.assign(value: input)
    }
}
