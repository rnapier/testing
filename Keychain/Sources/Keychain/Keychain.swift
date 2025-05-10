import Foundation

public struct Keychain: Sendable {
    
    init(
        dataForKey: @escaping @Sendable (_ key: String) -> Data?,
        stringForKey: @escaping @Sendable (_ key: String) -> String?,
        boolForKey: @escaping @Sendable (_ key: String) -> Bool?,
        setDataForKey: @escaping @Sendable (_ value: Data?, _ key: String) -> Void,
        setStringForKey: @escaping @Sendable (_ value: String?, _ key: String) -> Void,
        setBoolForKey: @escaping @Sendable (_ value: Bool?, _ key: String) -> Void,
        resetMethod: @escaping @Sendable () -> Void,
        hardResetMethod: @escaping @Sendable () -> Void
    ) {
        self.dataForKey = dataForKey
        self.stringForKey = stringForKey
        self.boolForKey = boolForKey
        self.setDataForKey = setDataForKey
        self.setStringForKey = setStringForKey
        self.setBoolForKey = setBoolForKey
        self.resetMethod = resetMethod
        self.hardResetMethod = hardResetMethod
    }

    init(_ keychain: some KeychainEngine) {
        self.dataForKey = keychain.data(for:)
        self.stringForKey = keychain.string(for:)
        self.boolForKey = keychain.bool(for:)
        self.setDataForKey = keychain.set(data:for:)
        self.setStringForKey = keychain.set(string:for:)
        self.setBoolForKey = keychain.set(bool:for:)
        self.resetMethod = keychain.reset
        self.hardResetMethod = keychain.hardReset
    }

    /// Creating a Keychain with the internal implementation. The underlying mechanisms will rely upon a concurrent queue with write barriers and an in-memory cache to speed up reads but ensure that writes are processed similar to a serial queue and lock any in-parallel reads until the write is complete. Ensuring the flow of data behaves as expected.
    ///
    /// - Parameters:
    ///   - keychainID: Identifier of the Keychain
    ///   - queueLabel: Identifier for the internal Queue
    ///   - persistingKeys: A series of Keys that should persist a keychain reset. Empty by default
    public init(keychainID: String, persistingKeys: [String] = []) {
        self.init(
            _Keychain(
                keychainID: keychainID,
                persistingKeys: persistingKeys
            )
        )
    }

    private var dataForKey: @Sendable (_ key: String) -> Data?
    private var stringForKey: @Sendable (_ key: String) -> String?
    private var boolForKey: @Sendable  (_ key: String) -> Bool?
    private var setDataForKey: @Sendable (_ value: Data?, _ key: String) -> Void
    private var setStringForKey: @Sendable (_ value: String?, _ key: String) -> Void
    private var setBoolForKey: @Sendable (_ value: Bool?, _ key: String) -> Void
    private var resetMethod: @Sendable () -> Void
    private var hardResetMethod: @Sendable () -> Void

    public func data(for key: String) -> Data? {
        dataForKey(key)
    }

    public func string(for key: String) -> String? {
        stringForKey(key)
    }
    
    public func bool(for key: String) -> Bool? {
        boolForKey(key)
    }

    public func set(data: Data?, for key: String) {
        setDataForKey(data, key)
    }

    public func set(string: String?, for key: String) {
        setStringForKey(string, key)
    }
    
    public func set(bool: Bool?, for key: String) {
        setBoolForKey(bool, key)
    }

    // or could utilize subscripts
    public subscript(key: String) -> String? {
        get { string(for: key) }
        set { set(string: newValue, for: key) }
    }
    public subscript(key: String) -> Data? {
        get { data(for: key) }
        set { set(data: newValue, for: key) }
    }
    public subscript(key: String) -> Bool? {
        get { bool(for: key) }
        set { set(bool: newValue, for: key) }
    }

    public func reset() {
        resetMethod()
    }

    public func hardReset() {
        hardResetMethod()
    }

    public func remove(key: String) {
        set(data: nil, for: key)
    }
}

public protocol KeychainEngine: Sendable {
    @Sendable func data(for key: String) -> Data?
    @Sendable func string(for key: String) -> String?
    @Sendable func bool(for key: String) -> Bool?
    @Sendable func set(data: Data?, for key: String)
    @Sendable func set(string: String?, for key: String)
    @Sendable func set(bool: Bool?, for key: String)
    
    /// Resets the keychain.
    ///
    /// This method removes all keys and values from the keychain except for ABHardwareIdentifier, ABDeviceIdentifier and ABDeviceActivationDataIdentifier, which are never intended to be changed.
    @Sendable func reset()

    /// This method removes all keys and values from the keychain! Including ABHardwareIdentifier, ABDeviceIdentifier and ABDeviceActivationDataIdentifier, which are never intended to be changed. Please be careful when using... this is probably not the reset you're looking for. 
    @Sendable func hardReset()
}

extension KeychainEngine {
    func eraseToKeychain() -> Keychain {
        Keychain(self)
    }
}
