# Offline Sync Kit - Example App

This example app demonstrates the powerful features and usage of the Offline Sync Kit package. 

## Demonstrated Features

### 1. Delta Synchronization

Delta synchronization saves bandwidth by only sending fields that have changed to the server.

```dart
// Todo model tracks changed fields
todo = todo.updateTitle("New title");  // Only the title field is modified
await OfflineSyncManager.instance.syncItemDelta(todo);  // Only sends changed field
```

### 2. Data Encryption (Optional)

End-to-end encryption support has been added to secure sensitive data.

```dart
// Enable encryption when initializing the app
await OfflineSyncManager.initialize(
  baseUrl: 'https://api.example.com',
  storageService: myStorage,
  enableEncryption: true,
  encryptionKey: 'secure-key',
);
```

### 3. Conflict Resolution Strategies

Various strategies for resolving conflicts when the same data is updated in different environments:

- Server Wins: Server version always takes precedence
- Client Wins: Client version always takes precedence
- Last Update Wins: Most recently updated version takes precedence
- Custom: Custom resolution strategy

### 4. Offline Data Management

Full offline mode that allows the app to function even without an internet connection:

- Offline data addition
- Offline updates
- Automatic synchronization when connection is restored
- Synchronization status tracking

### 5. User Interface Enhancements

- Status bar showing synchronization state
- Conflict strategy selector
- Delta synchronization toggle
- Synchronization status indicator for each item

## Usage

1. Start the application
2. Click the "+" button in the bottom right corner to add a Todo
3. Click on a Todo to view and edit its details
4. Use the toggle to enable/disable delta synchronization
5. Click the settings icon to change the conflict resolution strategy
6. Check the top bar for synchronization status information
7. Use the sync button for manual synchronization

## Recommended Test Scenarios

1. **Delta Synchronization Test**: Add a Todo and change just one field, observe that only that field is synchronized
2. **Offline Mode Test**: Turn on airplane mode, add several Todos, then turn off airplane mode and observe automatic synchronization
3. **Conflict Resolution Test**: Test different conflict resolution strategies to observe behavioral differences

This example app is designed to showcase the use of Offline Sync Kit in real-world scenarios. You can easily implement similar functionality in your own projects using this package.
