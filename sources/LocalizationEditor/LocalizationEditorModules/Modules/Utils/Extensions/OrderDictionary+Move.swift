//
//  OrderDictionary+Move.swift
//  LocalizationEditor
//
//  Created by JH on 2022/10/1.
//  Copyright © 2022 Igor Kulman. All rights reserved.
//

import Foundation
import OrderedCollections

public extension OrderedDictionary {
    mutating func move(from start: Index, to end: Index) {
        guard (0 ..< count) ~= start, (0 ... count) ~= end else { return }
        if start == end { return }
        let targetIndex = (start < end) ? (end - 1) : end
        let removed = remove(at: start)
        updateValue(removed.value, forKey: removed.key, insertingAt: targetIndex)
    }

    mutating func move(with indexes: IndexSet, to toIndex: Int) {
        let movingData = indexes.map { elements[$0] }

        let targetIndex = toIndex - indexes.filter { $0 < toIndex }.count
        for (i, e) in indexes.enumerated() {
            remove(at: e - i)
        }

        updateValue(contentsOf: movingData, at: targetIndex)
    }

    mutating func updateValue(contentsOf contents: [(key: Key, value: Value)], at targetIndex: Int) {
        contents.enumerated().forEach { index, content in
            updateValue(content.value, forKey: content.key, insertingAt: targetIndex + index)
        }
    }
}
