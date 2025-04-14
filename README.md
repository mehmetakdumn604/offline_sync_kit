<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

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

### Key Architectural Components

The package is built around several key components:

1. **SyncModel**: The base class for all synchronizable data models, featuring standardized fields for tracking synchronization status, timestamps, and error handling
2. **OfflineSyncManager**: The main entry point for the package that orchestrates synchronization operations
3. **StorageService**: Manages local data persistence with transactional support
4. **SyncEngine**: Handles the core synchronization logic with configurable strategies
5. **NetworkClient**: Provides a flexible API client with a default HTTP implementation
6. **ConnectivityService**: Monitors network state and triggers appropriate actions

### Real-World Applications

This package is particularly valuable for:

- **Field Service Applications**: Where technicians need access to work orders and the ability to complete forms even in areas with poor connectivity
- **Healthcare Apps**: For collecting patient data that must be reliably synchronized with medical records systems
- **Sales & Inventory Systems**: To update stock levels and process orders regardless of network availability
- **Collaborative Tools**: That need to handle editing conflicts when multiple users modify the same data
- **Data Collection Apps**: That gather information in remote locations for later synchronization

## Features

- Offline data storage and synchronization
- Flexible and extensible structure
- Works with different data types
- Conflict management
- Automatic synchronization
- Internet connection monitoring
- Synchronization status tracking
- Exponential backoff for failed requests
- Delta synchronization for bandwidth efficiency
- Customizable synchronization policies

## Installation

To add the package to your project, add the following lines to your `pubspec.yaml` file:

```yaml
dependencies:
  offline_sync_kit: ^0.0.1
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'syncError': syncError,
      'syncAttempts': syncAttempts,
    };
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
    );
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isSynced: json['isSynced'] as bool? ?? false,
      syncError: json['syncError'] as String? ?? '',
      syncAttempts: json['syncAttempts'] as int? ?? 0,
    );
  }
}
```

### 2. Initializing the Synchronization Manager

Configure the `OfflineSyncManager` during your application initialization:

```dart
import 'package:offline_sync_kit/offline_sync_kit.dart';

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
  
  await OfflineSyncManager.initialize(
    baseUrl: baseUrl,
    storageService: storageService,
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

#### Updating Data

```dart
final updatedTodo = todo.copyWith(
  title: 'Updated title',
  isCompleted: true,
);

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

## Example App

To run the example app that comes with the package:

```bash
cd example
flutter run
```

## License

This package is distributed under the MIT license.
