# Offline Sync Kit

Offline Sync Kit is a comprehensive Flutter package designed to solve one of the most challenging aspects of mobile app development: reliable data synchronization between local device storage and remote APIs, especially in environments with intermittent connectivity.

## Overview

This package provides a robust framework for storing different types of data locally while automatically managing their synchronization with a remote server. Whether your users are filling out forms, creating chat messages, updating records, or changing settings, Offline Sync Kit ensures that their data remains accessible offline and properly synchronized when connectivity is restored.

### The Problem Solved

Many mobile applications need to function seamlessly regardless of network conditions. Users expect to continue using apps even when offline, and they expect their changes to persist and eventually synchronize with backend systems without data loss.

Traditional approaches to this problem often involve writing custom synchronization logic for each data type, managing complex conflict resolution, and monitoring network connectivity - all of which require significant development effort and are prone to subtle bugs.

Offline Sync Kit abstracts away these challenges by providing:

- A unified model for defining any type of synchronized data
- Automatic local storage with SQLite-based persistence
- Intelligent upload queuing and retry mechanisms
- Network state monitoring with appropriate action handling
- Configurable synchronization strategies with bidirectional sync capability
- Conflict detection and resolution mechanisms
- Optimized data transfer with delta synchronization
- Enhanced security with optional data encryption

### Key Architectural Components

The package is built around several key components:

1. **SyncModel**: The base class for all synchronizable data models, featuring standardized fields for tracking synchronization status, timestamps, and error handling
2. **OfflineSyncManager**: The main entry point for the package that orchestrates synchronization operations
3. **StorageService**: Manages local data persistence with transactional support
4. **SyncEngine**: Handles the core synchronization logic with configurable strategies
5. **NetworkClient**: Provides a flexible API client with a default HTTP implementation
6. **ConnectivityService**: Monitors network state and triggers appropriate actions
7. **ConflictResolutionHandler**: Manages different strategies for resolving data conflicts

## Features

- **Core Features**:
  - Offline data storage and synchronization
  - Flexible and extensible structure
  - Works with different data types
  - Automatic synchronization
  - Internet connection monitoring
  - Synchronization status tracking
  - Exponential backoff for failed requests
  - Customizable synchronization policies

- **Advanced Features**:
  - **Delta Synchronization**: Only sync changed fields to improve bandwidth efficiency
  - **Advanced Conflict Resolution**: Multiple strategies including server-wins, client-wins, last-update-wins, and custom handlers
  - **Optional Data Encryption**: Secure storage of sensitive information with configurable encryption keys
  - **Performance Optimizations**: Batched synchronization and prioritized sync queue management
  - **Extended Configuration Options**: Flexible sync intervals, batch size settings, and bidirectional sync controls
  - **Custom Repository Injection**: Ability to inject your own repository implementation without forking the package
  - **Model Factory Access**: Built-in access to registered model factories
  - **Flexible Bidirectional Sync**: Enhanced support for fetching and pulling data from the server
  - **Robust Error Handling**: Improved handling of unexpected API responses

## Installation

To add the package to your project, add the following lines to your `pubspec.yaml` file:

```yaml
dependencies:
  offline_sync_kit: ^1.2.0
```

## Usage

### 1. Creating a Data Model

First, derive your synchronizable data model from the `SyncModel` class:

```dart
import 'package:offline_sync_kit/offline_sync_kit.dart';

class Todo extends SyncModel {
  final String title;
  final String description;
  final bool isCompleted;
  final int priority;
  
  // Track changed fields for delta sync
  final Set<String> changedFields;

  Todo({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.isSynced,
    super.syncError,
    super.syncAttempts,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 1,
    this.changedFields = const {},
  });

  @override
  String get endpoint => 'todos';

  @override
  String get modelType => 'todo';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'syncError': syncError,
      'syncAttempts': syncAttempts,
      'changedFields': changedFields.toList(),
    };
  }
  
  // Support for delta synchronization
  Map<String, dynamic> toJsonDelta() {
    final Map<String, dynamic> delta = {'id': id};
    
    if (changedFields.contains('title')) delta['title'] = title;
    if (changedFields.contains('description')) delta['description'] = description;
    if (changedFields.contains('isCompleted')) delta['isCompleted'] = isCompleted;
    if (changedFields.contains('priority')) delta['priority'] = priority;
    
    return delta;
  }

  @override
  Todo copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? syncError,
    int? syncAttempts,
    String? title,
    String? description,
    bool? isCompleted,
    int? priority,
    Set<String>? changedFields,
  }) {
    return Todo(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncError: syncError ?? this.syncError,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      changedFields: changedFields ?? this.changedFields,
    );
  }
  
  // Helper methods for updating fields
  Todo updateTitle(String newTitle) {
    final updatedFields = Set<String>.from(changedFields)..add('title');
    return copyWith(title: newTitle, changedFields: updatedFields);
  }
  
  Todo updateDescription(String newDescription) {
    final updatedFields = Set<String>.from(changedFields)..add('description');
    return copyWith(description: newDescription, changedFields: updatedFields);
  }
  
  Todo updateCompletionStatus(bool completed) {
    final updatedFields = Set<String>.from(changedFields)..add('isCompleted');
    return copyWith(isCompleted: completed, changedFields: updatedFields);
  }
  
  Todo updatePriority(int newPriority) {
    final updatedFields = Set<String>.from(changedFields)..add('priority');
    return copyWith(priority: newPriority, changedFields: updatedFields);
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    final changedFieldsList = json['changedFields'] as List<dynamic>?;
    final changedFields = changedFieldsList != null 
        ? Set<String>.from(changedFieldsList.map((e) => e as String))
        : <String>{};
        
    return Todo(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: json['priority'] as int? ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isSynced: json['isSynced'] as bool? ?? false,
      syncError: json['syncError'] as String? ?? '',
      syncAttempts: json['syncAttempts'] as int? ?? 0,
      changedFields: changedFields,
    );
  }
}
```

### 2. Initializing the Synchronization Manager

Configure the `OfflineSyncManager` during your application initialization with advanced options:

```dart
import 'package:offline_sync_kit/offline_sync_kit.dart';
import 'package:offline_sync_kit/src/models/conflict_resolution_strategy.dart';

Future<void> initSyncManager() async {
  // Specify your API base URL here
  const baseUrl = 'https://api.example.com';
  
  final storageService = StorageServiceImpl();
  await storageService.initialize();
  
  // Register model factory
  (storageService as StorageServiceImpl).registerModelDeserializer<Todo>(
    'todo',
    (json) => Todo.fromJson(json),
  );
  
  // Advanced configuration options
  final syncOptions = SyncOptions(
    syncInterval: const Duration(minutes: 5),
    useDeltaSync: true,
    conflictStrategy: ConflictResolutionStrategy.lastUpdateWins,
    batchSize: 10,
    autoSync: true,
    bidirectionalSync: true,
  );
  
  // Optional: Provide a custom repository implementation
  final customRepository = MyCustomRepository(
    networkClient: myNetworkClient,
    storageService: storageService,
  );
  
  // Enable encryption with a secure key
  final encryptionEnabled = true;
  final encryptionKey = 'your-secure-encryption-key';
  
  await OfflineSyncManager.initialize(
    baseUrl: baseUrl,
    storageService: storageService,
    syncOptions: syncOptions,
    encryptionEnabled: encryptionEnabled,
    encryptionKey: encryptionKey,
    customRepository: customRepository, // Optional
  );
  
  // Register TodoModel with OfflineSyncManager
  OfflineSyncManager.instance.registerModelFactory<Todo>(
    'todo',
    (json) => Todo.fromJson(json),
  );
}
```

### 3. Managing Data

#### Adding Data

```dart
final newTodo = Todo(
  title: 'New task',
  description: 'This is an example task',
);

await OfflineSyncManager.instance.saveModel<Todo>(newTodo);
```

#### Updating Data with Delta Synchronization

```dart
// Only the title will be synchronized with the server
final updatedTodo = todo.updateTitle('Updated title');

// Only the completion status will be synchronized with the server
final completedTodo = todo.updateCompletionStatus(true);

await OfflineSyncManager.instance.updateModel<Todo>(updatedTodo);
```

#### Deleting Data

```dart
await OfflineSyncManager.instance.deleteModel<Todo>(todo.id, 'todo');
```

#### Retrieving Data

```dart
// Get a single item
final todo = await OfflineSyncManager.instance.getModel<Todo>(id, 'todo');

// Get all items
final todos = await OfflineSyncManager.instance.getAllModels<Todo>('todo');
```

#### Fetching Data from Server

```dart
// Fetch items with pagination
final todos = await OfflineSyncManager.instance.fetchItems<Todo>(
  'todo',
  limit: 20, 
  offset: 0,
  since: lastSyncTime,
);

// Pull and synchronize with local storage
final result = await OfflineSyncManager.instance.pullFromServer<Todo>('todo');
```

### 4. Synchronization

#### Manual Synchronization

```dart
// Synchronize all data
await OfflineSyncManager.instance.syncAll();

// Synchronize a specific model type
await OfflineSyncManager.instance.syncByModelType('todo');
```

#### Automatic Synchronization

```dart
// Start periodic synchronization
await OfflineSyncManager.instance.startPeriodicSync();

// Stop periodic synchronization
await OfflineSyncManager.instance.stopPeriodicSync();
```

### 5. Monitoring Synchronization Status

```dart
// Listen to synchronization status
OfflineSyncManager.instance.syncStatusStream.listen((status) {
  print('Connection status: ${status.isConnected}');
  print('Synchronization process: ${status.isSyncing}');
  print('Pending changes: ${status.pendingChanges}');
  print('Last synchronization time: ${status.lastSyncTime}');
});

// Get current status
final status = await OfflineSyncManager.instance.currentStatus;
```

### 6. Handling Conflicts

```dart
// Set up a custom conflict handler
final customConflictResolver = (SyncConflict conflict) {
  // Custom logic to resolve conflicts
  if (conflict.localVersion.updatedAt.isAfter(conflict.serverVersion.updatedAt)) {
    return conflict.localVersion; // Local changes win
  } else {
    return conflict.serverVersion; // Server changes win
  }
};

// Configure with custom conflict resolution
final syncOptions = SyncOptions(
  conflictStrategy: ConflictResolutionStrategy.custom,
  conflictResolver: customConflictResolver,
);

OfflineSyncManager.instance.updateSyncOptions(syncOptions);
```

### 7. Managing Encryption

```dart
// Enable encryption
await OfflineSyncManager.instance.enableEncryption('secure-encryption-key');

// Disable encryption (data will be decrypted)
await OfflineSyncManager.instance.disableEncryption();

// Check encryption status
final isEncrypted = OfflineSyncManager.instance.isEncryptionEnabled;
```

### 8. Custom Repository Implementation

```dart
// Create a custom repository implementation
class MyCustomRepository implements SyncRepository {
  final NetworkClient networkClient;
  final StorageService storageService;
  
  MyCustomRepository({
    required this.networkClient,
    required this.storageService,
  });
  
  // Implement required methods
  
  // Custom implementation for fetchItems with special handling for your API
  @override
  Future<List<T>> fetchItems<T extends SyncModel>(
    String modelType, {
    DateTime? since,
    int? limit,
    int? offset,
    Map<String, dynamic Function(Map<String, dynamic>)>? modelFactories,
  }) async {
    // Your custom implementation...
  }
}
```

## Example App

To run the example app that comes with the package:

```bash
cd example
flutter run
```

## License

This package is distributed under the MIT license.
