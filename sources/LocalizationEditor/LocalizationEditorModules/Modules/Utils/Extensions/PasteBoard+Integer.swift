//
//  PasteBoardUtil.swift
//  LocalizationEditor
//
//  Created by JH on 2022/10/1.
//  Copyright © 2022 Igor Kulman. All rights reserved.
//

import Cocoa

public extension NSPasteboard.PasteboardType {
    static let rowIndex = NSPasteboard.PasteboardType(rawValue: "LocalizationEditor.RowIndex")
}

public extension NSPasteboardItem {
    func integer(forType type: NSPasteboard.PasteboardType) -> Int? {
        guard let data = data(forType: type) else { return nil }
        let plist = try? PropertyListSerialization.propertyList(
            from: data,
            options: .mutableContainers,
            format: nil
        )
        return plist as? Int
    }
}
