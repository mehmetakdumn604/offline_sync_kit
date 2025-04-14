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

Flutter paketi olan Offline Sync Kit, farklı türdeki verileri cihaz üzerinde offline olarak saklamak ve internet bağlantısı sağlandığında bu verileri belirli bir API'ye senkronize etmek için tasarlanmıştır.

## Özellikler

- Offline veri saklama ve senkronizasyon
- Esnek ve genişletilebilir yapı
- Farklı veri tipleriyle çalışabilme
- Veri çakışmalarını yönetme
- Otomatik senkronizasyon
- İnternet bağlantı durumunu izleme
- Senkronizasyon durumu takibi

## Kurulum

Paketi projenize eklemek için `pubspec.yaml` dosyasına aşağıdaki satırları ekleyin:

```yaml
dependencies:
  offline_sync_kit: ^0.0.1
```

## Kullanım

### 1. Veri Modeli Oluşturma

Öncelikle senkronize edilecek veri modelinizi `SyncModel` sınıfından türetin:

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

### 2. Senkronizasyon Yöneticisini Başlatma

Uygulamanızın başlatılması sırasında `OfflineSyncManager`'ı yapılandırın:

```dart
import 'package:offline_sync_kit/offline_sync_kit.dart';

Future<void> initSyncManager() async {
  // API baz URL'inizi burada belirtin
  const baseUrl = 'https://api.example.com';
  
  final storageService = StorageServiceImpl();
  await storageService.initialize();
  
  // Model factory kaydetme
  (storageService as StorageServiceImpl).registerModelDeserializer<Todo>(
    'todo',
    (json) => Todo.fromJson(json),
  );
  
  await OfflineSyncManager.initialize(
    baseUrl: baseUrl,
    storageService: storageService,
  );
  
  // TodoModel'i OfflineSyncManager'a kaydetme
  OfflineSyncManager.instance.registerModelFactory<Todo>(
    'todo',
    (json) => Todo.fromJson(json),
  );
}
```

### 3. Verileri Yönetme

#### Veri Ekleme

```dart
final newTodo = Todo(
  title: 'Yeni görev',
  description: 'Bu bir örnek görevdir',
);

await OfflineSyncManager.instance.saveModel<Todo>(newTodo);
```

#### Veri Güncelleme

```dart
final updatedTodo = todo.copyWith(
  title: 'Güncellenmiş başlık',
  isCompleted: true,
);

await OfflineSyncManager.instance.updateModel<Todo>(updatedTodo);
```

#### Veri Silme

```dart
await OfflineSyncManager.instance.deleteModel<Todo>(todo.id, 'todo');
```

#### Veri Alma

```dart
// Tek bir öğeyi getirme
final todo = await OfflineSyncManager.instance.getModel<Todo>(id, 'todo');

// Tüm öğeleri getirme
final todos = await OfflineSyncManager.instance.getAllModels<Todo>('todo');
```

### 4. Senkronizasyon

#### Manuel Senkronizasyon

```dart
// Tüm verileri senkronize etme
await OfflineSyncManager.instance.syncAll();

// Belirli model tipini senkronize etme
await OfflineSyncManager.instance.syncByModelType('todo');
```

#### Otomatik Senkronizasyon

```dart
// Periyodik senkronizasyonu başlatma
await OfflineSyncManager.instance.startPeriodicSync();

// Periyodik senkronizasyonu durdurma
await OfflineSyncManager.instance.stopPeriodicSync();
```

### 5. Senkronizasyon Durumunu İzleme

```dart
// Senkronizasyon durumunu dinleme
OfflineSyncManager.instance.syncStatusStream.listen((status) {
  print('Bağlantı durumu: ${status.isConnected}');
  print('Senkronizasyon işlemi: ${status.isSyncing}');
  print('Bekleyen değişiklikler: ${status.pendingChanges}');
  print('Son senkronizasyon zamanı: ${status.lastSyncTime}');
});

// Mevcut durumu alma
final status = await OfflineSyncManager.instance.currentStatus;
```

## Örnek Uygulama

Paket ile birlikte gelen örnek uygulamayı çalıştırmak için:

```bash
cd example
flutter run
```

## Lisans

Bu paket MIT lisansı altında dağıtılmaktadır.
