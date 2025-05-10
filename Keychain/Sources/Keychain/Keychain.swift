import Foundation

public struct Keychain: Sendable {
    private var dataForKeyMethod: @Sendable (String) -> Data?
    private var setDataForKeyMethod: @Sendable (Data?, String) -> Void
    private var resetMethod: @Sendable () -> Void
    private var hardResetMethod: @Sendable () -> Void

    public init(
        dataForKey: @escaping @Sendable (String) -> Data,
        setDataForKey: @escaping @Sendable (Data?, String) -> Void,
        reset: @escaping @Sendable () -> Void,
        hardReset: @escaping @Sendable () -> Void
    ) {
        self.dataForKeyMethod = dataForKey
        self.setDataForKeyMethod = setDataForKey
        self.resetMethod = reset
        self.hardResetMethod = hardReset
    }

    public func data(forKey key: String) -> Data? {
        dataForKeyMethod(key)
    }

    public func set(_ data: Data?, forKey key: String) {
        setDataForKeyMethod(data, key)
    }

    public func removeData(forKey key: String) {
        setDataForKeyMethod(nil, key)
    }

    public func reset() {
        resetMethod()
    }

    public func hardReset() {
        hardResetMethod()
    }
}
