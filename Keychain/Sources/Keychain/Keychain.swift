import Foundation
import OSLog

public actor Keychain {

  public init(keychainID: String) {
    self.keychainID = keychainID
  }

  public let keychainID: String

  private let log = Logger(subsystem: "Keychain", category: "Keychain")

  private var cache: [String: Data] = [:]

  public func reset() {
    cache = [:]

    // clear entries on disk
    deleteAllKeys(for: kSecClassGenericPassword)
    deleteAllKeys(for: kSecClassInternetPassword)
    deleteAllKeys(for: kSecClassCertificate)
    deleteAllKeys(for: kSecClassKey)
    deleteAllKeys(for: kSecClassIdentity)

    // Additional cleanup for keychain specific entries
    let query: [CFString: Any] = [
      kSecAttrService: kSecAttrGeneric,
      kSecAttrGeneric: Data(keychainID.utf8),
      kSecClass: kSecClassGenericPassword,
    ]
    let status = SecItemDelete(query as CFDictionary)
    if status != errSecSuccess {
      log.error("Error deleting keychain specific entries: \(status)")
    }
  }

  public func string(for key: String) -> String? {
    guard let data = data(for: key) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  public func set(string: String?, for key: String) {
    set(data: string != nil ? Data(string!.utf8) : nil, for: key)
  }

  public func bool(for key: String) -> Bool? {
    guard let data = data(for: key) else { return nil }
    do {
      return try JSONDecoder().decode(Bool.self, from: data)
    } catch {
      return nil
    }
  }

  public func set(bool: Bool?, for key: String) {
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

  public func data(for key: String) -> Data? {
    if let data = cache[key] {
      return data
    }

    var params = keychainDictionary(for: key)
    params[kSecMatchLimit] = kSecMatchLimitOne
    params[kSecReturnData] = kCFBooleanTrue
    var result: CFTypeRef?
    let status = SecItemCopyMatching(
      params as CFDictionary,
      &result
    )

    if status == errSecItemNotFound {
      return nil
    }

    guard status == errSecSuccess else {
      log.error("Error reading keychain: \(status)")
      return nil
    }

    let data = result as? Data

    cache[key] = data
    return data
  }

  public func set(data: Data?, for key: String) {
    cache[key] = data

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
      params[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      params[kSecValueData] = data
      status = SecItemAdd(params as CFDictionary, nil)
    }
    guard status != errSecSuccess else {
      log.error("Could not write data for key \(key): \(status)")
      return
    }
  }

  private func keychainDictionary(for id: String) -> [CFString: Any] {
    [
      kSecAttrService: id,
      kSecAttrGeneric: Data(keychainID.utf8),
      kSecClass: kSecClassGenericPassword,
    ]
  }

  private func deleteAllKeys(for secClass: CFString) {
    // delete
    let status = SecItemDelete(
      [
        kSecClass: secClass
      ] as CFDictionary)

    // check for errors
    if status != errSecSuccess && status != errSecItemNotFound {
      log.error("Error resetting \(secClass): \(status)")
    }
  }
}
