import Foundation

public actor Keychain {
  enum Error: Swift.Error {
    case keychain(OSStatus)
  }

  public init(keychainID: String) {
    self.keychainID = keychainID
  }

  public let keychainID: String

  private var cache: [String: Data] = [:]

  public func reset() throws {
    cache = [:]

    var query = keychainDictionary(for: nil)
#if os(macOS)
    query[kSecMatchLimit] = kSecMatchLimitAll
#endif

    let status = SecItemDelete(query as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw Error.keychain(status)
    }
  }

  public func string(for key: String) throws -> String? {
    guard let data = try data(for: key) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  public func set(string: String?, for key: String) throws {
    try set(data: string.map { Data($0.utf8) }, for: key)
  }

  public func value(for key: String) throws -> Any? {
    guard let data = try data(for: key) else { return nil }
    return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  }

  public func set(value: Any?, for key: String) throws {
    guard let value else {
      try set(data: nil, for: key)
      return
    }

    try set(data: JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]), for: key)
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
      throw Error.keychain(status)
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
      throw Error.keychain(status)
    }
  }

  private func keychainDictionary(for id: String?) -> [CFString: Any] {
    var query: [CFString: Any] = [
      kSecAttrGeneric: Data(keychainID.utf8),
      kSecClass: kSecClassGenericPassword,
    ]
    if let id {
      query[kSecAttrService] = id
    }
    return query
  }
}

// Helpers
extension Keychain {
  public func bool(for key: String) throws -> Bool? {
    try value(for: key) as? Bool
  }

  public func set(bool: Bool?, for key: String) throws {
    try set(value: bool, for: key)
  }

  public func int(for key: String) throws -> Int? {
    try value(for: key) as? Int
  }

  public func set(int: Int?, for key: String) throws {
    try set(value: int, for: key)
  }
}
