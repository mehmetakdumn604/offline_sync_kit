import 'package:flutter/material.dart';
import 'package:offline_sync_kit/offline_sync_kit.dart';
import '../models/todo.dart';
import 'todo_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Todo> _todos = [];
  SyncStatus _syncStatus = SyncStatus(
    isConnected: false,
    isSyncing: false,
    pendingChanges: 0,
  );
  late final Stream<SyncStatus> _statusStream;

  @override
  void initState() {
    super.initState();
    _statusStream = OfflineSyncManager.instance.syncStatusStream;
    _loadTodos();
    _listenToSyncStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTodos();
    });
  }

  void _listenToSyncStatus() {
    _statusStream.listen((status) {
      setState(() {
        _syncStatus = status;
      });
    });
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await OfflineSyncManager.instance.getAllModels<Todo>(
        'todo',
      );
      final status = await OfflineSyncManager.instance.currentStatus;

      setState(() {
        _todos.clear();
        _todos.addAll(todos);
        _syncStatus = status;
      });
    } catch (e) {
      debugPrint('Error loading todos: $e');
    }
  }

  Future<void> _syncTodos() async {
    try {
      setState(() {
        _syncStatus = _syncStatus.copyWith(isSyncing: true);
      });

      final result = await OfflineSyncManager.instance.syncByModelType('todo');
      debugPrint('Sync result: ${result.status}');

      final todos = await OfflineSyncManager.instance.getAllModels<Todo>(
        'todo',
      );
      final status = await OfflineSyncManager.instance.currentStatus;

      setState(() {
        _todos.clear();
        _todos.addAll(todos);
        _syncStatus = status;
      });
    } catch (e) {
      debugPrint('Error syncing todos: $e');
      setState(() {
        _syncStatus = _syncStatus.copyWith(isSyncing: false);
      });
    }
  }

  Future<void> _addTodo() async {
    final newTodo = Todo(
      title: 'New Todo ${_todos.length + 1}',
      description: 'Sample description for the new todo item',
    );

    try {
      setState(() {
        _todos.add(newTodo);
        _syncStatus = _syncStatus.copyWith(
          pendingChanges: _syncStatus.pendingChanges + 1,
          isSyncing: true,
        );
      });

      await OfflineSyncManager.instance.saveModel<Todo>(newTodo);
      await OfflineSyncManager.instance.syncByModelType('todo');

      final todos = await OfflineSyncManager.instance.getAllModels<Todo>(
        'todo',
      );
      final status = await OfflineSyncManager.instance.currentStatus;

      setState(() {
        _todos.clear();
        _todos.addAll(todos);
        _syncStatus = status;
      });
    } catch (e) {
      debugPrint('Error adding todo: $e');
      setState(() {
        _syncStatus = _syncStatus.copyWith(isSyncing: false);
      });
    }
  }

  void _navigateToDetail(Todo todo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TodoDetailScreen(todo: todo)),
    ).then((_) async {
      await _syncTodos();
      await _loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Demo'),
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: _syncTodos),
        ],
      ),
      body: Column(
        children: [
          _buildSyncStatusBar(),
          Expanded(
            child:
                _todos.isEmpty
                    ? const Center(child: Text('No todos yet. Add one!'))
                    : ListView.builder(
                      itemCount: _todos.length,
                      itemBuilder: (context, index) {
                        final todo = _todos[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                todo.isSynced ? Colors.green : Colors.orange,
                            child: Icon(
                              todo.isCompleted
                                  ? Icons.check
                                  : Icons.access_time,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(todo.title),
                          subtitle: Text(todo.description),
                          trailing: Text('Priority: ${todo.priority}'),
                          onTap: () => _navigateToDetail(todo),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSyncStatusBar() {
    return Container(
      color: _getSyncStatusColor(),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          Icon(_getSyncStatusIcon(), color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getSyncStatusText(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (_syncStatus.pendingChanges > 0)
            Badge(label: Text('${_syncStatus.pendingChanges}')),
        ],
      ),
    );
  }

  Color _getSyncStatusColor() {
    if (!_syncStatus.isConnected) {
      return Colors.grey.shade700;
    }
    if (_syncStatus.isSyncing) {
      return Colors.blue;
    }
    if (_syncStatus.pendingChanges > 0) {
      return Colors.orange;
    }
    return Colors.green;
  }

  IconData _getSyncStatusIcon() {
    if (!_syncStatus.isConnected) {
      return Icons.signal_wifi_off;
    }
    if (_syncStatus.isSyncing) {
      return Icons.sync;
    }
    if (_syncStatus.pendingChanges > 0) {
      return Icons.sync_problem;
    }
    return Icons.check_circle;
  }

  String _getSyncStatusText() {
    if (!_syncStatus.isConnected) {
      return 'Offline mode - changes will be synced when connection is restored';
    }
    if (_syncStatus.isSyncing) {
      return 'Syncing data...';
    }
    if (_syncStatus.pendingChanges > 0) {
      return '${_syncStatus.pendingChanges} changes pending synchronization';
    }
    return 'All changes synchronized';
  }
}
