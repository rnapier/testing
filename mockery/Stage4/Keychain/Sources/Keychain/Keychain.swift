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
public actor Keychain {
  private var cache: [String: Data] = [:]
  private let storage: KeychainStorage?

  public init(identifier: String) {
    self.storage = KeychainStorage(identifier: identifier)
  }

  // For tests, but we can do better than this.
  init(storage: KeychainStorage?) {
    self.storage = storage
  }

  // MARK: - Data Operations

  public func data(for key: String) throws -> Data? {
    // First check the cache
    if let data = cache[key] {
      return data
    }

    // That terrible `SecItemCopyMatching` call you all know...
    let data = try storage?.data(for: key)

    // And cache it for later
    cache[key] = data
    return data
  }

  public func set(data: Data, for key: String) throws {
    // Set it to the cache and to system keychain
    cache[key] = data
    try storage?.set(data: data, for: key)
  }

  public func removeData(for key: String) throws {
    // Remove it from the cache and the system keychain
    cache[key] = nil
    try storage?.removeData(for: key)
  }

  public func reset() throws {
    // Clear the cache and delete all keys for this identifier
    cache = [:]
    try storage?.reset()
  }

  // MARK: - String Operations -- Encode as UTF-8

  public func string(for key: String) throws -> String? {
    guard let data = try data(for: key) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  public func set(string: String, for key: String) throws {
    try set(data: Data(string.utf8), for: key)
  }

  // MARK: - JSONSerialization Operations

  public func value(for key: String) throws -> Any? {
    guard let data = try data(for: key) else { return nil }
    return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  }

  public func set(value: Any, for key: String) throws {
    let data = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
    try set(data: data, for: key)
  }

  // MARK: - Public Extensions for Common Types (Bool, Int)

  public func bool(for key: String) throws -> Bool? {
    try value(for: key) as? Bool
  }

  public func set(bool: Bool, for key: String) throws {
    try set(value: bool, for: key)
  }

  public func int(for key: String) throws -> Int? {
    try value(for: key) as? Int
  }

  public func set(int: Int, for key: String) throws {
    try set(value: int, for: key)
  }
}

public struct KeychainError: Swift.Error {
  let status: OSStatus
  init(_ status: OSStatus) { self.status = status }
}
