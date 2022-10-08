//
//  File.swift
//
//
//  Created by JH on 2022/10/4.
//

import Cocoa

public extension NSTableCellView {
    static var itemIdentifier: NSUserInterfaceItemIdentifier {
        .init(rawValue: identifier)
    }
    static var identifier: String {
        .init(describing: self)
    }
}
