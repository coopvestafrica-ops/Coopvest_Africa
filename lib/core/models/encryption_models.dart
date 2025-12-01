class EncryptionException implements Exception {
  final String message;
  final dynamic error;

  EncryptionException(this.message, [this.error]);

  @override
  String toString() => 'EncryptionException: $message${error != null ? ' ($error)' : ''}';
}

enum EncryptionStatus {
  uninitialized,
  initializing,
  ready,
  error,
  keyRotating
}

class EncryptionMetadata {
  final String version;
  final DateTime created;
  final DateTime? lastRotated;
  final String keyId;
  final Map<String, dynamic>? additionalData;

  EncryptionMetadata({
    required this.version,
    required this.created,
    this.lastRotated,
    required this.keyId,
    this.additionalData,
  });

  Map<String, dynamic> toMap() => {
    'version': version,
    'created': created.toIso8601String(),
    'lastRotated': lastRotated?.toIso8601String(),
    'keyId': keyId,
    'additionalData': additionalData,
  };

  factory EncryptionMetadata.fromMap(Map<String, dynamic> map) {
    return EncryptionMetadata(
      version: map['version'] as String,
      created: DateTime.parse(map['created'] as String),
      lastRotated: map['lastRotated'] != null 
        ? DateTime.parse(map['lastRotated'] as String)
        : null,
      keyId: map['keyId'] as String,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }
}
