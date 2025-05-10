# Technical Context: Keychain

## Technologies Used

### Core Technologies
- **Swift**: Primary programming language (Swift 6.1)
- **Swift Package Manager**: Dependency management and project structure
- **Keychain Services API**: Apple's secure storage mechanism
- **Synchronization Mechanisms**: For thread safety (NSLock currently, Mutex planned)

### Frameworks & Libraries
- **Foundation**: Core functionality and data types
- **Security**: For Keychain Services API access (CFDictionary, SecItemXXX methods)
- **Dispatch**: For concurrent queue with barriers in current implementation
- **Synchronization**: For Mutex in planned implementation

## Development Setup

### Current Project Structure
```
Keychain/
├── Package.swift             # Package definition with platform requirements
├── Sources/
│   └── Keychain/             # Main module
│       └── Keychain.swift    # Combined API interface + implementation class
└── Tests/
    └── KeychainTests/        # Test cases
        └── KeychainTests.swift
```

### Planned Project Structure
```
Keychain/
├── Package.swift             # Package definition
├── Sources/
│   └── Keychain/             # Main module
│       ├── Keychain.swift    # API interface struct
│       └── KeychainEngine.swift # Implementation class
└── Tests/
    └── KeychainTests/        # Test cases
        └── KeychainTests.swift
```

### Build Requirements
- Swift 6.1+
- iOS 18.0+, macOS 15.0+, tvOS 18.0+, watchOS 11.0+
- These higher minimum versions are required for Mutex support

## Technical Constraints

### Platform Constraints
- Limited to Apple platforms that support Keychain Services
- Must be compatible with Swift concurrency model
- Must respect memory limitations on all targeted platforms

### Security Constraints
- No sensitive data should be logged (current implementation has some print statements for errors)
- Cached data lives only in memory, not persisted outside Keychain
- Implementation must follow Apple's security best practices
- Persisting keys mechanism allows certain critical values to survive reset operations

## Dependencies

### External Dependencies
- None (self-contained package)

### System Dependencies
- Security.framework (Keychain Services)
- Foundation.framework (NSLock, DispatchQueue)
- Synchronization.framework (Mutex for planned implementation)

## Technical Decisions

### Dictionary-based In-Memory Cache
- Provides O(1) lookup time for cached values
- Simple to implement and maintain
- Efficient for typical use cases with string keys

### Thread Safety Implementation
**Current**:
- NSLock for protecting the dictionary state
- Concurrent dispatch queue with barriers for write operations
- Manual lock/unlock pattern requiring careful paired usage

**Planned**:
- `Mutex` for:
  - Direct protection of the dictionary state  
  - Modern Swift API design with `.withLock` pattern
  - Thread-safe access with improved ergonomics
  - Strong type safety through generic parameter

### Direct Keychain Services API Usage
- Using the C API directly rather than higher-level abstractions to:
  - Maintain complete control over operations
  - Avoid additional dependencies
  - Ensure optimal performance

### Reset Methods
**Current**:
- Both `reset()` and `hardReset()` methods are implemented
- `reset()` preserves specified "persisting keys" during reset
- `hardReset()` clears all data without preserving anything

**Planned**:
- Original plan was to omit these methods from the `KeychainEngine` class
- May need to reconsider based on existing implementation providing this functionality
