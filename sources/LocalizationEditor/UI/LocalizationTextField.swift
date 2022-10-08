//
//  LocalizationTextField.swift
//  LocalizationEditor
//
//  Created by JH on 2022/10/6.
//  Copyright © 2022 Igor Kulman. All rights reserved.
//

import Cocoa
import Combine

class LocalizationTextField: NSTextField {

    var textFieldDidFocusPublisher: PassthroughSubject<Void, Never> = .init()
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textFieldDidFocusPublisher.send(())
        return super.becomeFirstResponder()
    }
}
