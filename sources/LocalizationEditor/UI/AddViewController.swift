//
//  AddViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 14/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Cocoa

protocol AddViewControllerDelegate: AnyObject {
    func userDidCancel()
    func userDidAddTranslation(key: String, message: String?, addMode: AddViewController.AddMode)
}

final class AddViewController: NSViewController {

    enum AddMode {
        case append
        case insert(Int)
    }
    
    // MARK: - Outlets

    @IBOutlet private weak var keyTextField: NSTextField!
    @IBOutlet private weak var addButton: NSButton!
    @IBOutlet private weak var messageTextField: NSTextField!

    // MARK: - Properties

    weak var delegate: AddViewControllerDelegate?
    var addMode: AddMode = .append
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: - Setup

    private func setup() {
        keyTextField.delegate = self
    }

    // MARK: - Actions

    @IBAction private func cancelAction(_ sender: Any) {
        delegate?.userDidCancel()
    }

    @IBAction private func addAction(_ sender: Any) {
        guard !keyTextField.stringValue.isEmpty else { return }
        delegate?.userDidAddTranslation(key: keyTextField.stringValue, message: messageTextField.stringValue.isEmpty ? nil : messageTextField.stringValue, addMode: addMode)
    }
}

// MARK: - NSTextFieldDelegate

extension AddViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        addButton.isEnabled = !keyTextField.stringValue.isEmpty
    }
}
