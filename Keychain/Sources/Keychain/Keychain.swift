//
//  CustomKeychain.swift
//
//
//  Created by Rogers, Maximilian on 8/19/21.
//

import Foundation

/// The internal implementation of the Keychain struct, it maps to a particular keychain identiifier.
/// With an internal concurrent queue with write barriers will ensure that unexpected values changes can be avoided but still allowing for fast efficient reads from the keychain repository.
/// In addition to the concurrent queue, there is an in-memory cache to aid in speeding up reads
/// The persisting keys are used to ensure that certain important keys such as the HardwareID in the case of the AudibleUI keychain are not reset when all other values are expected to be wiped.
final class Keychain {

    init(keychainID: String, queueLabel: String, persistingKeys: [String] = []) {
        self.keychainID = keychainID
        self.queueLabel = queueLabel
        self.persistingKeys = persistingKeys
    }
    let keychainID: String
    let queueLabel: String
    let persistingKeys: [String]

    lazy var concurrentQueue = {
        DispatchQueue(
            label: queueLabel,
            attributes: .concurrent
        )
    }()
    var cache = [String: Data]()
    let dataLock = NSLock()

    subscript(key: String) -> String? {
        get { string(for: key) }
        set { set(string: newValue, for: key) }
    }

    subscript(key: String) -> Data? {
        get { data(for: key) }
        set { set(data: newValue, for: key) }
    }

    subscript(key: String) -> Bool? {
        get { bool(for: key) }
        set { set(bool: newValue, for: key) }
    }

    func reset() {
        // Grab the keys that should presist across resets.
        // For example with AudibleUI Keychain
        // the Hardware ID, Device ID & Activation Data will persist as they should never change.

        let cacheImportantKeys = persistingKeys
            .reduce(into: [String: Data]()) { result, key in
                result[key] = data(for: key)
            }

        // clear in-memory caches
        dataLock.lock()
        cache = [:]
        dataLock.unlock()

        // clear entries on disk
        do {
            try deleteAllKeys(for: kSecClassGenericPassword)
            try deleteAllKeys(for: kSecClassInternetPassword)
            try deleteAllKeys(for: kSecClassCertificate)
            try deleteAllKeys(for: kSecClassKey)
            try deleteAllKeys(for: kSecClassIdentity)
        } catch {
            // TODO log error
            print("Error Reseting Keychain! \(error)")
        }

        // reload back important keys that should survive a reset
        cacheImportantKeys.forEach {
            set(data: $0.value, for: $0.key)
        }
    }

    func hardReset() {
        // clear in-memory caches
        dataLock.lock()
        cache = [:]
        dataLock.unlock()

        // clear entries on disk
        do {
            try deleteAllKeys(for: kSecClassGenericPassword)
            try deleteAllKeys(for: kSecClassInternetPassword)
            try deleteAllKeys(for: kSecClassCertificate)
            try deleteAllKeys(for: kSecClassKey)
            try deleteAllKeys(for: kSecClassIdentity)
        } catch {
            // TODO log error
            print("Error Hard Reseting Keychain! \(error)")
        }
    }
}

// MARK: - String Methods
extension Keychain {
    func string(for key: String) -> String? {
        guard let data = data(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    func set(string: String?, for key: String) {
        set(data: string?.data(using: .utf8), for: key)
    }
}

// MARK: - Bool Methods
extension Keychain {
    func bool(for key: String) -> Bool? {
        guard let data = data(for: key) else { return nil }
        do {
            return try JSONDecoder().decode(Bool.self, from: data)
        } catch {
            return nil
        }
    }

    func set(bool: Bool?, for key: String) {
        guard let bool = bool else {
            set(data: nil, for: key)
            return
        }
        do {
            let data = try JSONEncoder().encode(bool)
            set(data: data, for: key)
        } catch {
            set(data: nil, for: key)
        }
    }
}

// MARK: - Data Methods
extension Keychain {
    func data(for key: String) -> Data? {
        var data: Data? = nil
        concurrentQueue.sync {
            // check in-memory cache
            if let _data = checkCache(for: key) {
                data = _data
                return
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
                return
            }

            // TODO: Noticed that in unit tests we encounter this issue
            // https://stackoverflow.com/questions/22082996/testing-the-keychain-osstatus-error-34018
            // Jira tiket created to find a workaround
            // https://jira.audible.com/browse/IOS-15895
            guard status == errSecSuccess else {
                // LOG ERROR
                // throw KeychainError.unhandledError(status: status)
                return
            }
            data = result as? Data
            // update cache
            cache(data: data, for: key)
        }
        return data
    }

    func set(data: Data?, for key: String) {
        // check disk - keychain
        concurrentQueue.sync(flags: .barrier) {
            // update in-memory cache
            cache(data: data, for: key)

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
}

// MARK: - Caching
extension Keychain {
    func cache(data: Data?, for key: String) {
        dataLock.lock()
        defer {
            dataLock.unlock()
        }
        cache[key] = data
    }

    func checkCache(for key: String) -> Data? {
        dataLock.lock()
        defer {
            dataLock.unlock()
        }
        return cache[key]
    }
}
// MARK: - Keychain CF Helper Methods
extension Keychain {
    func keychainDictionary(for id: String) -> [CFString: Any] {
        [
            kSecAttrService: id,
            kSecAttrGeneric: keychainID.data(using: .utf8)!,
            kSecClass: kSecClassGenericPassword
        ]
    }
}

extension Keychain {
    func deleteAllKeys(for secClass: CFString) throws {
        var error: (any Error)? = nil
        concurrentQueue.sync(flags: .barrier) {
            // delete
            let status = SecItemDelete([
                kSecClass: secClass
            ] as CFDictionary)
            // check for errors
            guard
                status == errSecSuccess || status == errSecItemNotFound
            else {
                error = KeychainError.unhandledError(status: status)
                return
            }
        }
        if let error = error {
            throw error
        }
    }
}
public enum KeychainError: Error {
    case noPassword
    case unhandledError(status: OSStatus)
}
