//
//  Array+Move.swift
//  LocalizationEditor
//
//  Created by JH on 2022/10/1.
//  Copyright © 2022 Igor Kulman. All rights reserved.
//

import Foundation

public extension Array {
    // These functions from sooop on GitHub
    // https://gist.github.com/sooop/3c964900d429516ba48bd75050d0de0a
    mutating func move(from start: Index, to end: Index) {
        guard (0 ..< count) ~= start, (0 ... count) ~= end else { return }
        if start == end { return }
        let targetIndex = start < end ? end - 1 : end
        insert(remove(at: start), at: targetIndex)
    }

    mutating func move(with indexes: IndexSet, to toIndex: Index) {
        let movingData = indexes.map { self[$0] }
        let targetIndex = toIndex - indexes.filter { $0 < toIndex }.count
        for (i, e) in indexes.enumerated() {
            remove(at: e - i)
        }
        insert(contentsOf: movingData, at: targetIndex)
    }
}
