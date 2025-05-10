import Testing
import Foundation
@testable import Keychain

// MARK: - Test Helpers

@Suite class KeychainTests {
  let keychain = Keychain(keychainID: "test.keychain.\(UUID())")

  func tearDown() async throws {
    try await keychain.reset()
  }

  func withCleanup(perform: () async throws -> Void) async throws {
    do {
      try await perform()
    } catch {
      try await tearDown()
      throw error
    }
    try await tearDown()
  }

  @Test
  func testStringStorageAndRetrieval() async throws {
    try await withCleanup {
      let key = "testString"
      let value = "Hello, Keychain!"

      // Store the value
      try await keychain.set(string: value, for: key)

      // Retrieve the value
      let retrieved = try await keychain.string(for: key)

      // Verify
      #expect(retrieved == value)
    }
  }

  @Test
  func testStringMethodStorageAndRetrieval() async throws {
    try await withCleanup {
      let key = "testStringMethod"
      let value = "Hello, Keychain Method!"

      // Store the value using method
      try await keychain.set(string: value, for: key)

      // Retrieve the value using method
      let retrieved = try await keychain.string(for: key)

      // Verify
      #expect(retrieved == value)
    }
  }

  @Test
  func testDataStorageAndRetrieval() async throws {
    try await withCleanup {
      let key = "testData"
      let value = Data("Binary Data".utf8)

      // Store the value
      try await keychain.set(data: value, for: key)

      // Retrieve the value
      let retrieved = try await keychain.data(for: key)

      // Verify
      #expect(retrieved == value)
    }
  }

  @Test
  func testDataMethodStorageAndRetrieval() async throws {
    try await withCleanup {
      let key = "testDataMethod"
      let value = Data("Binary Data Method".utf8)

      // Store the value using method
      try await keychain.set(data: value, for: key)

      // Retrieve the value using method
      let retrieved = try await keychain.data(for: key)

      // Verify
      #expect(retrieved == value)
    }
  }

  @Test
  func testBoolStorageAndRetrieval() async throws {
    try await withCleanup {
      let key = "testBool"
      let value = true

      // Store the value
      try await keychain.set(bool: value, for: key)

      // Retrieve the value
      let retrieved = try await keychain.bool(for: key)

      // Verify
      #expect(retrieved == value)
    }
  }

  @Test
  func testBoolMethodStorageAndRetrieval() async throws {
    try await withCleanup {
      let key = "testBoolMethod"
      let value = true

      // Store the value using method
      try await keychain.set(bool: value, for: key)

      // Retrieve the value using method
      let retrieved = try await keychain.bool(for: key)

      // Verify
      #expect(retrieved == value)
    }
  }

  @Test
  func testOverwritingValues() async throws {
    try await withCleanup {
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
  }

  @Test
  func testDeletingValues() async throws {
    try await withCleanup {
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
  }

  @Test
  func testDeletingDataValues() async throws {
    try await withCleanup {
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
  }

  // MARK: - Reset Functionality Tests

  @Test
  func testReset() async throws {
    try await withCleanup {
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
  }

  @Test
  func testMultipleDataTypes() async throws {
    try await withCleanup {
      // Store different data types
      try await keychain.set(string: "String Value", for: "stringKey")
      try await keychain.set(bool: true, for: "boolKey")
      try await keychain.set(data: Data("Data Value".utf8), for: "dataKey")

      // Verify all values were stored correctly
      #expect(try await keychain.string(for: "stringKey") == "String Value")
      #expect(try await keychain.bool(for: "boolKey") == true)
      #expect(try await keychain.data(for: "dataKey") == Data("Data Value".utf8))
    }
  }

  @Test
  func testCacheConsistency() async throws {
    try await withCleanup {
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
}
