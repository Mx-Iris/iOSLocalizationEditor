//
//  LocalizationString.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation

/// Class representing single localization string in form of key: "value"; as found in strings files
public final class LocalizationString {
    public let key: String
    public private(set) var value: String
    public private(set) var message: String?

    public init(key: String, value: String, message: String?) {
        self.key = key
        self.value = value
        self.message = message
    }

    public func update(newValue: String) {
        value = newValue
    }
}

// MARK: Description

extension LocalizationString: CustomStringConvertible {
    public var description: String {
        return "\(key) = \(value)" + (message.map { "/* \($0) */" } ?? "")
    }
}

// MARK: Comparison

extension LocalizationString: Comparable {
    public static func < (lhs: LocalizationString, rhs: LocalizationString) -> Bool {
        return lhs.key < rhs.key
    }

    public static func == (lhs: LocalizationString, rhs: LocalizationString) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
}
