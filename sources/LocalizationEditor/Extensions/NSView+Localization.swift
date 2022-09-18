//
//  NSVIew+Localization.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 24/10/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//
// Inspired by https://github.com/PiXeL16/IBLocalizable for iOS
//
// swiftlint:disable unused_setter_value

import AppKit
import Foundation

///  Localizable Protocol
protocol Localizable: AnyObject {
    /// The property that can be localized for each view, for example in a UILabel its the text, in a UIButton its the title, etc
    /// 可以为每个视图本地化的属性，例如在UILabel中它是文本，在UIButton中它是标题，等等
    var localizableProperty: String? { get set }

    /// The localizable string value in the your localizable strings
    /// 本地化字符串中的可本地化字符串的值
    var localizableString: String { get set }

    /// Applies the localizable string to the supported view attribute
    /// 将可本地化字符串应用于受支持的视图属性
    func applyLocalizableString(_ localizableString: String?)
}

extension Localizable {
    /// Applies the localizable string to the supported view attribute
    ///
    /// - parameter localizableString: localizable String Value
    public func applyLocalizableString(_ localizableString: String?) {
        localizableProperty = localizableString?.localized
    }
}

extension NSCell: Localizable {
    /// Not implemented in base class
    /// 无具体实现的基类
    @objc
    var localizableProperty: String? {
        get {
            return ""
        }
        set {}
    }

    /// Applies the localizable string to the localizable field of the supported view
    @IBInspectable
    var localizableString: String {
        get {
            guard let text = localizableProperty else {
                return ""
            }
            return text
        }
        set {
            ///  Applys the localization to the property
            applyLocalizableString(newValue)
        }
    }
}

extension NSMenuItem: Localizable {
    /// Not implemented in base class
    @objc
    var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }

    /// Applies the localizable string to the localizable field of the supported view
    @IBInspectable
    var localizableString: String {
        get {
            guard let text = localizableProperty else {
                return ""
            }
            return text
        }
        set {
            ///  Applys the localization to the property
            applyLocalizableString(newValue)
        }
    }

    func applyLocalizableString(_ localizableString: String?) {
        title = localizableString?.localized ?? ""
    }
}

extension NSMenu {
    /// Not implemented in base class
    @objc
    var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }

    /// Applies the localizable string to the localizable field of the supported view
    @IBInspectable
    var localizableString: String {
        get {
            guard let text = localizableProperty else {
                return ""
            }
            return text
        }
        set {
            ///  Applys the localization to the property
            applyLocalizableString(newValue)
        }
    }

    func applyLocalizableString(_ localizableString: String?) {
        title = localizableString?.localized ?? ""
    }
}

extension NSSearchField {
    /// Not implemented in base class
    @objc
    var localizableProperty: String? {
        get {
            return placeholderString
        }
        set {
            placeholderString = newValue ?? ""
        }
    }

    /// Applies the localizable string to the localizable field of the supported view
    @IBInspectable
    var localizableString: String {
        get {
            guard let text = localizableProperty else {
                return ""
            }
            return text
        }
        set {
            ///  Applys the localization to the property
            applyLocalizableString(newValue)
        }
    }

    func applyLocalizableString(_ localizableString: String?) {
        placeholderString = localizableString?.localized ?? ""
    }
}

public extension NSTextFieldCell {
    override var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }
}

public extension NSButtonCell {
    override var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }
}

public extension NSPopUpButtonCell {
    override var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }
}
