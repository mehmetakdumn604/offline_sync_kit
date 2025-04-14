import 'package:flutter/material.dart';
import 'package:offline_sync_kit/offline_sync_kit.dart';
import 'models/todo.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSyncManager();

  runApp(const MyApp());
}

Future<void> initSyncManager() async {
  // Put your API address here in a real application
  const baseUrl = 'https://jsonplaceholder.typicode.com';

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
