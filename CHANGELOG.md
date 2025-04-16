## 1.2.0

* Added github address to pubspec.yaml file.
* Readme file updated.

## 1.1.0

* Advanced conflict resolution strategies:
  * Server-wins, client-wins, last-update-wins policies
  * Custom conflict resolution handler support
  * Conflict detection and reporting
* Delta synchronization:
  * Optimized syncing of changed fields only
  * Automatic tracking of field-level changes
  * Reduced network bandwidth usage
* Optional data encryption:
  * Secure storage of sensitive information
  * Configurable encryption keys
  * Transparent encryption/decryption process
* Performance optimizations:
  * Batched synchronization support
  * Prioritized sync queue management
  * Enhanced offline processing
* Extended configuration options:
  * Flexible synchronization intervals
  * Custom batch size settings
  * Bidirectional sync controls

## 1.0.0

* Initial official release
* Core features:
  * Flexible data model integration based on SyncModel
  * Offline data storage with local database
  * Automatic data synchronization
  * Internet connectivity monitoring
  * Synchronization status tracking
  * Exponential backoff retry mechanism
  * Bidirectional synchronization support
  * Data conflict management
  * Customizable API integration
* Example application demonstrating usage
* SQLite-based StorageServiceImpl implementation
* HTTP-based DefaultNetworkClient implementation
* Comprehensive documentation
