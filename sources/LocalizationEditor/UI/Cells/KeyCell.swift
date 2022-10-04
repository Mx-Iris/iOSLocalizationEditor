//
//  KeyCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa

final class KeyCell: NSTableCellView {
    // MARK: - Outlets

    @IBOutlet private weak var keyLabel: NSTextField!
    @IBOutlet private weak var messageLabel: NSTextField!

    // MARK: - Properties

    var key: String? {
        didSet {
            keyLabel.stringValue = key ?? ""
        }
    }
    var message: String? {
        didSet {
            messageLabel.stringValue = message ?? ""
        }
    }
}
