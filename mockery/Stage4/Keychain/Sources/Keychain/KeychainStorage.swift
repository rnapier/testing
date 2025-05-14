import Foundation

// A type that just manages talking to system keychain and nothing else
struct KeychainStorage {
  let identifier: String

  init(identifier: String) { self.identifier = identifier}

  private func makeParameters(for key: String?) -> [CFString: Any] {
    var query: [CFString: Any] = [
      kSecAttrGeneric: Data(self.identifier.utf8),
      kSecClass: kSecClassGenericPassword,
    ]
    if let key {
      query[kSecAttrService] = key
    }
    return query
  }

  func data(for key: String) throws -> Data? {
    var params = makeParameters(for: key)
    params[kSecMatchLimit] = kSecMatchLimitOne
    params[kSecReturnData] = kCFBooleanTrue
    var result: CFTypeRef?
    let status = SecItemCopyMatching(
      params as CFDictionary,
      &result)

    if status == errSecItemNotFound {
      return nil
    }

    guard status == errSecSuccess else {
      throw KeychainError(status)
    }

    return result as? Data
  }

  func set(data: Data, for key: String) throws {
    var params = makeParameters(for: key)

    // Attempt to update the entry
    var status = SecItemUpdate(
      params as CFDictionary,
      [kSecValueData: data] as CFDictionary)

    // If it doesn't exist, try adding it
    if status == errSecItemNotFound {
      params[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      params[kSecValueData] = data
      status = SecItemAdd(params as CFDictionary, nil)
    }

    guard status == errSecSuccess else {
      throw KeychainError(status)
    }
  }

  func removeData(for key: String) throws {
    let params = makeParameters(for: key)
    let status = SecItemDelete(params as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError(status)
    }
  }

  func reset() throws {
    var query = makeParameters(for: nil)
#if os(macOS)
    query[kSecMatchLimit] = kSecMatchLimitAll
#endif

    let status = SecItemDelete(query as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError(status)
    }
  }
}
