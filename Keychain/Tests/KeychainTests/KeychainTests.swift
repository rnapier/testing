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

@Test
func testStringStorageAndRetrieval() async {
    let keychain = createTestKeychain()
    let key = "testString"
    let value = "Hello, Keychain!"
    
    // Store the value
    await keychain.set(string: value, for: key)
    
    // Retrieve the value
    let retrieved = await keychain.string(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testStringMethodStorageAndRetrieval() async {
    let keychain = createTestKeychain()
    let key = "testStringMethod"
    let value = "Hello, Keychain Method!"
    
    // Store the value using method
    await keychain.set(string: value, for: key)
    
    // Retrieve the value using method
    let retrieved = await keychain.string(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testDataStorageAndRetrieval() async {
    let keychain = createTestKeychain()
    let key = "testData"
    let value = "Binary Data".data(using: .utf8)!
    
    // Store the value
    await keychain.set(data: value, for: key)
    
    // Retrieve the value
    let retrieved = await keychain.data(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testDataMethodStorageAndRetrieval() async {
    let keychain = createTestKeychain()
    let key = "testDataMethod"
    let value = "Binary Data Method".data(using: .utf8)!
    
    // Store the value using method
    await keychain.set(data: value, for: key)
    
    // Retrieve the value using method
    let retrieved = await keychain.data(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testBoolStorageAndRetrieval() async {
    let keychain = createTestKeychain()
    let key = "testBool"
    let value = true
    
    // Store the value
    await keychain.set(bool: value, for: key)
    
    // Retrieve the value
    let retrieved = await keychain.bool(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testBoolMethodStorageAndRetrieval() async {
    let keychain = createTestKeychain()
    let key = "testBoolMethod"
    let value = true
    
    // Store the value using method
    await keychain.set(bool: value, for: key)
    
    // Retrieve the value using method
    let retrieved = await keychain.bool(for: key)
    
    // Verify
    #expect(retrieved == value)
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testOverwritingValues() async {
    let keychain = createTestKeychain()
    let key = "testOverwrite"
    
    // Store initial value
    await keychain.set(string: "Initial Value", for: key)
    
    // Overwrite with new value
    await keychain.set(string: "New Value", for: key)
    
    // Retrieve the value
    let retrieved = await keychain.string(for: key)
    
    // Verify
    #expect(retrieved == "New Value")
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testDeletingValues() async {
    let keychain = createTestKeychain()
    let key = "testDelete"
    
    // Store a value
    await keychain.set(string: "Value to Delete", for: key)
    
    // Verify it was stored
    #expect(await keychain.string(for: key) != nil)
    
    // Delete by setting nil
    await keychain.set(string: nil, for: key)
    
    // Verify it was deleted
    #expect(await keychain.string(for: key) == nil)
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testDeletingDataValues() async {
    let keychain = createTestKeychain()
    let key = "testDeleteData"
    
    // Store a value
    await keychain.set(data: "Data to Delete".data(using: .utf8), for: key)
    
    // Verify it was stored
    #expect(await keychain.data(for: key) != nil)
    
    // Delete by setting nil
    await keychain.set(data: nil, for: key)
    
    // Verify it was deleted
    #expect(await keychain.data(for: key) == nil)
    
    // Clean up
    await keychain.hardReset()
}

// MARK: - Reset Functionality Tests

@Test
func testResetWithPersistingKeys() async {
    let persistingKey = "persistingKey"
    let regularKey = "regularKey"
    let keychain = createTestKeychain(persistingKeys: [persistingKey])
    
    // Store values
    await keychain.set(string: "Persistent Value", for: persistingKey)
    await keychain.set(string: "Regular Value", for: regularKey)
    
    // Verify both values were stored
    #expect(await keychain.string(for: persistingKey) == "Persistent Value")
    #expect(await keychain.string(for: regularKey) == "Regular Value")
    
    // Reset the keychain
    await keychain.reset()
    
    // Verify persisting key survived but regular key was deleted
    #expect(await keychain.string(for: persistingKey) == "Persistent Value")
    #expect(await keychain.string(for: regularKey) == nil)
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testHardReset() async {
    let persistingKey = "persistingKey"
    let regularKey = "regularKey"
    let keychain = createTestKeychain(persistingKeys: [persistingKey])
    
    // Store values
    await keychain.set(string: "Persistent Value", for: persistingKey)
    await keychain.set(string: "Regular Value", for: regularKey)
    
    // Verify both values were stored
    #expect(await keychain.string(for: persistingKey) == "Persistent Value")
    #expect(await keychain.string(for: regularKey) == "Regular Value")
    
    // Hard reset the keychain
    await keychain.hardReset()
    
    // Verify both keys were deleted
    #expect(await keychain.string(for: persistingKey) == nil)
    #expect(await keychain.string(for: regularKey) == nil)
}

@Test
func testMultipleDataTypes() async {
    let keychain = createTestKeychain()
    
    // Store different data types
    await keychain.set(string: "String Value", for: "stringKey")
    await keychain.set(bool: true, for: "boolKey")
    await keychain.set(data: "Data Value".data(using: .utf8)!, for: "dataKey")
    
    // Verify all values were stored correctly
    #expect(await keychain.string(for: "stringKey") == "String Value")
    #expect(await keychain.bool(for: "boolKey") == true)
    #expect(await keychain.data(for: "dataKey") == "Data Value".data(using: .utf8)!)
    
    // Clean up
    await keychain.hardReset()
}

@Test
func testCacheConsistency() async {
    let keychain = createTestKeychain()
    let key = "cacheTest"
    
    // Store a value
    await keychain.set(string: "Cached Value", for: key)
    
    // Read it multiple times to ensure cache consistency
    let firstRead = await keychain.string(for: key)
    let secondRead = await keychain.string(for: key)
    
    // Verify both reads return the same value
    #expect(firstRead == secondRead)
    #expect(firstRead == "Cached Value")
    
    // Clean up
    await keychain.hardReset()
}

// MARK: - Subscript Tests (Using Deprecated API)

@Test
func testSubscriptBackwardCompatibility() {
    // This test ensures the deprecated subscript API still works
    let keychain = createTestKeychain()
    let key = "subscriptTest"
    
    // Use the subscript to store a value
    keychain[key] = "Subscript Value"
    
    // Use the subscript to retrieve the value
    let retrieved: String? = keychain[key]
    
    // Verify
    #expect(retrieved == "Subscript Value")
    
    // Delete using subscript (explicitly use the String subscript)
    keychain[key] = Optional<String>.none
    
    // Verify deletion - specify that we're checking the String subscript
    #expect((keychain[key] as String?) == nil)
    
    // Clean up using the synchronous wrapper
    Task { 
        await keychain.hardReset() 
    }
}
