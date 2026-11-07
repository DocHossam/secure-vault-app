import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/vault_provider.dart';
import 'screens/lock_screen.dart';
import 'services/storage_service.dart';
import 'services/subscription_notification_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation & status bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: VaultTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize offline Hive storage and local subscription notifications.
  await StorageService.instance.init();
  await SubscriptionNotificationService.instance.initialize();

  runApp(const SecureVaultApp());
}

class SecureVaultApp extends StatelessWidget {
  const SecureVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VaultProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MaterialApp(
        title: 'Secure Vault',
        debugShowCheckedModeBanner: false,
        theme: VaultTheme.darkTheme,
        home: const LockScreen(),
      ),
    );
  }
}
