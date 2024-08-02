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

/// A simple implementation of a hashmap with fixed capacity and collision handling
class HashMapV1<K: Hashable, V> {
    fileprivate var buckets: [Entry<K, V>?]
    fileprivate(set) var capacity: Int
    fileprivate var hashMethod: HashMethod = .native
    
    init(capacity: Int, hashMethod: HashMethod) {
        self.capacity = max(1, capacity)
        self.buckets = [Entry<K, V>?](repeating: nil, count: capacity)
        self.hashMethod = hashMethod
    }
    
    private func hash(key: K) -> Int {
        return hashMethod.toIndex(key: key, range: capacity)
    }
    
    func put(key: K, value: V) {
        let index = hash(key: key)
        var current = buckets[index]
        
        // Check for existing
        while let entry = current {
            if entry.key == key {
                entry.value = value
                return
            }
            current = entry.next
        }
        
        // Add new
        let newEntry = Entry(key: key, value: value)
        newEntry.next = buckets[index]
        buckets[index] = newEntry
    }
    
    func get(key: K) -> V? {
        let index = hash(key: key)
        var current = buckets[index]
        
        while current != nil {
            if current?.key == key {
                return current?.value
            }
            current = current?.next
        }
        return nil
    }
    
    func remove(key: K) -> V? {
        let index = hash(key: key)
        var current = buckets[index]
        var previous: Entry<K, V>?
        
        while current != nil {
            if current?.key == key {
                if let prev = previous {
                    prev.next = current?.next
                } else {
                    buckets[index] = current?.next
                }
                return current?.value
            }
            previous = current
            current = current?.next
        }
        
        return nil
    }
}

/// Enhanced version of HashMapV1 with dynamic sizing
class HashMapV2<K: Hashable, V>:HashMapV1<K, V> {
    private var count: Int
    private let loadFactor: Double = 0.75
    
    override init(capacity: Int = 16, hashMethod: HashMethod = .native) {
        self.count = 0
        super.init(capacity: capacity, hashMethod: hashMethod)
    }
    
    override func put(key: K, value: V) {
        super.put(key: key, value: value)
        count += 1
        // Resize if necessary
        if Double(count) / Double(capacity) > loadFactor {
            resize()
        }
    }
    
    override func remove(key: K) -> V? {
        let removed = super.remove(key: key)
        if removed != nil {
            count -= 1
        }
        return removed
    }
    
    
    private func resize() {
        let newCapacity = capacity * 2
        var newBuckets = [Entry<K, V>?](repeating: nil, count: newCapacity)

        for oldBucket in buckets {
            var current = oldBucket
            while let entry = current {
                let newIndex = hashMethod.toIndex(key: entry.key, range: newCapacity)
                let newEntry = Entry(key: entry.key, value: entry.value)
                newEntry.next = newBuckets[newIndex]
                newBuckets[newIndex] = newEntry
                current = entry.next
            }
        }

        buckets = newBuckets
        capacity = newCapacity
    }
}

// TODO: Implement hashmap with BST (performance O(n) to O(logn))
// TODO: Implement thread safe hashmap
// TODO: Try implementing it using open adressing

// Helpers

enum HashMethod {
    case native
    case FNV1a32
    case FNV1a64
    
    /// Maps the hash code of a given key to an index within a specified range.
    func toIndex(key: any Hashable, range:Int) -> Int {
        switch self {
        case .native:
            return abs(Hash.native(key)) % range
        case .FNV1a32:
            return Int(Hash.FNV1a.hash32(key) % UInt32(range))
        case .FNV1a64:
            return Int(Hash.FNV1a.hash64(key) % UInt64(range))
        }
    }
}

struct Hash {
    
    static func native<K:Hashable>(_ key: K) -> Int {
        return abs(key.hashValue)
    }
    
    // FNV-1a hash function implementation
    // https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
    struct FNV1a {
        
        static func hash32(for data: Data) -> UInt32 {
            let fnvOffsetBasis: UInt32 = 0x811c9dc5
            let fnvPrime: UInt32 = 0x01000193
            
            var hash: UInt32 = fnvOffsetBasis
            
            for byte in data {
                hash ^= UInt32(byte)
                hash = hash &* fnvPrime
            }
            
            return hash
        }
        
        static func hash64(for data: Data) -> UInt64 {
            let fnvOffsetBasis: UInt64 = 0xcbf29ce484222325
            let fnvPrime: UInt64 = 0x100000001b3
            
            var hash: UInt64 = fnvOffsetBasis
            
            for byte in data {
                hash ^= UInt64(byte)
                hash = hash &* fnvPrime
            }
            
            return hash
        }
        
        static func hash32<K:Hashable>(_ key: K) -> UInt32 {
            let keyString = String(describing: key)
            let keyData = keyString.data(using: .utf8) ?? Data()
            return Hash.FNV1a.hash32(for: keyData)
        }
        
        static func hash64<K:Hashable>(_ key: K) -> UInt64 {
            let keyString = String(describing: key)
            let keyData = keyString.data(using: .utf8) ?? Data()
            return Hash.FNV1a.hash64(for: keyData)
        }
    }
}

func generateRandomString(length: Int) -> String {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let randomString = String((0..<length).compactMap { _ in characters.randomElement() })
    return randomString
}

enum HashMapVersion {
    case fixedSize(HashMethod, Int)
    case dynamic(HashMethod)
}

func test(numOfEntries: Int = 512, hashMapVersion: HashMapVersion) {
    var hashMap: HashMapV1<String, Int>
    let clock = ContinuousClock()
    var keys: [String] = []
    
    switch hashMapVersion {
    case .fixedSize(let hashMethod, let capacity):
        hashMap = HashMapV1<String, Int>(capacity: capacity, hashMethod: hashMethod)
        print("------ Started test for HashMap V1 ------ \nhashMethod:\(hashMethod), numOfEntries:\(numOfEntries), capacity:\(capacity)")
    case .dynamic(let hashMethod):
        hashMap = HashMapV2<String, Int>(hashMethod: hashMethod)
        print("------ Started test for HashMap V2 ------ \nhashMethod:\(hashMethod), numOfEntries:\(numOfEntries)")
    }
    
    func populate() {
        for i in 0..<numOfEntries {
            let key = generateRandomString(length: i % 5 + 5)
            keys.append(key)
            hashMap.put(key: key, value: i)
        }
    }
    
    func readAll() {
        for key in keys {
            _ = hashMap.get(key: key)
            //print("VALUE for \(key): \(String(describing: value))")
        }
    }
    
    func removeAll() {
        for key in keys {
            _ = hashMap.remove(key: key)
        }
    }
    
    let put = clock.measure(populate)
    let read = clock.measure(readAll)
    let remove = clock.measure(removeAll)

    print("Populate table: \(put)")
    print("Read table: \(read)")
    print("Clear table: \(remove)")
}

let numOfEntries = 512
print("Native")
test(numOfEntries: numOfEntries, hashMapVersion: .fixedSize(.native, numOfEntries))
test(numOfEntries: numOfEntries, hashMapVersion: .dynamic(.native))
print("FNV1a32")
test(numOfEntries: numOfEntries, hashMapVersion: .fixedSize(.FNV1a32, numOfEntries))
test(numOfEntries: numOfEntries, hashMapVersion: .dynamic(.FNV1a32))
print("FNV1a64")
test(numOfEntries: numOfEntries, hashMapVersion: .fixedSize(.FNV1a64, numOfEntries))
test(numOfEntries: numOfEntries, hashMapVersion: .dynamic(.FNV1a64))
