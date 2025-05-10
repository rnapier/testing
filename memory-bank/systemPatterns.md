# System Patterns: Keychain

## Evolutionary Architecture

The Keychain package is designed to evolve through multiple architectural patterns to demonstrate different testing approaches. Each architecture represents a stage in the blog series, with its own tradeoffs and testing implications.

### Stage 1: Direct Implementation (Current)
A simple concrete implementation tested against the real keychain:

```
┌─────────────────────────────┐
│     Client Application      │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│      Keychain Class         │
│  (API + Implementation)     │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│    System Keychain Layer    │
└─────────────────────────────┘
```

**Testing Approach**: Direct testing against the real keychain
**Pros**: Tests real behavior, no abstraction overhead
**Cons**: Tests depend on system keychain, potential for flakiness

### Stage 2: Closure-Based Mocking (Planned)
Using a struct with injected closures for testing:

```
┌─────────────────────────────┐
│     Client Application      │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│      Keychain Struct        │
│     (API + Closures)        │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│ Default Closure Implementation │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│    System Keychain Layer    │
└─────────────────────────────┘
```

**Testing Approach**: Inject test closures that don't use real keychain
**Pros**: Isolated testing, flexible behavior control
**Cons**: Heavy code overhead, debugging challenges, potential for inconsistent behavior

### Stage 3: Protocol-Based Mocking (Planned)
Using protocols for abstraction and testing:

```
┌─────────────────────────────┐
│     Client Application      │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│     KeychainProtocol        │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│ Concrete Keychain Implementation │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│    System Keychain Layer    │
└─────────────────────────────┘
```

**Testing Approach**: Create mock implementations of the protocol
**Pros**: Clear interface, consistent behavior
**Cons**: Protocol overhead, potential for implementation drift

### Stage 4: Focused Extraction (Planned)
Extracting only the difficult-to-test code:

```
┌─────────────────────────────┐
│     Client Application      │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│      Keychain Class         │
│    (Business Logic)         │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│    KeychainStorage Class    │
│  (System Interaction Only)  │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│    System Keychain Layer    │
└─────────────────────────────┘
```

**Testing Approach**: Test business logic with real code, only mock the minimal KeychainStorage
**Pros**: Most code tested without mocks, minimal abstraction overhead
**Cons**: Still requires some isolation for the system interaction layer

## Design Patterns

### 1. Direct Implementation (Current)
The current implementation uses a single class approach:
- Combines API and implementation in one class
- Uses NSLock for thread safety
- Implements cache-aside pattern for performance
- Provides subscript-based access for different data types

### 2. Closure-Based Dependency Injection (Planned)
The planned closure-based implementation will:
- Accept handler functions in the initializer
- Delegate operations to injected closures
- Enable behavior customization for testing
- Demonstrate the overhead and challenges of this approach

### 3. Protocol-Based Abstraction (Planned)
The planned protocol-based implementation will:
- Define a protocol for keychain operations
- Create concrete and mock implementations
- Show the overhead of protocol-based abstraction
- Demonstrate potential for implementation drift

### 4. Focused Extraction (Planned)
The planned extraction-based implementation will:
- Isolate only the system interaction code
- Keep business logic in testable, non-mocked code
- Minimize abstraction overhead
- Demonstrate a balanced approach to testability

## Thread Safety Patterns

**Current Implementation**:
- Uses NSLock for direct protection of the dictionary state
- Manual lock/unlock pattern in methods
- Combined with concurrent dispatch queue with barriers for writes

**Future Implementations**:
Each implementation stage will maintain thread safety but may use different approaches to demonstrate various techniques and their testability.

## Data Flow

### Current Implementation - Reading Data:
1. Client requests data for a key (using method or subscript)
2. Operation runs on concurrent queue
3. Check in-memory cache (protected by NSLock)
4. If found, return cached data
5. If not found, query system Keychain
6. Update cache with retrieved data (protected by NSLock)
7. Return data to client

### Current Implementation - Writing Data:
1. Client provides data and key (using method or subscript)
2. Operation runs on concurrent queue with barrier for exclusive access
3. Update in-memory cache (protected by NSLock)
4. Try to update system Keychain
5. If key doesn't exist, create new Keychain item
6. Return success/failure to client

### Future Implementations:
Each implementation stage will maintain similar data flows but with different architectural approaches to demonstrate testing tradeoffs.
