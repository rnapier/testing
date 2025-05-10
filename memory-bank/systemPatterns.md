# System Patterns: Keychain

## Architecture Overview

### Planned Architecture
The Keychain package is designed to follow a layered architecture with clear separation of concerns:

```
┌─────────────────────────────┐
│     Client Application      │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│     Keychain API Layer      │
│   (Keychain struct - API)   │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│   Implementation Layer      │
│ (KeychainEngine - concrete) │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│    System Keychain Layer    │
└─────────────────────────────┘
```

### Current Implementation
The current implementation uses a different architecture with a single class handling both API and implementation:

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

## Design Patterns

### 1. Dependency Injection (Planned)
The planned `Keychain` struct will use dependency injection:
- Accept handler functions in the initializer
- Delegate actual operations to injected handlers
- Enable mocking for testing purposes

### 2. Facade Pattern
Both planned and current implementations provide a simplified interface to the complex underlying Keychain Services API:
- Clean, straightforward methods hide implementation complexity
- Consistent error handling approach
- Type-safe interactions

### 3. Cache-Aside Pattern
Both planned and current implementations use a cache-aside pattern:
- Check cache first for requested data
- If not found, query the system Keychain
- Update cache with retrieved data
- Subsequent requests served from cache when possible

### 4. Thread Synchronization Patterns
**Current Implementation**:
- Uses NSLock for direct protection of the dictionary state
- Manual lock/unlock pattern in methods
- Combined with concurrent dispatch queue with barriers for writes

**Planned Implementation**:
- Use Mutex with `.withLock` pattern for thread-safe access
- Modern Swift API design with better ergonomics
- Strong type safety through generic parameter

## Component Relationships

### Planned Architecture

1. **External Client → Keychain Struct**
   - Clients interact with the `Keychain` struct directly
   - Clean API with minimal complexity

2. **Keychain Struct → KeychainEngine**
   - `KeychainEngine` is a concrete implementation that can be used with `Keychain`
   - Provides actual Keychain storage and caching functionality

3. **KeychainEngine → System Keychain**
   - Uses Security framework to interact with the system Keychain
   - Handles all low-level Keychain operations

### Current Implementation

1. **External Client → Keychain Class**
   - Clients interact with the `Keychain` class directly
   - API includes subscripts for different data types and reset methods

2. **Keychain Class → System Keychain**
   - Class directly uses Security framework to interact with the system Keychain
   - Handles both high-level API and low-level operations

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

### Planned Implementation - Data Flow:
The planned implementation will maintain similar flows but with clearer separation between the API layer and implementation details.
