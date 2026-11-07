import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'encryption_service.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  static const String _keyPinHash = 'vault_pin_hash';
  static const String _keyBiometricsEnabled = 'vault_biometrics_enabled';
  static const String _defaultPinSalt = 'salt_for_offline_vault_security_2026';

  bool _isLocked = true;
  bool get isLocked => _isLocked;

  /// Check if user has already created a PIN
  Future<bool> isPinSet() async {
    final hash = await _secureStorage.read(key: _keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// Check if device supports biometrics
  Future<bool> canUseBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Check if biometric unlock is enabled in app settings
  Future<bool> isBiometricsEnabled() async {
    final val = await _secureStorage.read(key: _keyBiometricsEnabled);
    return val == 'true';
  }

  /// Toggle biometrics
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricsEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Hash PIN with SHA-256 + salt
  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin + _defaultPinSalt)).toString();
  }

  /// Setup initial PIN
  Future<void> setupPin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: _keyPinHash, value: hash);
    // Also store master encryption key or initialize encryption with the PIN
    EncryptionService.instance.initialize(pin);
    _isLocked = false;
  }

  /// Verify entered PIN
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _keyPinHash);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    if (inputHash == storedHash) {
      EncryptionService.instance.initialize(pin);
      _isLocked = false;
      return true;
    }
    return false;
  }

  /// Authenticate with biometric (Fingerprint / Face ID)
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isEnabled = await isBiometricsEnabled();
      if (!isEnabled) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock your Secure Vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // Biometrics successful, unlock vault
        // Note: In a production app, the encryption key can be stored in Android Keystore / iOS Keychain
        _isLocked = false;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Lock vault
  void lock() {
    _isLocked = true;
  }

  /// Unlock manually
  void unlock() {
    _isLocked = false;
  }
}
