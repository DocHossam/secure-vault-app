import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/vault_provider.dart';
import '../services/auth_service.dart';
import '../services/clipboard_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService.instance;
  bool _biometricsEnabled = false;
  bool _canBiometrics = false;
  int _clipboardSeconds = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bioEnabled = await _auth.isBiometricsEnabled();
    final canBio = await _auth.canUseBiometrics();
    setState(() {
      _biometricsEnabled = bioEnabled;
      _canBiometrics = canBio;
      _clipboardSeconds = ClipboardService.instance.autoClearSeconds;
    });
  }

  Future<void> _toggleBiometrics(bool val) async {
    await _auth.setBiometricsEnabled(val);
    setState(() => _biometricsEnabled = val);
  }

  Future<void> _exportBackup() async {
    try {
      final backupData = await StorageService.instance.exportBackupData();
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/vault_backup_${DateTime.now().millisecondsSinceEpoch}.vault');
      await backupFile.writeAsString(backupData);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text: 'My Secure Vault Encrypted Backup',
        subject: 'Secure Vault Backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export backup: $e')),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final count = await StorageService.instance.importBackupData(content);

        if (mounted) {
          Provider.of<VaultProvider>(context, listen: false).loadItems();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully imported $count items!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import backup: $e')),
        );
      }
    }
  }

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VaultTheme.surface,
        title: const Text('Change Master PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current 6-Digit PIN'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New 6-Digit PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: VaultTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldPin = oldPinController.text.trim();
              final newPin = newPinController.text.trim();

              if (newPin.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New PIN must be 6 digits')),
                );
                return;
              }

              final isValid = await _auth.verifyPin(oldPin);
              if (!isValid) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Current PIN is incorrect')),
                  );
                }
                return;
              }

              await _auth.setupPin(newPin);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN changed successfully!')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VaultProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Security Header
          _buildSectionHeader('SECURITY & ACCESS'),
          const SizedBox(height: 8),

          // Biometrics
          Container(
            decoration: BoxDecoration(
              color: VaultTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VaultTheme.border),
            ),
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded, color: VaultTheme.primary),
              title: const Text('Biometric Unlock', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _canBiometrics
                    ? 'Use fingerprint or face recognition'
                    : 'Not supported on this device',
                style: const TextStyle(fontSize: 12, color: VaultTheme.textSecondary),
              ),
              value: _biometricsEnabled,
              onChanged: _canBiometrics ? _toggleBiometrics : null,
              activeColor: VaultTheme.primary,
            ),
          ),
          const SizedBox(height: 10),

          // Change PIN
          _buildTile(
            icon: Icons.pin_rounded,
            title: 'Change Master PIN',
            subtitle: 'Update your 6-digit access code',
            onTap: _showChangePinDialog,
          ),
          const SizedBox(height: 10),

          // Clipboard Auto-clear
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: VaultTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VaultTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: VaultTheme.accent),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clipboard Auto-Clear', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Clears copied secrets automatically', style: TextStyle(fontSize: 12, color: VaultTheme.textSecondary)),
                    ],
                  ),
                ),
                DropdownButton<int>(
                  value: _clipboardSeconds,
                  dropdownColor: VaultTheme.surface,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15s')),
                    DropdownMenuItem(value: 30, child: Text('30s')),
                    DropdownMenuItem(value: 60, child: Text('60s')),
                    DropdownMenuItem(value: 0, child: Text('Off')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _clipboardSeconds = val);
                      ClipboardService.instance.autoClearSeconds = val;
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup Header
          _buildSectionHeader('OFFLINE BACKUP & RESTORE'),
          const SizedBox(height: 8),

          _buildTile(
            icon: Icons.upload_file_rounded,
            title: 'Export Encrypted Backup',
            subtitle: 'Save a backup file to keep your data safe offline',
            onTap: _exportBackup,
          ),
          const SizedBox(height: 10),

          _buildTile(
            icon: Icons.download_rounded,
            title: 'Restore from Backup',
            subtitle: 'Import a previously exported .vault file',
            onTap: _importBackup,
          ),
          const SizedBox(height: 24),

          // Vault Stats & Zero-Knowledge Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VaultTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VaultTheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_rounded, color: VaultTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Zero-Knowledge & 100% Offline',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: VaultTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'All your API keys, credit cards, notes, and photos are stored strictly on this device and encrypted with AES-256. No data ever leaves your phone.',
                  style: TextStyle(color: VaultTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Total Items: ${provider.items.length}',
                      style: const TextStyle(color: VaultTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: VaultTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: VaultTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VaultTheme.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: VaultTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: VaultTheme.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: VaultTheme.textMuted),
        onTap: onTap,
      ),
    );
  }
}
