import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/vault_item.dart';
import '../services/subscription_storage_service.dart';
import 'encryption_service.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  static const String _boxName = 'secure_vault_items';
  Box? _box;
  final _uuid = const Uuid();

  /// Initialize Hive and open box
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Get directory for securely storing images and attachments
  Future<Directory> _getMediaDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'vault_media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  Map<String, dynamic> _encryptItemForStorage(VaultItem item) {
    final enc = EncryptionService.instance;
    final map = item.toMap();
    if (enc.isInitialized) {
      if (item.secretValue != null && item.secretValue!.isNotEmpty) {
        map['secretValue'] = enc.encryptText(item.secretValue!);
      }
      if (item.secondarySecret != null && item.secondarySecret!.isNotEmpty) {
        map['secondarySecret'] = enc.encryptText(item.secondarySecret!);
      }
      if (item.cardNumber != null && item.cardNumber!.isNotEmpty) {
        map['cardNumber'] = enc.encryptText(item.cardNumber!);
      }
      if (item.cvv != null && item.cvv!.isNotEmpty) {
        map['cvv'] = enc.encryptText(item.cvv!);
      }
    }
    return map;
  }

  VaultItem _decryptItemFromStorage(Map<String, dynamic> rawMap) {
    final enc = EncryptionService.instance;
    final map = Map<String, dynamic>.from(rawMap);
    if (enc.isInitialized) {
      if (map['secretValue'] != null && (map['secretValue'] as String).isNotEmpty) {
        map['secretValue'] = enc.decryptText(map['secretValue']);
      }
      if (map['secondarySecret'] != null && (map['secondarySecret'] as String).isNotEmpty) {
        map['secondarySecret'] = enc.decryptText(map['secondarySecret']);
      }
      if (map['cardNumber'] != null && (map['cardNumber'] as String).isNotEmpty) {
        map['cardNumber'] = enc.decryptText(map['cardNumber']);
      }
      if (map['cvv'] != null && (map['cvv'] as String).isNotEmpty) {
        map['cvv'] = enc.decryptText(map['cvv']);
      }
    }
    return VaultItem.fromMap(map);
  }

  /// Load all vault items
  List<VaultItem> getAllItems() {
    if (_box == null) return [];
    final List<VaultItem> list = [];
    for (var key in _box!.keys) {
      final raw = _box!.get(key);
      if (raw != null) {
        try {
          final map = Map<String, dynamic>.from(raw as Map);
          list.add(_decryptItemFromStorage(map));
        } catch (_) {}
      }
    }
    list.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  Future<void> saveItem(VaultItem item) async {
    if (_box == null) await init();
    final encryptedMap = _encryptItemForStorage(item);
    await _box!.put(item.id, encryptedMap);
  }

  Future<void> deleteItem(String id) async {
    if (_box == null) await init();
    final raw = _box!.get(id);
    if (raw != null) {
      final map = Map<String, dynamic>.from(raw as Map);
      final paths = List<String>.from(map['imagePaths'] ?? []);
      for (var path in paths) {
        final f = File(path);
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    }
    await _box!.delete(id);
  }

  Future<String> saveImageAttachment(File sourceImage) async {
    final mediaDir = await _getMediaDir();
    final ext = p.extension(sourceImage.path).isEmpty ? '.enc' : p.extension(sourceImage.path);
    final fileName = '${_uuid.v4()}$ext';
    final targetFile = File(p.join(mediaDir.path, fileName));
    if (EncryptionService.instance.isInitialized) {
      await EncryptionService.instance.encryptFile(sourceImage, targetFile);
    } else {
      await sourceImage.copy(targetFile.path);
    }
    return targetFile.path;
  }

  Future<Uint8List?> getImageBytes(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    if (EncryptionService.instance.isInitialized) {
      try {
        return await EncryptionService.instance.decryptFileToBytes(file);
      } catch (_) {
        return await file.readAsBytes();
      }
    } else {
      return await file.readAsBytes();
    }
  }

  /// Export the vault and subscriptions into one encrypted backup.
  Future<String> exportBackupData() async {
    final items = getAllItems();
    await SubscriptionStorageService.instance.init();
    final subscriptions = SubscriptionStorageService.instance.exportForBackup();
    final jsonStr = json.encode({
      'version': '1.1',
      'exportedAt': DateTime.now().toIso8601String(),
      'itemCount': items.length,
      'items': items.map((item) => item.toMap()).toList(),
      'subscriptionCount': subscriptions.length,
      'subscriptions': subscriptions,
    });
    if (EncryptionService.instance.isInitialized) {
      return EncryptionService.instance.encryptText(jsonStr);
    }
    return jsonStr;
  }

  /// Import vault entries and subscription reminders from a backup.
  Future<int> importBackupData(String backupData) async {
    String jsonStr = backupData;
    if (EncryptionService.instance.isInitialized) {
      try {
        jsonStr = EncryptionService.instance.decryptText(backupData);
      } catch (_) {}
    }
    final decoded = json.decode(jsonStr) as Map<String, dynamic>;
    final itemsList = decoded['items'] as List<dynamic>;
    var importedCount = 0;
    for (var raw in itemsList) {
      try {
        final item = VaultItem.fromMap(Map<String, dynamic>.from(raw as Map));
        await saveItem(item);
        importedCount++;
      } catch (_) {}
    }

    await SubscriptionStorageService.instance.init();
    final subscriptions = decoded['subscriptions'] as List<dynamic>? ?? const [];
    final importedSubscriptions =
        await SubscriptionStorageService.instance.importFromBackup(subscriptions);
    return importedCount + importedSubscriptions;
  }
}
