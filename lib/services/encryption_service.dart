import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  static final EncryptionService instance = EncryptionService._internal();
  EncryptionService._internal();

  enc.Key? _masterKey;
  final enc.IV _fixedIV = enc.IV.fromUtf8('1234567890123456'); // 16 bytes IV

  /// Initialize with a master key derived from user's master PIN/password and salt
  void initialize(String masterPin, {String salt = 'secure_local_vault_salt_v1'}) {
    final keyBytes = sha256.convert(utf8.encode(masterPin + salt)).bytes;
    _masterKey = enc.Key(Uint8List.fromList(keyBytes));
  }

  bool get isInitialized => _masterKey != null;

  /// Encrypt a plain text string
  String encryptText(String plainText) {
    if (_masterKey == null) {
      throw StateError('EncryptionService is not initialized');
    }
    if (plainText.isEmpty) return '';

    final encrypter = enc.Encrypter(enc.AES(_masterKey!, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _fixedIV);
    return encrypted.base64;
  }

  /// Decrypt a base64 encrypted string
  String decryptText(String encryptedBase64) {
    if (_masterKey == null) {
      throw StateError('EncryptionService is not initialized');
    }
    if (encryptedBase64.isEmpty) return '';

    try {
      final encrypter = enc.Encrypter(enc.AES(_masterKey!, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(encryptedBase64, iv: _fixedIV);
    } catch (e) {
      // If decryption fails (e.g. wrong key or corrupt), return original
      return encryptedBase64;
    }
  }

  /// Encrypt a local image file and save to destination path
  Future<void> encryptFile(File sourceFile, File targetFile) async {
    if (_masterKey == null) {
      throw StateError('EncryptionService is not initialized');
    }
    final bytes = await sourceFile.readAsBytes();
    final encrypter = enc.Encrypter(enc.AES(_masterKey!, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(bytes, iv: _fixedIV);
    await targetFile.writeAsBytes(encrypted.bytes);
  }

  /// Decrypt an encrypted local file into raw bytes for Image.memory
  Future<Uint8List> decryptFileToBytes(File encryptedFile) async {
    if (_masterKey == null) {
      throw StateError('EncryptionService is not initialized');
    }
    final encryptedBytes = await encryptedFile.readAsBytes();
    final encrypter = enc.Encrypter(enc.AES(_masterKey!, mode: enc.AESMode.cbc));
    final decryptedBytes = encrypter.decryptBytes(
      enc.Encrypted(encryptedBytes),
      iv: _fixedIV,
    );
    return Uint8List.fromList(decryptedBytes);
  }
}
