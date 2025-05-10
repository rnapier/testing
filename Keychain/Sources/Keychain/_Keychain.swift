import Foundation
import Security
import Synchronization

public final class _Keychain: KeychainEngine, Sendable {
    private let cache = Mutex<[String: Data]>([:])
    private let keychainID: String
    private let persistingKeys: [String]
    
    public init(keychainID: String, persistingKeys: [String] = []) {
        self.keychainID = keychainID
        self.persistingKeys = persistingKeys
    }
    
    public func data(for key: String) -> Data? {
        // Check cache first
        if let cachedData = cache.withLock({ $0[key] }) {
            return cachedData
        }
        
        // If not in cache, query from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: keychainID,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            // Update cache with mutex protection
            cache.withLock { $0[key] = data }
            return data
        }
        
        return nil
    }
    
    public func string(for key: String) -> String? {
        guard let data = data(for: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    public func bool(for key: String) -> Bool? {
        guard let data = data(for: key), data.count == 1 else {
            return nil
        }
        return data[0] == 1
    }
    
    public func set(data: Data?, for key: String) {
        // Update cache with mutex protection
        cache.withLock {
            if let data = data {
                $0[key] = data
            } else {
                $0.removeValue(forKey: key)
            }
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: keychainID
        ]
        
        // Remove existing item first
        SecItemDelete(query as CFDictionary)
        
        // If data is non-nil, add the new item
        if let data = data {
            var newQuery = query
            newQuery[kSecValueData as String] = data
            
            // Additional attributes for new items
            newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            
            SecItemAdd(newQuery as CFDictionary, nil)
        }
    }
    
    public func set(string: String?, for key: String) {
        guard let string = string else {
            set(data: nil, for: key)
            return
        }
        
        guard let data = string.data(using: .utf8) else {
            return
        }
        
        set(data: data, for: key)
    }
    
    public func set(bool: Bool?, for key: String) {
        guard let boolValue = bool else {
            set(data: nil, for: key)
            return
        }
        
        let data = Data([boolValue ? 1 : 0])
        set(data: data, for: key)
    }
    
    public func reset() {
        // Get all keys from cache
        let allKeys = cache.withLock { Array($0.keys) }
        
        // Remove all keys except those that should persist
        for key in allKeys {
            if !persistingKeys.contains(key) {
                set(data: nil, for: key)
            }
        }
    }
    
    public func hardReset() {
        // Get all keys from cache
        let allKeys = cache.withLock { Array($0.keys) }
        
        // Remove all keys including those that should persist
        for key in allKeys {
            set(data: nil, for: key)
        }
    }
}
