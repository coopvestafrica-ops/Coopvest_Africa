import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:uuid/uuid.dart';
import '../models/encryption_models.dart';

class EncryptionService {
  static const currentVersion = '1.0.0';
  static const chunkSize = 1024 * 1024; // 1MB chunks for large data
  
  final FlutterSecureStorage _storage;
  static const _keyKey = 'encryption_key';
  static const _ivKey = 'encryption_iv';
  static const _metadataKey = 'encryption_metadata';
  static const _backupKeyPrefix = 'backup_key_';
  
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;
  late String _currentKeyId;
  
  EncryptionStatus _status = EncryptionStatus.uninitialized;

  EncryptionService({FlutterSecureStorage? storage}) 
      : _storage = storage ?? const FlutterSecureStorage();

  EncryptionStatus get status => _status;

  Future<void> initialize() async {
    try {
      _status = EncryptionStatus.initializing;
      
      // Check if we have an existing key and metadata
      String? keyStr = await _storage.read(key: _keyKey);
      String? ivStr = await _storage.read(key: _ivKey);
      String? metadataStr = await _storage.read(key: _metadataKey);

      if (keyStr == null || ivStr == null || metadataStr == null) {
        await _generateNewKey();
      } else {
        // Load existing key and metadata
        final metadata = EncryptionMetadata.fromMap(
          jsonDecode(metadataStr) as Map<String, dynamic>
        );

        // Check version compatibility
        if (metadata.version != currentVersion) {
          await _migrateKey(metadata.version);
        }

        // Initialize encrypter with existing key
        final key = encrypt.Key(base64.decode(keyStr));
        _iv = encrypt.IV(base64.decode(ivStr));
        _encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
        _currentKeyId = metadata.keyId;

        // Validate the key
        if (!await validateKey()) {
          throw EncryptionException('Key validation failed');
        }
      }

      _status = EncryptionStatus.ready;
    } catch (e) {
      _status = EncryptionStatus.error;
      throw EncryptionException('Failed to initialize encryption service', e);
    }
  }

  Future<void> _generateNewKey() async {
    final key = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);
    final keyId = const Uuid().v4();

    final metadata = EncryptionMetadata(
      version: currentVersion,
      created: DateTime.now(),
      keyId: keyId,
    );

    // Store everything securely
    await Future.wait([
      _storage.write(key: _keyKey, value: base64.encode(key.bytes)),
      _storage.write(key: _ivKey, value: base64.encode(iv.bytes)),
      _storage.write(key: _metadataKey, value: jsonEncode(metadata.toMap())),
    ]);

    _encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    _iv = iv;
    _currentKeyId = keyId;
  }

  Future<void> _migrateKey(String oldVersion) async {
    // Implement version-specific migration logic here
    throw UnimplementedError('Migration from version $oldVersion is not implemented');
  }

  String encryptText(String data) {
    final encryptedData = _encrypter.encrypt(data, iv: _iv);
    return encryptedData.base64;
  }

  String decryptText(String encryptedData) {
    final encryptedObj = encrypt.Encrypted.fromBase64(encryptedData);
    return _encrypter.decrypt(encryptedObj, iv: _iv);
  }

  Uint8List encryptBytes(Uint8List data) {
    final dataStr = base64.encode(data);
    final encryptedStr = encryptText(dataStr);
    return base64.decode(encryptedStr);
  }

  Uint8List decryptBytes(Uint8List encryptedData) {
    final encryptedStr = base64.encode(encryptedData);
    final decryptedStr = decryptText(encryptedStr);
    return base64.decode(decryptedStr);
  }

  Future<void> rotateKey() async {
    _status = EncryptionStatus.keyRotating;
    try {
      // Backup the current key
      final oldKeyId = _currentKeyId;
      final oldKey = await _storage.read(key: _keyKey);
      if (oldKey != null) {
        await _storage.write(key: '$_backupKeyPrefix$oldKeyId', value: oldKey);
      }

      // Generate new key and IV
      final newKey = encrypt.Key.fromSecureRandom(32);
      final newIv = encrypt.IV.fromSecureRandom(16);
      final newKeyId = const Uuid().v4();

      // Create new encrypter
      final newEncrypter = encrypt.Encrypter(
        encrypt.AES(newKey, mode: encrypt.AESMode.cbc)
      );

      // Update metadata
      final metadataStr = await _storage.read(key: _metadataKey);
      if (metadataStr != null) {
        final metadata = EncryptionMetadata.fromMap(
          jsonDecode(metadataStr) as Map<String, dynamic>
        );
        
        final updatedMetadata = EncryptionMetadata(
          version: metadata.version,
          created: metadata.created,
          lastRotated: DateTime.now(),
          keyId: newKeyId,
          additionalData: metadata.additionalData,
        );

        // Store new key, IV and metadata
        await Future.wait([
          _storage.write(key: _keyKey, value: base64.encode(newKey.bytes)),
          _storage.write(key: _ivKey, value: base64.encode(newIv.bytes)),
          _storage.write(key: _metadataKey, value: jsonEncode(updatedMetadata.toMap())),
        ]);

        // Update instance variables
        _encrypter = newEncrypter;
        _iv = newIv;
        _currentKeyId = newKeyId;
      }

      _status = EncryptionStatus.ready;
    } catch (e) {
      _status = EncryptionStatus.error;
      throw EncryptionException('Failed to rotate encryption key', e);
    }
  }

  Future<bool> validateKey() async {
    try {
      final testData = 'test';
      final encrypted = encryptText(testData);
      final decrypted = decryptText(encrypted);
      return testData == decrypted;
    } catch (e) {
      return false;
    }
  }
}
