# Technical Context: Keychain

## Technologies Used

### Core Technologies
- **Swift**: Primary programming language (Swift 6.1)
- **Swift Package Manager**: Dependency management and project structure
- **Keychain Services API**: Apple's secure storage mechanism
- **Synchronization Mechanisms**: For thread safety (NSLock currently)
- **Testing Framework**: Swift Testing framework

### Frameworks & Libraries
- **Foundation**: Core functionality and data types
- **Security**: For Keychain Services API access (CFDictionary, SecItemXXX methods)
- **Dispatch**: For concurrent queue with barriers in current implementation
- **Testing**: Swift Testing framework for unit tests

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

### Future Project Structures
As the project evolves through different testing approaches, the structure will change to demonstrate various architectural patterns:

#### Stage 2: Closure-Based Mocking
```
Keychain/
├── Package.swift
├── Sources/
│   └── Keychain/
│       └── Keychain.swift    # Struct with closure-based dependency injection
└── Tests/
    └── KeychainTests/
        ├── KeychainTests.swift
        └── MockClosures.swift  # Test closures
```

#### Stage 3: Protocol-Based Mocking
```
Keychain/
├── Package.swift
├── Sources/
│   └── Keychain/
│       ├── KeychainProtocol.swift  # Protocol definition
│       └── Keychain.swift          # Concrete implementation
└── Tests/
    └── KeychainTests/
        ├── KeychainTests.swift
        └── MockKeychain.swift      # Mock implementation
```

#### Stage 4: Focused Extraction
```
Keychain/
├── Package.swift
├── Sources/
│   └── Keychain/
│       ├── Keychain.swift          # Business logic
│       └── KeychainStorage.swift   # System interaction only
└── Tests/
    └── KeychainTests/
        ├── KeychainTests.swift
        └── MockKeychainStorage.swift  # Minimal mock
```

### Build Requirements
- Swift 6.1+
- iOS 18.0+, macOS 15.0+, tvOS 18.0+, watchOS 11.0+

## Technical Constraints

### Testing Constraints
- **Educational Focus**: Code must clearly demonstrate testing concepts
- **Evolution**: Architecture will change multiple times to showcase different approaches
- **Clarity**: Each implementation must clearly illustrate its testing tradeoffs

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
- Testing.framework (Swift Testing framework)

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

### Direct Keychain Services API Usage
- Using the C API directly rather than higher-level abstractions to:
  - Maintain complete control over operations
  - Avoid additional dependencies
  - Ensure optimal performance

### Reset Methods
- Both `reset()` and `hardReset()` methods are implemented
- `reset()` preserves specified "persisting keys" during reset
- `hardReset()` clears all data without preserving anything

### Testing Approach
**Current (Stage 1)**:
- Direct testing against the real keychain
- Tests create a unique keychain ID to avoid interfering with real data
- Each test cleans up after itself with hardReset()

**Future Stages**:
- Will demonstrate different testing approaches with their respective tradeoffs
- Each approach will be clearly documented to highlight its educational value
