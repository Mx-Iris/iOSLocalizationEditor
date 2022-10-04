//
//  LocalizationGroup.swift
//  LocalizationEditor
//
//  Created by Florian Agsteiner on 19.06.18.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation

/// Group of localizations, like Localizabe.strings, InfoPlist.strings, etc.
///
public final class LocalizationGroup {
    public let name: String
    public let path: String
    public let localizations: [Localization]

    public init(name: String, localizations: [Localization], path: String) {
        self.name = name
        self.localizations = localizations
        self.path = path
    }
}

// MARK: Description

extension LocalizationGroup: CustomStringConvertible {
    public var description: String {
        return name
    }
}

// MARK: Comparison

extension LocalizationGroup: Comparable {
    public static func < (lhs: LocalizationGroup, rhs: LocalizationGroup) -> Bool {
        return lhs.name < rhs.name
    }

    public static func == (lhs: LocalizationGroup, rhs: LocalizationGroup) -> Bool {
        return lhs.name == rhs.name && lhs.path == rhs.path && lhs.localizations == rhs.localizations
    }
}
