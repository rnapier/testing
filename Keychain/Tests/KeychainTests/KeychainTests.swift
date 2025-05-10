import Testing
import Foundation
@testable import Keychain

// MARK: - Test Helpers

/// Creates a test keychain with a unique ID to avoid interfering with real data
func createTestKeychain(persistingKeys: [String] = []) -> Keychain {
    let uuid = UUID().uuidString
    return Keychain(
        keychainID: "com.test.keychain.\(uuid)",
        queueLabel: "com.test.keychain.queue.\(uuid)",
        persistingKeys: persistingKeys
    )
}

// MARK: - Basic Functionality Tests

@Test func testStringStorageAndRetrieval() {
    let keychain = createTestKeychain()
    let key = "testString"
    let value = "Hello, Keychain!"
    
    // Store the value
    keychain.set(string: value, for: key)
    
    // Retrieve the value
    let retrieved = keychain.string(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    keychain.hardReset()
}

@Test func testStringMethodStorageAndRetrieval() {
    let keychain = createTestKeychain()
    let key = "testStringMethod"
    let value = "Hello, Keychain Method!"
    
    // Store the value using method
    keychain.set(string: value, for: key)
    
    // Retrieve the value using method
    let retrieved = keychain.string(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    keychain.hardReset()
}

@Test func testDataStorageAndRetrieval() {
    let keychain = createTestKeychain()
    let key = "testData"
    let value = "Binary Data".data(using: .utf8)!
    
    // Store the value
    keychain.set(data: value, for: key)
    
    // Retrieve the value
    let retrieved = keychain.data(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    keychain.hardReset()
}

@Test func testDataMethodStorageAndRetrieval() {
    let keychain = createTestKeychain()
    let key = "testDataMethod"
    let value = "Binary Data Method".data(using: .utf8)!
    
    // Store the value using method
    keychain.set(data: value, for: key)
    
    // Retrieve the value using method
    let retrieved = keychain.data(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    keychain.hardReset()
}

@Test func testBoolStorageAndRetrieval() {
    let keychain = createTestKeychain()
    let key = "testBool"
    let value = true
    
    // Store the value
    keychain.set(bool: value, for: key)
    
    // Retrieve the value
    let retrieved = keychain.bool(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    keychain.hardReset()
}

@Test func testBoolMethodStorageAndRetrieval() {
    let keychain = createTestKeychain()
    let key = "testBoolMethod"
    let value = true
    
    // Store the value using method
    keychain.set(bool: value, for: key)
    
    // Retrieve the value using method
    let retrieved = keychain.bool(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    keychain.hardReset()
}

@Test func testOverwritingValues() {
    let keychain = createTestKeychain()
    let key = "testOverwrite"
    
    // Store initial value
    keychain.set(string: "Initial Value", for: key)
    
    // Overwrite with new value
    keychain.set(string: "New Value", for: key)
    
    // Retrieve the value
    let retrieved = keychain.string(for: key)
    
    // Verify
    #expect(retrieved == "New Value")
    
    // Clean up
    keychain.hardReset()
}

@Test func testDeletingValues() {
    let keychain = createTestKeychain()
    let key = "testDelete"
    
    // Store a value
    keychain.set(string: "Value to Delete", for: key)
    
    // Verify it was stored
    #expect(keychain.string(for: key) != nil)
    
    // Delete by setting nil
    keychain.set(string: nil, for: key)
    
    // Verify it was deleted
    #expect(keychain.string(for: key) == nil)
    
    // Clean up
    keychain.hardReset()
}

@Test func testDeletingDataValues() {
    let keychain = createTestKeychain()
    let key = "testDeleteData"
    
    // Store a value
    keychain.set(data: "Data to Delete".data(using: .utf8), for: key)
    
    // Verify it was stored
    #expect(keychain.data(for: key) != nil)
    
    // Delete by setting nil
    keychain.set(data: nil, for: key)
    
    // Verify it was deleted
    #expect(keychain.data(for: key) == nil)
    
    // Clean up
    keychain.hardReset()
}

// MARK: - Reset Functionality Tests

@Test func testResetWithPersistingKeys() {
    let persistingKey = "persistingKey"
    let regularKey = "regularKey"
    let keychain = createTestKeychain(persistingKeys: [persistingKey])
    
    // Store values
    keychain.set(string: "Persistent Value", for: persistingKey)
    keychain.set(string: "Regular Value", for: regularKey)
    
    // Verify both values were stored
    #expect(keychain.string(for: persistingKey) == "Persistent Value")
    #expect(keychain.string(for: regularKey) == "Regular Value")
    
    // Reset the keychain
    keychain.reset()
    
    // Verify persisting key survived but regular key was deleted
    #expect(keychain.string(for: persistingKey) == "Persistent Value")
    #expect(keychain.string(for: regularKey) == nil)
    
    // Clean up
    keychain.hardReset()
}

@Test func testHardReset() {
    let persistingKey = "persistingKey"
    let regularKey = "regularKey"
    let keychain = createTestKeychain(persistingKeys: [persistingKey])
    
    // Store values
    keychain.set(string: "Persistent Value", for: persistingKey)
    keychain.set(string: "Regular Value", for: regularKey)
    
    // Verify both values were stored
    #expect(keychain.string(for: persistingKey) == "Persistent Value")
    #expect(keychain.string(for: regularKey) == "Regular Value")
    
    // Hard reset the keychain
    keychain.hardReset()
    
    // Verify both keys were deleted
    #expect(keychain.string(for: persistingKey) == nil)
    #expect(keychain.string(for: regularKey) == nil)
}

@Test func testMultipleDataTypes() {
    let keychain = createTestKeychain()
    
    // Store different data types
    keychain.set(string: "String Value", for: "stringKey")
    keychain.set(bool: true, for: "boolKey")
    keychain.set(data: "Data Value".data(using: .utf8)!, for: "dataKey")
    
    // Verify all values were stored correctly
    #expect(keychain.string(for: "stringKey") == "String Value")
    #expect(keychain.bool(for: "boolKey") == true)
    #expect(keychain.data(for: "dataKey") == "Data Value".data(using: .utf8)!)
    
    // Clean up
    keychain.hardReset()
}

@Test func testCacheConsistency() {
    let keychain = createTestKeychain()
    let key = "cacheTest"
    
    // Store a value
    keychain.set(string: "Cached Value", for: key)
    
    // Read it multiple times to ensure cache consistency
    let firstRead = keychain.string(for: key)
    let secondRead = keychain.string(for: key)
    
    // Verify both reads return the same value
    #expect(firstRead == secondRead)
    #expect(firstRead == "Cached Value")
    
    // Clean up
    keychain.hardReset()
}
