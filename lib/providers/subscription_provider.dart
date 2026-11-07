import 'package:flutter/foundation.dart';

import '../models/subscription.dart';
import '../services/subscription_notification_service.dart';
import '../services/subscription_storage_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionStorageService _storage = SubscriptionStorageService.instance;
  final SubscriptionNotificationService _notifications =
      SubscriptionNotificationService.instance;

  List<Subscription> _subscriptions = [];
  bool _isLoading = true;

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool get isLoading => _isLoading;

  List<Subscription> get activeSubscriptions => _subscriptions
      .where((subscription) => subscription.status == SubscriptionStatus.active)
      .toList()
    ..sort((a, b) => a.nextDueDate().compareTo(b.nextDueDate()));

  List<Subscription> get upcomingSubscriptions => activeSubscriptions
      .where((subscription) => subscription.daysUntilDue() <= 30)
      .toList();

  Future<void> load({required bool isArabic}) async {
    _isLoading = true;
    notifyListeners();
    await _storage.init();
    _subscriptions = _storage.getAll();
    _isLoading = false;
    notifyListeners();
    await _notifications.syncAll(_subscriptions, isArabic: isArabic);
  }

  Future<void> saveSubscription(
    Subscription subscription, {
    required bool isArabic,
  }) async {
    await _storage.save(subscription);
    final index = _subscriptions.indexWhere((item) => item.id == subscription.id);
    if (index == -1) {
      _subscriptions.add(subscription);
    } else {
      _subscriptions[index] = subscription;
    }
    _subscriptions.sort((a, b) => a.nextDueDate().compareTo(b.nextDueDate()));
    notifyListeners();
    await _notifications.syncSubscription(subscription, isArabic: isArabic);
  }

  Future<void> updateStatus(
    Subscription subscription,
    SubscriptionStatus status, {
    required bool isArabic,
  }) async {
    final updated = subscription.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await saveSubscription(updated, isArabic: isArabic);
  }

  Future<void> deleteSubscription(String id) async {
    await _storage.delete(id);
    _subscriptions.removeWhere((item) => item.id == id);
    notifyListeners();
    await _notifications.cancelForSubscription(id);
  }
}
