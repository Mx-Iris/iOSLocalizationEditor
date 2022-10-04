//
//  Localization.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation
import Utils
/// Complete localization for a single language. Represents a single strings file for a single language
///
public final class Localization {
    public let language: String
    public let path: String
    public private(set) var translations: [LocalizationString]

    public init(language: String, translations: [LocalizationString], path: String) {
        self.language = language
        self.translations = translations
        self.path = path
    }

    public subscript(key: String) -> LocalizationString? {
        if let existing = translations.first(where: { $0.key == key }) {
            return existing
        } else {
            return nil
        }
    }
    
    public func update(key: String, value: String, message: String?) {
        if let existing = translations.first(where: { $0.key == key }) {
            existing.update(newValue: value)
            return
        }

        let newTranslation = LocalizationString(key: key, value: value, message: message)
        translations = (translations + [newTranslation])
    }

    public func add(key: String, message: String?) -> LocalizationString {
        let newTranslation = LocalizationString(key: key, value: "", message: message)
        translations = (translations.filter { $0.key != key } + [newTranslation])
        return newTranslation
    }

    public func remove(key: String) {
        translations = translations.filter { $0.key != key }
    }

    public func move(with indexes: IndexSet, to toIndex: Int) {
        translations.move(with: indexes, to: toIndex)
    }
}

// MARK: Description

extension Localization: CustomStringConvertible {
    public var description: String {
        return language.uppercased()
    }
}

// MARK: Equality

extension Localization: Equatable {
    public static func == (lhs: Localization, rhs: Localization) -> Bool {
        return lhs.language == rhs.language && lhs.translations == rhs.translations && lhs.path == rhs.path
    }
}

// MARK: Debug description

extension Localization: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(language.uppercased()): \(translations.count) translations (\(path))"
    }
}
