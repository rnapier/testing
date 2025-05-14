import Foundation
import Testing

@testable import Keychain

@Suite class KeychainTests {
  var keychain: Keychain = Keychain(storage: nil)

  @Test
  func testCrossStorage() async throws {
    // Write it as String
    try await keychain.set(string: "abc", for: "key")

    // Read it as data
    let data = try #require(try await keychain.data(for: "key"))
    let result = String(decoding: data, as: UTF8.self)

    #expect(result == "abc")
  }

  @Test
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

  @Test
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

  @Test
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

  @Test
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

  @Test
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

  @Test
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

  @Test
  func testIntStorageAndRetrieval() async throws {
    let key = "testInt"
    let value = 42

    // Store the value
    try await keychain.set(int: value, for: key)

    // Retrieve the value
    let retrieved = try await keychain.int(for: key)

    // Verify
    #expect(retrieved == value)
  }

  @Test
  func testIntMethodStorageAndRetrieval() async throws {
    let key = "testIntMethod"
    let value = 12345

    // Store the value using method
    try await keychain.set(int: value, for: key)

    // Retrieve the value using method
    let retrieved = try await keychain.int(for: key)

    // Verify
    #expect(retrieved == value)
  }

  @Test
  func testGenericValueStorageAndRetrieval() async throws {
    let key = "testGenericValue"
    let name = "Test User"
    let age = 30
    let isAdmin = true

    // Create dictionary data using individual components
    let nameData = try JSONEncoder().encode(name)
    let ageData = try JSONEncoder().encode(age)
    let isAdminData = try JSONEncoder().encode(isAdmin)

    // Store individual components
    try await keychain.set(data: nameData, for: "\(key).name")
    try await keychain.set(data: ageData, for: "\(key).age")
    try await keychain.set(data: isAdminData, for: "\(key).isAdmin")

    // Retrieve individual values
    let retrievedName = try await JSONDecoder().decode(
      String.self, from: keychain.data(for: "\(key).name") ?? Data())
    let retrievedAge = try await JSONDecoder().decode(
      Int.self, from: keychain.data(for: "\(key).age") ?? Data())
    let retrievedIsAdmin = try await JSONDecoder().decode(
      Bool.self, from: keychain.data(for: "\(key).isAdmin") ?? Data())

    // Verify each component
    #expect(retrievedName == name)
    #expect(retrievedAge == age)
    #expect(retrievedIsAdmin == isAdmin)
  }

  @Test
  func testArrayStorageAndRetrieval() async throws {
    let key = "testArrayValue"
    let fruits = ["Apple", "Banana", "Orange"]

    // Encode array to data
    let fruitData = try JSONEncoder().encode(fruits)

    // Store data
    try await keychain.set(data: fruitData, for: key)

    // Retrieve and decode
    let retrievedData = try await keychain.data(for: key)
    let retrievedFruits = try JSONDecoder().decode([String].self, from: retrievedData ?? Data())

    // Verify array contents
    #expect(retrievedFruits.count == 3)
    #expect(retrievedFruits[0] == "Apple")
    #expect(retrievedFruits[1] == "Banana")
    #expect(retrievedFruits[2] == "Orange")
  }

  @Test
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

  @Test
  func testDeletingValues() async throws {
    let key = "testDelete"

    // Store a value
    try await keychain.set(string: "Value to Delete", for: key)

    // Verify it was stored
    #expect(try await keychain.string(for: key) != nil)

    // Delete
    try await keychain.removeData(for: key)

    // Verify it was deleted
    #expect(try await keychain.string(for: key) == nil)
  }

  @Test
  func testDeletingDataValues() async throws {
    let key = "testDeleteData"

    // Store a value
    try await keychain.set(data: Data("Data to Delete".utf8), for: key)

    // Verify it was stored
    #expect(try await keychain.data(for: key) != nil)

    // Delete by setting nil
    try await keychain.removeData(for: key)

    // Verify it was deleted
    #expect(try await keychain.data(for: key) == nil)
  }

  // MARK: - Reset Functionality Tests

  @Test
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

  @Test
  func testMultipleDataTypes() async throws {
    // Store different data types
    try await keychain.set(string: "String Value", for: "stringKey")
    try await keychain.set(bool: true, for: "boolKey")
    try await keychain.set(data: Data("Data Value".utf8), for: "dataKey")
    try await keychain.set(int: 123, for: "intKey")

    // Verify all values were stored correctly
    #expect(try await keychain.string(for: "stringKey") == "String Value")
    #expect(try await keychain.bool(for: "boolKey") == true)
    #expect(try await keychain.data(for: "dataKey") == Data("Data Value".utf8))
    #expect(try await keychain.int(for: "intKey") == 123)
  }

  @Test
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
