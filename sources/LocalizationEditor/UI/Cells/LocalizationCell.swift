//
//  LocalizationCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa
import Models
import Utils
import NSObject_Combine

protocol LocalizationCellDelegate: AnyObject {
    func userDidFocusLocalizationString(_ cell: LocalizationCell)
    func userDidUpdateLocalizationString(language: String, key: String, with value: String, message: String?, willUpdate: Closure?, didUpdate: Closure?)
}

final class LocalizationCell: NSTableCellView {
    // MARK: - Outlets

    @IBOutlet
    private var valueTextField: LocalizationTextField!

    // MARK: - Properties

    weak var delegate: LocalizationCellDelegate?

    var language: String?

    var value: LocalizationString? {
        didSet {
            valueTextField.stringValue = value?.value ?? ""
            valueTextField.delegate = self
            setStateUI()
        }
    }

    private func setStateUI() {
        valueTextField.layer?.borderColor = valueTextField.stringValue.isEmpty ? NSColor.red.cgColor : NSColor.clear.cgColor
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        valueTextField.wantsLayer = true
        valueTextField.layer?.borderWidth = 1.0
        valueTextField.layer?.cornerRadius = 0.0
        valueTextField.textFieldDidFocusPublisher
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                delegate?.userDidFocusLocalizationString(self)
            }
            .store(in: &combine.cancellables)
    }

    /// Focues the cell by activating the NSTextField, making sure there is no selection and cursor is moved to the end
    func focus() {
        valueTextField?.becomeFirstResponder()
        valueTextField?.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
        valueTextField?.currentEditor()?.moveToEndOfDocument(nil)
    }
    
}

// MARK: - Delegate

extension LocalizationCell: NSTextFieldDelegate {
    
    func controlTextDidEndEditing(_: Notification) {
        update(newValue: valueTextField.stringValue)
    }

    func update(newValue: String) {
        guard let language = language, let localizationString = value else { return }

        setStateUI()
        let oldValue = value?.value
        delegate?.userDidUpdateLocalizationString(language: language, key: localizationString.key, with: newValue, message: localizationString.message) {
            self.undoManager?.registerUndo(withTarget: self) { target in
                guard let oldValue = oldValue else { return }
                print(oldValue, newValue)
                target.update(newValue: oldValue)
            }
        } didUpdate: {
            self.value?.update(newValue: newValue)
        }

        valueTextField.stringValue = newValue
        setStateUI()
    }
}
