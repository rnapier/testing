import Foundation

/// The internal implementation of the Keychain struct, it maps to a particular keychain identifier.
/// As an actor, it provides built-in synchronization to ensure thread safety when accessing the keychain.
/// It maintains an in-memory cache to aid in speeding up reads.
actor Keychain {

    init(keychainID: String) {
        self.keychainID = keychainID
    }
    let keychainID: String
    
    var cache = [String: Data]()

    // MARK: - Reset Methods
    
    func reset() async {
        // clear in-memory caches
        cache = [:]

        // clear entries on disk
        do {
            try await deleteAllKeys(for: kSecClassGenericPassword)
            try await deleteAllKeys(for: kSecClassInternetPassword)
            try await deleteAllKeys(for: kSecClassCertificate)
            try await deleteAllKeys(for: kSecClassKey)
            try await deleteAllKeys(for: kSecClassIdentity)
            
            // Additional cleanup for keychain specific entries
            let query: [CFString: Any] = [
                kSecAttrService: kSecAttrGeneric,
                kSecAttrGeneric: Data(keychainID.utf8),
                kSecClass: kSecClassGenericPassword
            ]
            _ = SecItemDelete(query as CFDictionary)
        } catch {
            // TODO log error
            print("Error Reseting Keychain! \(error)")
        }
    }
}

// MARK: - String Methods
extension Keychain {
    func string(for key: String) async -> String? {
        guard let data = await data(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func set(string: String?, for key: String) async {
        await set(data: string != nil ? Data(string!.utf8) : nil, for: key)
    }
}

// MARK: - Bool Methods
extension Keychain {
    func bool(for key: String) async -> Bool? {
        guard let data = await data(for: key) else { return nil }
        do {
            return try JSONDecoder().decode(Bool.self, from: data)
        } catch {
            return nil
        }
    }

    func set(bool: Bool?, for key: String) async {
        guard let bool = bool else {
            await set(data: nil, for: key)
            return
        }
        do {
            let data = try JSONEncoder().encode(bool)
            await set(data: data, for: key)
        } catch {
            await set(data: nil, for: key)
        }
    }
}

// MARK: - Data Methods
extension Keychain {
    func data(for key: String) async -> Data? {
        // check in-memory cache
        if let data = cache[key] {
            return data
        }
        
        // check disk - keychain
        // setup keychain params
        var params = keychainDictionary(for: key)
        params[kSecMatchLimit] = kSecMatchLimitOne
        params[kSecReturnData] = kCFBooleanTrue
        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            params as CFDictionary,
            &result
        )
        guard status != errSecItemNotFound else {
            // LOG ERROR
            // throw KeychainError.noPassword
            return nil
        }

        // TODO: Noticed that in unit tests we encounter this issue
        // https://stackoverflow.com/questions/22082996/testing-the-keychain-osstatus-error-34018
        // Jira tiket created to find a workaround
        // https://jira.audible.com/browse/IOS-15895
        guard status == errSecSuccess else {
            // LOG ERROR
            // throw KeychainError.unhandledError(status: status)
            return nil
        }
        
        let data = result as? Data
        // update cache
        cache[key] = data
        return data
    }

    func set(data: Data?, for key: String) async {
        // update in-memory cache
        cache[key] = data

        // prep query
        var params = keychainDictionary(for: key)
        let query: () -> OSStatus = {
            // if nil, then delete instead of update
            if data == nil {
                return SecItemDelete(params as CFDictionary)
            } else {
                // first lets attempt to update the entry
                return SecItemUpdate(
                    params as CFDictionary,
                    [
                        kSecValueData: data
                    ] as CFDictionary
                )
            }
        }

        var status = query()
        if status == errSecItemNotFound && data != nil {
            // if the item was not found and we aren't deleting, lets create the entry
            params[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            params[kSecValueData] = data
            status = SecItemAdd(params as CFDictionary, nil)
        }
        guard status != errSecSuccess else {
            // TODO LOG ERROR
            // throw KeychainError.unhandledError(status: status)
            return
        }
    }
}

// MARK: - Keychain CF Helper Methods
extension Keychain {
    nonisolated func keychainDictionary(for id: String) -> [CFString: Any] {
        [
            kSecAttrService: id,
            kSecAttrGeneric: Data(keychainID.utf8),
            kSecClass: kSecClassGenericPassword
        ]
    }
}

extension Keychain {
    func deleteAllKeys(for secClass: CFString) async throws {
        // delete
        let status = SecItemDelete([
            kSecClass: secClass
        ] as CFDictionary)
        
        // check for errors
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

public enum KeychainError: Error {
    case noPassword
    case unhandledError(status: OSStatus)
}
