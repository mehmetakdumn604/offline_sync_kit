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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(
      text: widget.todo.description,
    );
    _isCompleted = widget.todo.isCompleted;
    _priority = widget.todo.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTodo() async {
    final updatedTodo = widget.todo.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      isCompleted: _isCompleted,
      priority: _priority,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    try {
      await OfflineSyncManager.instance.updateModel<Todo>(updatedTodo);
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating todo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating todo: $e')));
    }
  }

  Future<void> _deleteTodo() async {
    try {
      await OfflineSyncManager.instance.deleteModel<Todo>(
        widget.todo.id,
        widget.todo.modelType,
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error deleting todo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting todo: $e')));
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
            _buildSyncStatus(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTodo,
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
            Text('Sync Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  widget.todo.isSynced
                      ? Icons.check_circle
                      : Icons.sync_problem,
                  color: widget.todo.isSynced ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.todo.isSynced ? 'Synced' : 'Not synced',
                  style: textStyle,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${_formatDate(widget.todo.createdAt)}',
              style: textStyle,
            ),
            Text(
              'Updated: ${_formatDate(widget.todo.updatedAt)}',
              style: textStyle,
            ),
            if (widget.todo.syncError.isNotEmpty)
              Text(
                'Error: ${widget.todo.syncError}',
                style: textStyle?.copyWith(color: Colors.red),
              ),
            if (widget.todo.syncAttempts > 0)
              Text(
                'Sync attempts: ${widget.todo.syncAttempts}',
                style: textStyle,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Todo'),
          content: const Text('Are you sure you want to delete this todo?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTodo();
              },
            ),
          ],
        );
      },
    );
  }
}
