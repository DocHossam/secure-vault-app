import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/subscription.dart';
import 'encryption_service.dart';

class SubscriptionStorageService {
  SubscriptionStorageService._();
  static final SubscriptionStorageService instance = SubscriptionStorageService._();

  static const String _boxName = 'secure_vault_subscriptions';
  Box<String>? _box;

  Future<void> init() async {
    if (_box?.isOpen == true) return;
    _box = await Hive.openBox<String>(_boxName);
  }

  Box<String> get _openBox {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('Subscription storage has not been initialized.');
    }
    return box;
  }

  List<Subscription> getAll() {
    if (!EncryptionService.instance.isInitialized) {
      throw StateError('Unlock the vault before reading subscriptions.');
    }
    final result = <Subscription>[];
    for (final value in _openBox.values) {
      try {
        final plainText = EncryptionService.instance.decryptText(value);
        result.add(
          Subscription.fromMap(
            Map<String, dynamic>.from(jsonDecode(plainText) as Map),
          ),
        );
      } catch (_) {
        // Skip an unreadable record instead of preventing the rest from loading.
      }
    }
    result.sort((a, b) => a.nextDueDate().compareTo(b.nextDueDate()));
    return result;
  }

  Future<void> save(Subscription subscription) async {
    if (!EncryptionService.instance.isInitialized) {
      throw StateError('Unlock the vault before saving subscriptions.');
    }
    final encrypted = EncryptionService.instance.encryptText(
      jsonEncode(subscription.toMap()),
    );
    await _openBox.put(subscription.id, encrypted);
  }

  Future<void> delete(String id) async {
    await _openBox.delete(id);
  }

  List<Map<String, dynamic>> exportForBackup() {
    return getAll().map((subscription) => subscription.toMap()).toList();
  }

  Future<int> importFromBackup(List<dynamic> rawSubscriptions) async {
    var imported = 0;
    for (final raw in rawSubscriptions) {
      try {
        final subscription = Subscription.fromMap(
          Map<String, dynamic>.from(raw as Map),
        );
        await save(subscription);
        imported++;
      } catch (_) {
        // Ignore an invalid record and continue restoring the backup.
      }
    }
    return imported;
  }
}
