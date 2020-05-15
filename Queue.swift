import Foundation

private let QueueSpecificKey = DispatchSpecificKey<NSObject>()

private let globalMainQueue = Queue(queue: .main)
private let globalDefaultQueue = Queue(queue: .global(qos: .default))
private let globalBackgroundQueue = Queue(queue: .global(qos: .background))

final class Queue {
    private let nativeQueue: DispatchQueue
    private var specific = NSObject()
    private let specialIsMainQueue: Bool

    var queue: DispatchQueue {
        get {
            return self.nativeQueue
        }
    }

    class func mainQueue() -> Queue {
        return globalMainQueue
    }

    class func concurrentDefaultQueue() -> Queue {
        return globalDefaultQueue
    }

    class func concurrentBackgroundQueue() -> Queue {
        return globalBackgroundQueue
    }

    init(queue: DispatchQueue) {
        self.nativeQueue = queue
        self.specialIsMainQueue = queue == .main
    }

    fileprivate init(queue: DispatchQueue, specialIsMainQueue: Bool) {
        self.nativeQueue = queue
        self.specialIsMainQueue = specialIsMainQueue
    }

    init(name: String? = nil, qos: DispatchQoS = .default) {
        self.nativeQueue = DispatchQueue(label: name ?? "", qos: qos)

        self.specialIsMainQueue = false

        self.nativeQueue.setSpecific(key: QueueSpecificKey, value: self.specific)
    }

    func isCurrent() -> Bool {
        if DispatchQueue.getSpecific(key: QueueSpecificKey) === self.specific {
            return true
        } else if self.specialIsMainQueue && Thread.isMainThread {
            return true
        } else {
            return false
        }
    }

    func async(_ f: @escaping () -> Void) {
        if self.isCurrent() {
            f()
        } else {
            self.nativeQueue.async(execute: f)
        }
    }

    func sync(_ f: () -> Void) {
        if self.isCurrent() {
            f()
        } else {
            self.nativeQueue.sync(execute: f)
        }
    }

    func justDispatch(_ f: @escaping () -> Void) {
        self.nativeQueue.async(execute: f)
    }

    func justDispatchWithQoS(qos: DispatchQoS, _ f: @escaping () -> Void) {
        self.nativeQueue.async(group: nil, qos: qos, flags: [.enforceQoS], execute: f)
    }

    func after(_ delay: Double, _ f: @escaping() -> Void) {
        let time: DispatchTime = DispatchTime.now() + delay
        self.nativeQueue.asyncAfter(deadline: time, execute: f)
    }
}
