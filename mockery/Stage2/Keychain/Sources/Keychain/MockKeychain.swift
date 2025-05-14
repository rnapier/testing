import Foundation

public actor MockKeychain: KeychainProtocol {
  private var storage: [String: Data] = [:]

  //
  // Data accessors
  //
  public func data(for key: String) throws -> Data? { storage[key] }
  public func set(data: Data, for key: String) throws { storage[key] = data }
  public func removeData(for key: String) throws { storage[key] = nil }
  public func reset() throws { storage.removeAll() }

  //
  // Codable accessors
  //
  public func string(for key: String) throws -> String? { try decode(key: key) }
  public func set(string: String, for key: String) throws { try store(string, for: key)}
  public func bool(for key: String) throws -> Bool? { try decode(key: key) }
  public func set(bool: Bool, for key: String) throws { try store(bool, for: key) }
  public func int(for key: String) throws -> Int? { try decode(key: key) }
  public func set(int: Int, for key: String) throws { try store(int, for: key) }

  //
  // JSONSerialization accessors
  //
  public func value(for key: String) throws -> Any? {
    guard let data = storage[key] else { return nil }
    return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  }

  public func set(value: Any, for key: String) throws {
    storage[key] = try JSONSerialization.data(withJSONObject: data, options: [.fragmentsAllowed])
  }

  //
  // Private helpers
  //
  private func decode<T: Codable>(key: String, as: T.Type = T.self) throws -> T? {
    guard let data = storage[key] else { return nil }
    return try JSONDecoder().decode(T.self, from: data)
  }

  private func store<T: Codable>(_ value: T, for key: String) throws {
    storage[key] = try JSONEncoder().encode(value)
  }
}
