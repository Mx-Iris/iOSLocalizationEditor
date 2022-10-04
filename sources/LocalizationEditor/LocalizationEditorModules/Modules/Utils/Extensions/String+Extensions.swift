//
//  String+Extensions.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 05/02/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Foundation

public extension String {
    var normalized: String {
        return folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    var capitalizedFirstLetter: String {
        return prefix(1).uppercased() + lowercased().dropFirst()
    }

    var unescaped: String {
        let entities = [
            "\\n": "\n",
            "\\t": "\t",
            "\\r": "\r",
            "\\\"": "\"",
            "\\\'": "\'",
            "\\\\": "\\",
        ]
        var current = self
        for (key, value) in entities {
            current = current.replacingOccurrences(of: key, with: value)
        }
        return current
    }

    var escaped: String {
        return replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
    }

    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
