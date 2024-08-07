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
class HashMap<K: Hashable, V> {
    private var buckets: [Entry<K, V>?]
    private var count: Int
    private let loadFactor: Double = 0.75
    
    init(capacity: Int = 16) {
        self.count = 0
        self.buckets = [Entry<K, V>?](repeating: nil, count: Swift.max(1, capacity))
    }
    
    func put(key: K, value: V) {
        let index = hash(key: key)
        var current = buckets[index]
        
        if let _ = processEntry(forKey: key, startingFrom: &current) {
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
        
        if let value = processEntry(forKey: key, startingFrom: &current, previous: &previous) {
            if let current {
                if let prev = previous {
                    prev.next = current.next
                } else {
                    buckets[index] = current.next
                }
                count -= 1
            }
            return value
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
        let oldBuckets = buckets
        let newCapacity = buckets.count * 2
        buckets = [Entry<K, V>?](repeating: nil, count: newCapacity)

        for oldBucket in oldBuckets {
            var current = oldBucket
            while let entry = current {
                addEntry(key: entry.key, value: entry.value, at: hash(key: entry.key))
                current = entry.next
            }
        }
    }
    
    struct Iterator: IteratorProtocol {
        typealias Element = (K,V)
        private var currentIndex = 0
        private var currentEntry: Entry<K,V>?
        private let buckets: [Entry<K, V>?]
        
        init(hashMap: HashMap<K,V>) {
            self.buckets = hashMap.buckets
            getFirstNonEmptyBucket()
        }
        
        mutating private func getFirstNonEmptyBucket() {
            while currentIndex < buckets.count && buckets[currentIndex] == nil {
                currentIndex += 1
            }
            if currentIndex < buckets.count {
                currentEntry = buckets[currentIndex]
            }
        }
        
        mutating func next() -> (K,V)? {
            if currentEntry == nil {
                getFirstNonEmptyBucket()
                currentIndex += 1
            }
            if let entry = currentEntry {
                currentEntry = entry.next
                return (entry.key, entry.value)
            }
            return nil
        }
    }
}

extension HashMap: Sequence {
    func makeIterator() -> Iterator {
        return Iterator(hashMap: self)
    }
}

// Some additional methods
extension HashMap {
    
    func forEach(_ elem: (K, V) -> Void) {
        for bucket in buckets {
            var current = bucket
            while let entry = current {
                elem(entry.key, entry.value)
                current = entry.next
            }
        }
    }
    
    func keys() -> [K] {
        var keys: [K] = []
        self.forEach { key, _ in
            keys.append(key)
        }
        return keys
    }
    
    func values() -> [V] {
        var values: [V] = []
        self.forEach { _, value in
            values.append(value)
        }
        return values
    }
    
    func clear() {
        self.count = 0
        self.buckets = [Entry<K, V>?](repeating: nil, count: buckets.count)
    }
    
    func size() -> Int {
        count
    }
    
    func isEmpty() -> Bool {
        count == 0
    }
}

func safeAbs<T: FixedWidthInteger & SignedInteger>(_ value: T) -> T {
    if value == T.min {
        return value
    } else {
        return abs(value)
    }
}

var hashmap = HashMap<String, Int>()
hashmap.put(key: "test0", value: 0)
hashmap.put(key: "test1", value: 1)
hashmap.put(key: "test2", value: 2)
hashmap.put(key: "test3", value: 3)
hashmap.put(key: "test4", value: 4)

for (key, value) in hashmap {
    print("\(key): \(value)")
}

hashmap.forEach { key, value in
    print("\(key): \(value)")
}
print(hashmap.keys())
hashmap.remove(key: "test2")
hashmap.remove(key: "test3")
print(hashmap.values())
print(hashmap.isEmpty())
