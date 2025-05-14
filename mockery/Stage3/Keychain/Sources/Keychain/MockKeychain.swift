import Foundation

public actor MockKeychain: KeychainStorage {
  private var storage: [String: Data] = [:]

  public func data(for key: String) throws -> Data? { storage[key] }
  public func set(data: Data, for key: String) throws { storage[key] = data }
  public func removeData(for key: String) throws { storage[key] = nil }
  public func reset() throws { storage.removeAll() }
}
