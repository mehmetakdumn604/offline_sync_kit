// ignore_for_file: public_member_api_docs

import 'package:encrypt/encrypt.dart' as encrypt;

/// Represents the encryption configuration options
///
/// This class is used to configure various aspects of data encryption
/// within the offline sync system.
class EncryptionOptions {
  /// Whether encryption is enabled
  final bool enabled;

  /// The encryption key to use
  final String? key;

  /// The encryption mode
  final EncryptionMode mode;

  /// Initialization vector length in bytes
  final int ivLength;

  /// Creates a new encryption options instance
  ///
  /// [enabled] Whether encryption is enabled (default: false)
  /// [key] The encryption key to use (required if enabled is true)
  /// [mode] The encryption mode to use (default: EncryptionMode.aes)
  /// [ivLength] Initialization vector length in bytes (default: 16)
  const EncryptionOptions({
    this.enabled = false,
    this.key,
    this.mode = EncryptionMode.aes,
    this.ivLength = 16,
  }) : assert(
         !enabled || (enabled && key != null),
         'An encryption key must be provided when encryption is enabled',
       );

  /// Creates a copy of this object with the specified fields replaced
  EncryptionOptions copyWith({
    bool? enabled,
    String? key,
    EncryptionMode? mode,
    int? ivLength,
  }) {
    return EncryptionOptions(
      enabled: enabled ?? this.enabled,
      key: key ?? this.key,
      mode: mode ?? this.mode,
      ivLength: ivLength ?? this.ivLength,
    );
  }

  /// Creates a disabled encryption options instance
  static const EncryptionOptions disabled = EncryptionOptions(enabled: false);

  /// Creates a production-ready encryption options instance with AES encryption
  static EncryptionOptions secure(String key) =>
      EncryptionOptions(enabled: true, key: key, mode: EncryptionMode.aes);

  /// A factory method to create encryption options from a map
  factory EncryptionOptions.fromJson(Map<String, dynamic> json) {
    return EncryptionOptions(
      enabled: json['enabled'] as bool? ?? false,
      key: json['key'] as String?,
      mode: EncryptionMode.values.firstWhere(
        (e) => e.name == (json['mode'] as String? ?? EncryptionMode.aes.name),
        orElse: () => EncryptionMode.aes,
      ),
      ivLength: json['ivLength'] as int? ?? 16,
    );
  }

  /// Converts this options object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'key': key,
      'mode': mode.name,
      'ivLength': ivLength,
    };
  }
}

/// The encryption mode to use
enum EncryptionMode {
  /// AES encryption (default)
  aes,

  /// Salsa20 encryption
  salsa20,

  /// Fernet encryption (includes authentication)
  fernet,
}

/// Used to determine which fields should be encrypted
///
/// This is used to control which fields in a model are encrypted
enum FieldEncryptionPolicy {
  /// Encrypt all fields except for ID and modelType
  allExceptIdAndType,

  /// Encrypt only the specified fields
  onlySpecifiedFields,

  /// Encrypt all except for the specified fields
  allExceptSpecifiedFields,
}

/// Extension methods for EncryptionMode
extension EncryptionModeExtension on EncryptionMode {
  /// Gets the actual encrypter implementation
  encrypt.Encrypter getEncrypter(encrypt.Key key) {
    switch (this) {
      case EncryptionMode.aes:
        return encrypt.Encrypter(encrypt.AES(key));
      case EncryptionMode.salsa20:
        return encrypt.Encrypter(encrypt.Salsa20(key));
      case EncryptionMode.fernet:
        return encrypt.Encrypter(encrypt.Fernet(key));
    }
  }
}
