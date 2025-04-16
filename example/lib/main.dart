import 'package:flutter/material.dart';
import 'package:offline_sync_kit/offline_sync_kit.dart';
import 'models/todo.dart';
import 'models/encryption_manager.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize encryption manager
  await EncryptionManager().initialize();

  // Initialize sync manager
  await initSyncManager();

  runApp(const MyApp());
}

Future<void> initSyncManager() async {
  // Put your API address here in a real application
  const baseUrl = 'https://jsonplaceholder.typicode.com';

  final storageService = StorageServiceImpl();
  await storageService.initialize();

  // Register model factory
  (storageService).registerModelDeserializer<Todo>(
    'todo',
    (json) => Todo.fromJson(json),
  );

  // Enhanced security and performance options with SyncOptions
  final syncOptions = SyncOptions(
    syncInterval: const Duration(minutes: 15),
    useDeltaSync: true, // Enable delta synchronization
    conflictStrategy: ConflictResolutionStrategy.lastUpdateWins,
    batchSize: 20, // Higher value for batch operations
    autoSync: true,
    bidirectionalSync: true,
  );

  // Get encryption status from the manager
  final encryptionManager = EncryptionManager();
  final isEncryptionEnabled = encryptionManager.isEncryptionEnabled;

  // Initialize sync manager with optional encryption
  await OfflineSyncManager.initialize(
    baseUrl: baseUrl,
    storageService: storageService,
    syncOptions: syncOptions,
    enableEncryption: isEncryptionEnabled, // Use value from EncryptionManager
    encryptionKey:
        isEncryptionEnabled
            ? 'secure-key-here'
            : null, // Only provide key if enabled
  );

  // Register Todo model with OfflineSyncManager
  OfflineSyncManager.instance.registerModelFactory<Todo>(
    'todo',
    (json) => Todo.fromJson(json),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Sync Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
