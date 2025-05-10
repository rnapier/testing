import Foundation

public actor Keychain {
  struct Error: Swift.Error {
    var status: OSStatus
  }

  public init(keychainID: String) {
    self.keychainID = keychainID
  }

  // Test helper to directly add values to cache for testing
  public func addToTestCache(value: Data?, for key: String) {
    cache[key] = value
  }

  public let keychainID: String

  private var cache: [String: Data] = [:]

  public func reset() throws {
    cache = [:]

    var query: [CFString: Any] = [
      kSecAttrGeneric: Data(keychainID.utf8),
      kSecClass: kSecClassGenericPassword,
    ]
#if os(macOS)
    query[kSecMatchLimit] = kSecMatchLimitAll
#endif

    let status = SecItemDelete(query as CFDictionary)
    if status != errSecSuccess && status != errSecItemNotFound {
      throw Error(status: status)
    }
  }

  public func string(for key: String) throws -> String? {
    guard let data = try data(for: key) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  public func set(string: String?, for key: String) throws {
    try set(data: string.map { Data($0.utf8) }, for: key)
  }

  public func bool(for key: String) throws -> Bool? {
    guard let data = try data(for: key) else { return nil }
    do {
      return try JSONDecoder().decode(Bool.self, from: data)
    } catch {
      return nil
    }
  }

  public func set(bool: Bool?, for key: String) throws {
    guard let bool = bool else {
      try set(data: nil, for: key)
      return
    }
    do {
      let data = try JSONEncoder().encode(bool)
      try set(data: data, for: key)
    } catch {
      try set(data: nil, for: key)
    }
  }

  public func data(for key: String) throws -> Data? {
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
      throw Error(status: status)
    }

    let data = result as? Data

    cache[key] = data
    return data
  }

  public func set(data: Data?, for key: String) throws {
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
    guard status == errSecSuccess else {
      throw Error(status: status)
    }
  }

  private func keychainDictionary(for id: String) -> [CFString: Any] {
    [
      kSecAttrService: id,
      kSecAttrGeneric: Data(keychainID.utf8),
      kSecClass: kSecClassGenericPassword,
    ]
  }
}
