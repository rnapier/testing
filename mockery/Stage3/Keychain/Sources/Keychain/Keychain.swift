import Foundation

/// A Keychain wrapper that offers key/value storage with the following features:
///
/// * Takes an identifier to maintain separate stores
/// * Each Keychain offers independent key/value storage
/// * Caches values in memory
/// * Allows reading and writing Data directly
/// * Encodes Strings as UTF-8
/// * Encodes JSONSerialization-compatible types in JSON
/// * Supports "reset" to delete all keys in this Keychain
///
public actor Keychain: KeychainStorage {
  public let identifier: String
  private var cache: [String: Data] = [:]

  public init(identifier: String) {
    self.identifier = identifier
  }

  // MARK: - Data Operations

  public func data(for key: String) throws -> Data? {
    // First check the cache
    if let data = cache[key] {
      return data
    }

    // That terrible `SecItemCopyMatching` call you all know...
    let data = try _data(for: key)

    // And cache it for later
    cache[key] = data
    return data
  }

  public func set(data: Data, for key: String) throws {
    // Set it to the cache and to system keychain
    cache[key] = data
    try _set(data: data, for: key)
  }

  public func removeData(for key: String) throws {
    // Remove it from the cache and the system keychain
    cache[key] = nil
    try _removeData(for: key)
  }

  public func reset() throws {
    // Clear the cache and delete all keys for this identifier
    cache = [:]
    try _reset()
  }

  // MARK: - All those horrible low-level SecItem... wrappers that I'm not going to bore you with

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

  private func _data(for key: String) throws -> Data? {
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

  private func _set(data: Data, for key: String) throws {
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

  private func _removeData(for key: String) throws {
    let params = makeParameters(for: key)
    let status = SecItemDelete(params as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError(status)
    }
  }

  private func _reset() throws {
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

public struct KeychainError: Swift.Error {
  let status: OSStatus
  init(_ status: OSStatus) { self.status = status }
}
