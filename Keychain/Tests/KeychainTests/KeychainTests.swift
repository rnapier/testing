import Testing
import Foundation
@testable import Keychain

@Suite class KeychainTests {
  var keychain: Keychain { .current }

  @Test(.withKeychain)
  func testStringStorageAndRetrieval() async throws {
    let key = "testString"
    let value = "Hello, Keychain!"

    // Store the value
    try await keychain.set(string: value, for: key)

    // Retrieve the value
    let retrieved = try await keychain.string(for: key)

    // Verify
    #expect(retrieved == value)
  }

  @Test(.withKeychain)
  func testStringMethodStorageAndRetrieval() async throws {
    let key = "testStringMethod"
    let value = "Hello, Keychain Method!"

    // Store the value using method
    try await keychain.set(string: value, for: key)

    // Retrieve the value using method
    let retrieved = try await keychain.string(for: key)

    // Verify
    #expect(retrieved == value)
  }

  @Test(.withKeychain)
  func testDataStorageAndRetrieval() async throws {
    let key = "testData"
    let value = Data("Binary Data".utf8)

    // Store the value
    try await keychain.set(data: value, for: key)

    // Retrieve the value
    let retrieved = try await keychain.data(for: key)

    // Verify
    #expect(retrieved == value)
  }

  @Test(.withKeychain)
  func testDataMethodStorageAndRetrieval() async throws {
    let key = "testDataMethod"
    let value = Data("Binary Data Method".utf8)

    // Store the value using method
    try await keychain.set(data: value, for: key)

    // Retrieve the value using method
    let retrieved = try await keychain.data(for: key)

    // Verify
    #expect(retrieved == value)
  }

  @Test(.withKeychain)
  func testBoolStorageAndRetrieval() async throws {
    let key = "testBool"
    let value = true

    // Store the value
    try await keychain.set(bool: value, for: key)

    // Retrieve the value
    let retrieved = try await keychain.bool(for: key)

    // Verify
    #expect(retrieved == value)
  }

  @Test(.withKeychain)
  func testBoolMethodStorageAndRetrieval() async throws {
    let key = "testBoolMethod"
    let value = true

    // Store the value using method
    try await keychain.set(bool: value, for: key)

    // Retrieve the value using method
    let retrieved = try await keychain.bool(for: key)

    // Verify
    #expect(retrieved == value)
  }

  @Test(.withKeychain)
  func testOverwritingValues() async throws {
    let key = "testOverwrite"

    // Store initial value
    try await keychain.set(string: "Initial Value", for: key)

    // Overwrite with new value
    try await keychain.set(string: "New Value", for: key)

    // Retrieve the value
    let retrieved = try await keychain.string(for: key)

    // Verify
    #expect(retrieved == "New Value")
  }

  @Test(.withKeychain)
  func testDeletingValues() async throws {
    let key = "testDelete"

    // Store a value
    try await keychain.set(string: "Value to Delete", for: key)

    // Verify it was stored
    #expect(try await keychain.string(for: key) != nil)

    // Delete by setting nil
    try await keychain.set(string: nil, for: key)

    // Verify it was deleted
    #expect(try await keychain.string(for: key) == nil)
  }

  @Test(.withKeychain)
  func testDeletingDataValues() async throws {
    let key = "testDeleteData"

    // Store a value
    try await keychain.set(data: Data("Data to Delete".utf8), for: key)

    // Verify it was stored
    #expect(try await keychain.data(for: key) != nil)

    // Delete by setting nil
    try await keychain.set(data: nil, for: key)

    // Verify it was deleted
    #expect(try await keychain.data(for: key) == nil)
  }

  // MARK: - Reset Functionality Tests

  @Test(.withKeychain)
  func testReset() async throws {
    let key = "testKey"

    // Store a value
    try await keychain.set(string: "Test Value", for: key)

    // Verify it was stored
    #expect(try await keychain.string(for: key) == "Test Value")

    // Reset the keychain
    try await keychain.reset()

    // Verify the key was deleted
    #expect(try await keychain.string(for: key) == nil)
  }

  @Test(.withKeychain)
  func testMultipleDataTypes() async throws {
    // Store different data types
    try await keychain.set(string: "String Value", for: "stringKey")
    try await keychain.set(bool: true, for: "boolKey")
    try await keychain.set(data: Data("Data Value".utf8), for: "dataKey")

    // Verify all values were stored correctly
    #expect(try await keychain.string(for: "stringKey") == "String Value")
    #expect(try await keychain.bool(for: "boolKey") == true)
    #expect(try await keychain.data(for: "dataKey") == Data("Data Value".utf8))
  }

  @Test(.withKeychain)
  func testCacheConsistency() async throws {
    let key = "cacheTest"

    // Store a value
    try await keychain.set(string: "Cached Value", for: key)

    // Read it multiple times to ensure cache consistency
    let firstRead = try await keychain.string(for: key)
    let secondRead = try await keychain.string(for: key)

    // Verify both reads return the same value
    #expect(firstRead == secondRead)
    #expect(firstRead == "Cached Value")
  }
}

extension Keychain {
  @TaskLocal static var current: Keychain!
}

struct KeychainTrait: TestTrait, TestScoping {
  var isRecursive: Bool { true }

  func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {

    let keychain = Keychain(keychainID: "test.keychain.\(UUID())")

    try await Keychain.$current.withValue(keychain) {

      var error: Error? = nil
      do {
        try await function()
      } catch let e {
        error = e
      }

      try await keychain.reset()

      if let error {
        throw error
      }
    }
  }
}

extension Trait where Self == KeychainTrait {
  static var withKeychain: Self {
    Self()
  }
}
