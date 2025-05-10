import Testing
import Foundation
@testable import Keychain

// MARK: - Test Helpers

/// Creates a test keychain with a unique ID to avoid interfering with real data
func createTestKeychain() -> Keychain {
    let uuid = UUID().uuidString
    return Keychain(
        keychainID: "com.test.keychain.\(uuid)"
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
    await keychain.reset()
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
    await keychain.reset()
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
    await keychain.reset()
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
    await keychain.reset()
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
    await keychain.reset()
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
    await keychain.reset()
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
    await keychain.reset()
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
    await keychain.reset()
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
    await keychain.reset()
}

// MARK: - Reset Functionality Tests

@Test
func testReset() async {
    let keychain = createTestKeychain()
    let key = "testKey"
    
    // Store a value
    await keychain.set(string: "Test Value", for: key)
    
    // Verify it was stored
    #expect(await keychain.string(for: key) == "Test Value")
    
    // Reset the keychain
    await keychain.reset()
    
    // Verify the key was deleted
    #expect(await keychain.string(for: key) == nil)
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
    await keychain.reset()
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
    await keychain.reset()
}
