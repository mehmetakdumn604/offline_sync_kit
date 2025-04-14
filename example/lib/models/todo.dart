import 'package:offline_sync_kit/offline_sync_kit.dart';

class Todo extends SyncModel {
  final String title;
  final String description;
  final bool isCompleted;
  final int priority;

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
    int? priority,
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
    );
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: json['priority'] as int? ?? 1,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      isSynced: json['isSynced'] as bool? ?? false,
      syncError: json['syncError'] as String? ?? '',
      syncAttempts: json['syncAttempts'] as int? ?? 0,
    );
  }
}
