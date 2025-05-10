# System Patterns: Keychain

## Architecture Overview

The Keychain package follows a layered architecture with clear separation of concerns:

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

## Design Patterns

### 1. Dependency Injection
The `Keychain` struct uses dependency injection to allow for flexible implementation and testing:
- Accepts handler functions in the initializer
- Delegates actual operations to injected handlers
- Enables mocking for testing purposes

### 2. Facade Pattern
The `Keychain` struct provides a simplified interface to the complex underlying Keychain Services API:
- Clean, straightforward methods hide implementation complexity
- Consistent error handling approach
- Type-safe interactions

### 3. Cache-Aside Pattern
The `KeychainEngine` uses a cache-aside pattern:
- Check cache first for requested data
- If not found, query the system Keychain
- Update cache with retrieved data
- Subsequent requests served from cache when possible

### 4. Thread Synchronization Pattern
Thread-safe wrapper class with NSLock to protect shared resources:
- Private ThreadSafeCache class to encapsulate locking logic
- Thread-safe dictionary access through controlled methods
- Prevents data races with concurrent reading/writing
- Uses NSLock with lock/unlock pattern

## Component Relationships

1. **External Client → Keychain**
   - Clients interact with the `Keychain` struct directly
   - Clean API with minimal complexity

2. **Keychain → KeychainEngine**
   - `KeychainEngine` is a concrete implementation that can be used with `Keychain`
   - Provides actual Keychain storage and caching functionality

3. **KeychainEngine → System Keychain**
   - Uses Security framework to interact with the system Keychain
   - Handles all low-level Keychain operations

## Data Flow

### Reading Data:
1. Client requests data for a key
2. Check in-memory cache
3. If found, return cached data
4. If not found, query system Keychain
5. Update cache with retrieved data
6. Return data to client

### Writing Data:
1. Client provides data and key
2. Update in-memory cache
3. Update system Keychain
4. Return success/failure to client
