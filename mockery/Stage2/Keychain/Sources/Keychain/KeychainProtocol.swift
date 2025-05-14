import Foundation

//
// A protocol that exactly matches the interface of Keychain so we can mock it.
//
public protocol KeychainProtocol: Actor {
  func data(for key: String) throws -> Data?
  func set(data: Data, for key: String) throws
  func removeData(for key: String) throws
  func reset() throws

  func string(for key: String) throws -> String?
  func set(string: String, for key: String) throws

  func value(for key: String) throws -> Any?
  func set(value: Any, for key: String) throws

  func bool(for key: String) throws -> Bool?
  func set(bool: Bool, for key: String) throws

  func int(for key: String) throws -> Int?
  func set(int: Int, for key: String) throws
}
