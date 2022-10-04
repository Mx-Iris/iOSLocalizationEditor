//
//  FolderContentMonitor+Combine.swift
//  LocalizationEditor
//
//  Created by JH on 2022/9/25.
//  Copyright © 2022 Igor Kulman. All rights reserved.
//

import Foundation
import Combine

@available(macOS 10.15, *)
public extension FolderContentMonitor {
    var publisher: AnyPublisher<FolderContentChangeEvent, Never> {
        Publisher(monitor: self).eraseToAnyPublisher()
    }
}

extension FolderContentMonitor {
    @available(macOS 10.15, *)
    class Publisher: Combine.Publisher {
        typealias Output = FolderContentChangeEvent
        typealias Failure = Never

        private let monitor: FolderContentMonitor

        init(monitor: FolderContentMonitor) {
            self.monitor = monitor
        }

        func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Output == S.Input {
            let subscription = Subscription(subscriber: subscriber, monitor: monitor)
            subscriber.receive(subscription: subscription)
        }
    }

    @available(macOS 10.15, *)
    class Subscription<SubscriberType: Subscriber>: Combine.Subscription where SubscriberType.Input == FolderContentChangeEvent, SubscriberType.Failure == Never {
        private var subscriber: SubscriberType?
        private weak var monitor: FolderContentMonitor?
        init(subscriber: SubscriberType, monitor: FolderContentMonitor) {
            self.subscriber = subscriber
            self.monitor = monitor
            let oldCallback = monitor.callback
            monitor.callback = { event in
                oldCallback?(event)
                _ = subscriber.receive(event)
            }
            monitor.start()
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            subscriber = nil
            monitor?.stop()
        }
    }
}
