import 'package:flutter/material.dart';
import 'package:offline_sync_kit/offline_sync_kit.dart';
import '../models/todo.dart';

class TodoDetailScreen extends StatefulWidget {
  final Todo todo;

  const TodoDetailScreen({super.key, required this.todo});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isCompleted;
  late int _priority;
  late Todo _currentTodo;
  bool _useDeltaSync = true; // Delta sync enabled by default

  @override
  void initState() {
    super.initState();
    _currentTodo = widget.todo;
    _titleController = TextEditingController(text: _currentTodo.title);
    _descriptionController = TextEditingController(
      text: _currentTodo.description,
    );
    _isCompleted = _currentTodo.isCompleted;
    _priority = _currentTodo.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTodo() async {
    try {
      if (_useDeltaSync) {
        // Update only changed fields using delta sync
        Todo updatedTodo = _currentTodo;

        // Only update fields that have changed
        if (_titleController.text != _currentTodo.title) {
          updatedTodo = updatedTodo.updateTitle(_titleController.text);
        }

        if (_descriptionController.text != _currentTodo.description) {
          updatedTodo = updatedTodo.updateDescription(
            _descriptionController.text,
          );
        }

        if (_isCompleted != _currentTodo.isCompleted) {
          updatedTodo = updatedTodo.updateCompletionStatus(_isCompleted);
        }

        if (_priority != _currentTodo.priority) {
          updatedTodo = updatedTodo.updatePriority(_priority);
        }

        if (updatedTodo.hasChanges) {
          // Save only changed fields
          await OfflineSyncManager.instance.updateModel<Todo>(updatedTodo);

          // Sync using delta sync
          await OfflineSyncManager.instance.syncItemDelta<Todo>(updatedTodo);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changed fields saved (Delta)')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No fields changed')));
        }
      } else {
        // Update the entire model - standard method
        final updatedTodo = _currentTodo.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          isCompleted: _isCompleted,
          priority: _priority,
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        await OfflineSyncManager.instance.updateModel<Todo>(updatedTodo);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Todo saved')));
      }

      // Pull latest data from server
      await OfflineSyncManager.instance.pullFromServer<Todo>('todo');

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating todo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteTodo() async {
    try {
      await OfflineSyncManager.instance.deleteModel<Todo>(
        _currentTodo.id,
        _currentTodo.modelType,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error deleting todo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Status: '),
                Switch(
                  value: _isCompleted,
                  onChanged: (value) {
                    setState(() {
                      _isCompleted = value;
                    });
                  },
                ),
                Text(_isCompleted ? 'Completed' : 'Pending'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Priority: '),
                Slider(
                  value: _priority.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _priority.toString(),
                  onChanged: (value) {
                    setState(() {
                      _priority = value.toInt();
                    });
                  },
                ),
                Text(_priority.toString()),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Delta Synchronization'),
              subtitle: const Text('Only send changed fields (faster)'),
              value: _useDeltaSync,
              onChanged: (value) {
                setState(() {
                  _useDeltaSync = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSyncStatus(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTodo,
        tooltip: 'Save',
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildSyncStatus() {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Synchronization Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _currentTodo.isSynced
                      ? Icons.check_circle
                      : Icons.sync_problem,
                  color: _currentTodo.isSynced ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentTodo.isSynced ? 'Synced' : 'Not Synced',
                  style: textStyle,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${_formatDate(_currentTodo.createdAt)}',
              style: textStyle,
            ),
            Text(
              'Updated: ${_formatDate(_currentTodo.updatedAt)}',
              style: textStyle,
            ),
            if (_currentTodo.hasChanges)
              Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Changed fields: ${_currentTodo.changedFields.join(", ")}',
                    style: textStyle?.copyWith(color: Colors.blue),
                  ),
                ],
              ),
            if (_currentTodo.syncError.isNotEmpty)
              Text(
                'Error: ${_currentTodo.syncError}',
                style: textStyle?.copyWith(color: Colors.red),
              ),
            if (_currentTodo.syncAttempts > 0)
              Text(
                'Sync attempts: ${_currentTodo.syncAttempts}',
                style: textStyle,
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Todo'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _deleteTodo();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
