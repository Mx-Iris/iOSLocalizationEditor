//
//  LocalizationsDataSource.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa
import os
import OrderedCollections
import ObjectiveC
import Models
import Utils

public typealias LocalizationsDataSourceData = ([String], String?, [LocalizationGroup])
public typealias LocalizationRowData = OrderedDictionary<String, LocalizationString?>

public enum Filter: Int, CaseIterable, CustomStringConvertible {
    case all
    case missing

    public var description: String {
        switch self {
        case .all:
            return "all".localized
        case .missing:
            return "missing".localized
        }
    }
}

/// Data source for the NSTableView with localizations
public final class LocalizationsDataSource: NSObject {
    private let localizationProvider = LocalizationProvider()

    private var localizationGroups: [LocalizationGroup] = []

    private var selectedLocalizationGroup: LocalizationGroup?

    private var languagesCount = 0

    private var mainLocalization: Localization?

    public var undoManager: UndoManager?

    /// Dictionary indexed by localization key on the first level and by language on the second level for easier access
    /// Dictionary 在第一级按本地化key索引, 在第二级按语言索引, 以便于访问
    private var data: OrderedDictionary<String, OrderedDictionary<String, LocalizationString?>> = [:]

    /// Keys for the consumer. Depend on applied filter.
    /// consumer的key, 取决于使用的过滤器
    private var filteredKeys: [String] = []

    // MARK: - Actions

    /// Loads data for directory at given path
    /// 为给定路径的目录加载数据
    ///
    /// - Parameter folder: directory path to start the search （开始搜索的目录路径）
    ///
    /// - Parameter onCompletion: callback with data （完成时的回掉，会传入加载完毕的数据）
    public func load(folder: URL, onCompletion: @escaping (LocalizationsDataSourceData) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let localizationGroups = self.localizationProvider.getLocalizations(url: folder)
            guard localizationGroups.count > 0,
                  let group = localizationGroups.first(where: { $0.name == "Localizable.strings" }) ?? localizationGroups.first
            else {
                os_log("No localization data found", type: OSLogType.error)
                DispatchQueue.main.async {
                    onCompletion(([], nil, []))
                }
                return
            }

            self.localizationGroups = localizationGroups
            let languages = self.select(group: group)

            DispatchQueue.main.async {
                onCompletion((languages, group.name, localizationGroups))
            }
        }
    }

    /// Selects given localization group, converting its data to a more usable form and returning an array of available languages
    /// 选择给定的`LocalizationGroup`，将其数据转换为更可用的形式并返回可用语言的数组
    ///
    /// - Parameter group: group to select（选择的group）
    ///
    /// - Returns: an array of available languages （包含可用的语言的数组）
    private func select(group: LocalizationGroup) -> [String] {
        selectedLocalizationGroup = group

        let localizations = group.localizations
            .sorted { lhs, rhs in
                if lhs.language.lowercased() == "base" {
                    return true
                }

                if rhs.language.lowercased() == "base" {
                    return false
                }

                return lhs.translations.count > rhs.translations.count
            }
        mainLocalization = localizations.first
        languagesCount = localizations.count

        data = [:]
        for key in mainLocalization!.translations.map({ $0.key }) {
            data[key] = [:]
            for localization in localizations {
                data[key]![localization.language] = localization.translations.first(where: { $0.key == key })
            }
        }

        // making sure filteredKeys are computed
        filter(by: Filter.all, searchString: nil)

        return localizations.map { $0.language }
    }

    /// Selects given group and gets available languages
    /// 选择给定的组并获取可用的语言
    ///
    /// - Parameter group: group name
    ///
    /// - Returns: array of languages
    public func selectGroupAndGetLanguages(for group: String) -> [String] {
        let group = localizationGroups.first(where: { $0.name == group })!
        let languages = select(group: group)
        return languages
    }

    /// Adds new localization key with a message to all the localizations
    /// 添加新的`Localization`对象（其中包含`key`和`message`）
    ///
    /// - Parameter key: key to add
    ///
    /// - Parameter message: message (optional)
    public func addLocalization(key: String, message: String?) {
        guard let selectedLocalizationGroup = selectedLocalizationGroup else { return }

        selectedLocalizationGroup.localizations.forEach { localization in

            let newTranslation = localizationProvider.addKeyToLocalization(localization: localization, key: key, message: message)
            // If we already created the entry in the data dict, do not overwrite the entry entirely.
            // Instead just add the data to the already present entry.
            if data[key] != nil {
                data[key]?[localization.language] = newTranslation
            } else {
                data[key] = [localization.language: newTranslation]
            }
            
        }
    }

    public func insertLocalization(key: String, message: String?, row: Int) {
        guard let selectedLocalizationGroup = selectedLocalizationGroup else { return }
        
        selectedLocalizationGroup.localizations.forEach { localization in
            let newTranslation = localizationProvider.insertKey(to: localization, for: key, with: message, at: row)
            
            if data[key] != nil {
                data[key]?[localization.language] = newTranslation
            } else {
                data.updateValue([localization.language : newTranslation], forKey: key, insertingAt: row)
            }
        }
    }
    
    /// Deletes given key from all the localizations
    /// 从所有`Localization`中删除给定的`key`
    ///
    /// - Parameter key: key to delete
    public func deleteLocalization(key: String) {
        guard let selectedLocalizationGroup = selectedLocalizationGroup else {
            return
        }

        selectedLocalizationGroup.localizations.forEach { localization in
            self.localizationProvider.deleteKeyFromLocalization(localization: localization, key: key)
        }
        data.removeValue(forKey: key)
    }

    /// Updates given localization values in given language
    /// 更新给定语言中给定的`Localization`值
    ///
    /// - Parameter language: language to update
    ///
    /// - Parameter key: localization string key
    ///
    /// - Parameter value: new value for the localization string
    public func updateLocalization(
        language: String,
        key: String,
        value: String,
        message: String?,
        willUpdate: Closure? = nil,
        didUpdate: Closure? = nil
    ) {
        guard let localization = selectedLocalizationGroup?.localizations.first(where: { $0.language == language }) else {
            return
        }
        localizationProvider.updateLocalization(
            localization: localization,
            key: key,
            with: value,
            message: message,
            willUpdate: willUpdate,
            didUpdate: didUpdate
        )
    }

    public func updateLocalizationRow(key: String, rowData: LocalizationRowData, rowIndex row: Int) {
        data.updateValue(rowData, forKey: key, insertingAt: row)
        rowData.compactMap { (key, localizationString) -> (String, String)? in
            guard let value = localizationString?.value else { return nil }
            return (key, value)
        }.forEach { language, value in
            updateLocalization(language: language, key: key, value: value, message: getMessage(row: row))
        }
    }
    
    /// Gets key for speficied row
    /// 获取指定行的 `key`
    ///
    /// - Parameter row: row number
    ///
    /// - Returns: key if valid
    public func getKey(row: Int) -> String? {
        return row < filteredKeys.count ? filteredKeys[row] : nil
    }

    /// Gets the message for specified row
    /// 获取指定行的 `message`
    ///
    /// - Parameter row: row number
    ///
    /// - Returns: message if any
    public func getMessage(row: Int?) -> String? {
        guard let row = row, let key = getKey(row: row), let part = data[key], let languageKey = mainLocalization?.language else {
            return nil
        }
        return part[languageKey]??.message
    }

    /// Gets localization for specified language and row. The language should be always valid. The localization might be missing, returning it with empty value in that case
    /// 获取指定语言和行的`Localization`。语言应该总是有效的。`Localization`可能丢失，在这种情况下返回空值
    ///
    /// - Parameter language: language to get the localization for
    ///
    /// - Parameter row: row number
    ///
    /// - Returns: localization string
    public func getLocalization(language: String, row: Int) -> LocalizationString {
        guard let key = getKey(row: row) else {
            // should not happen but you never know
            fatalError("No key for given row")
        }

        guard let section = data[key], let data = section[language], let localization = data else {
            return LocalizationString(key: key, value: "", message: "")
        }

        return localization
    }

    public func getLocalizationRowData(key: String) -> LocalizationRowData? {
        data[key]
    }
    
    /// Returns row number for given key
    /// 返回给定`key`的`row`
    ///
    /// - Parameter key: key to check
    ///
    /// - Returns: row number (if any)
    public func getRow(key: String) -> Int? {
        return filteredKeys.firstIndex(of: key)
    }

    /// Filters the data by given filter and search string. Empty search string means all data us included.
    /// 根据给定的过滤器和搜索字符串过滤数据。空搜索字符串表示包含所有数据。
    ///
    /// Filtering is done by setting the filteredKeys property. A key is included if it matches the search string or any of its translations matches.
    /// 过滤是通过设置filteredKeys属性来完成的。如果匹配搜索字符串或其任何翻译匹配，则包含键。
    public func filter(by filter: Filter, searchString: String?) {
        os_log("Filtering by %@", type: OSLogType.debug, "\(filter)")

        // first use filter, missing translation is a translation that is missing in any language for the given key
        let data = filter == .all ? self.data : self.data.filter { dict in
            dict.value.keys.count != self.languagesCount || !dict.value.values.allSatisfy { $0?.value.isEmpty == false }
        }

        // no search string, just use teh filtered data
        guard let searchString = searchString, !searchString.isEmpty else {
            filteredKeys = data.keys.map { $0 }
            return
        }

        os_log("Searching for %@", type: OSLogType.debug, searchString)

        var keys: [String] = []
        for (key, value) in data {
            // include if key matches (no need to check further)
            if key.normalized.contains(searchString.normalized) {
                keys.append(key)
                continue
            }

            // include if any of the translations matches
            if value.compactMap({ $0.value }).map({ $0.value }).contains(where: { $0.normalized.contains(searchString.normalized) }) {
                keys.append(key)
            }
        }

        filteredKeys = keys
    }
}

public extension LocalizationsDataSource {
    func moveLocalizations(with indexes: IndexSet, to toIndex: Int) {
        data.move(with: indexes, to: toIndex)
        selectedLocalizationGroup?.localizations.forEach { localization in
            localization.move(with: indexes, to: toIndex)
            localizationProvider.update(localization: localization)
        }
    }
}

// MARK: - Delegate

extension LocalizationsDataSource: NSTableViewDataSource {
    public func numberOfRows(in _: NSTableView) -> Int {
        return filteredKeys.count
    }

    public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        tableView.draggingDestinationFeedbackStyle = .gap
    }

    public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        NSPasteboardItem().then {
            $0.setPropertyList(row, forType: .rowIndex)
        }
    }

    public func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard dropOperation == .above, (info.draggingSource as? NSTableView) === tableView else { return [] }
        return .move
    }

    public func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let items = info.draggingPasteboard.pasteboardItems else { return false }

        let oldIndexes = items.compactMap { $0.integer(forType: .rowIndex) }

        if oldIndexes.isEmpty { return false }

        moveLocalizations(with: IndexSet(oldIndexes), to: row)

        tableView.beginUpdates()

        var oldIndexOffset = 0
        var newIndexOffset = 0
        for oldIndex in oldIndexes {
            if oldIndex < row {
                tableView.moveRow(at: oldIndex + oldIndexOffset, to: row - 1)
                oldIndexOffset -= 1
            } else {
                tableView.moveRow(at: oldIndex, to: row + newIndexOffset)
                newIndexOffset += 1
            }
        }

        tableView.endUpdates()

        return true
    }

    public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        tableView.draggingDestinationFeedbackStyle = .none
    }
}
