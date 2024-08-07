import Foundation

class Entry<K: Hashable, V> {
    var key: K
    var value: V
    var next: Entry?

    init(key: K, value: V) {
        self.key = key
        self.value = value
    }
}

/// A simple implementation of a hashmap with dynamic sizing and collision handling
class HashMap<K: Hashable, V:Hashable> {
    private var buckets: [Entry<K, V>?]
    private var count: Int
    private let loadFactor: Double = 0.75
    
    init(capacity: Int = 16) {
        self.count = 0
        self.buckets = [Entry<K, V>?](repeating: nil, count: max(1, capacity))
    }
    
    func put(key: K, value: V) {
        let index = hash(key: key)
        var current = buckets[index]
        
        if let found = processEntry(forKey: key, startingFrom: &current) {
            current?.value = value
            return
        }
        
        addEntry(key: key, value: value, at: index)
        count += 1
        
        // Resize if necessary
        if Double(count) > loadFactor * Double(buckets.count) {
            resize()
        }
    }
    
    func get(key: K) -> V? {
        return processEntry(forKey: key, startingFrom: &buckets[hash(key: key)])
    }
    
    func remove(key: K) -> V? {
        let index = hash(key: key)
        var current = buckets[index]
        var previous: Entry<K, V>?
        
        if let found = processEntry(forKey: key, startingFrom: &current, previous: &previous) {
            if let current {
                if let prev = previous {
                    prev.next = current.next
                } else {
                    buckets[index] = current.next
                }
                count -= 1
            }
            return found
        }
        
        return nil
    }
    
    // MARK: Private methods
    
    private func hash(key: K) -> Int {
        return safeAbs(key.hashValue) % buckets.count
    }
    
    private func addEntry(key: K, value: V, at index: Int) {
        let entry = Entry(key: key, value: value)
        entry.next = buckets[index]
        buckets[index] = entry
    }
    
    // Method overloading since cannot add default value for inout
    private func processEntry(forKey key: K, startingFrom current: inout Entry<K, V>?) -> V? {
        var prev: Entry<K, V>?
        return processEntry(forKey: key, startingFrom: &current, previous: &prev)
    }
    
    private func processEntry(forKey key: K, startingFrom current: inout Entry<K, V>?, previous: inout Entry<K, V>?) -> V? {
        while let entry = current {
            if entry.key == key {
                return entry.value
            }
            previous = current
            current = entry.next
        }
        return nil
    }
    
    private func resize() {
        var oldBuckets = buckets
        var newCapacity = buckets.count * 2
        buckets = [Entry<K, V>?](repeating: nil, count: newCapacity)

        for oldBucket in oldBuckets {
            var current = oldBucket
            while let entry = current {
                addEntry(key: entry.key, value: entry.value, at: hash(key: entry.key))
                current = entry.next
            }
        }
    }
}

func safeAbs<T: FixedWidthInteger & SignedInteger>(_ value: T) -> T {
    if value == T.min {
        return value
    } else {
        return abs(value)
    }
}

func generateRandomString(length: Int) -> String {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let randomString = String((0..<length).compactMap { _ in characters.randomElement() })
    return randomString
}
