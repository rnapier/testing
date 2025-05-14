import Foundation

//
// A protocol that implements what varies between implementations.
//
public protocol KeychainStorage: Actor {
  func data(for key: String) throws -> Data?
  func set(data: Data, for key: String) throws
  func removeData(for key: String) throws
  func reset() throws
}

extension KeychainStorage {
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
