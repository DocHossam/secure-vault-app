import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/subscription.dart';

class SubscriptionNotificationService {
  SubscriptionNotificationService._();
  static final SubscriptionNotificationService instance =
      SubscriptionNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  Future<void> syncAll(
    List<Subscription> subscriptions, {
    required bool isArabic,
  }) async {
    if (!_initialized) return;
    for (final subscription in subscriptions) {
      await syncSubscription(subscription, isArabic: isArabic);
    }
  }

  Future<void> syncSubscription(
    Subscription subscription, {
    required bool isArabic,
  }) async {
    if (!_initialized) return;

    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      if (notification.payload == subscription.id) {
        await _plugin.cancel(notification.id);
      }
    }

    if (!subscription.isActive || !subscription.remindersEnabled) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'subscription_reminders',
        'Subscription reminders',
        channelDescription: 'Alerts before recurring subscription renewals',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    final renewals = subscription.upcomingRenewalDates(count: 5);
    for (final renewal in renewals) {
      for (final leadDays in subscription.reminderDays) {
        final reminderDate = renewal.subtract(Duration(days: leadDays));
        final scheduled = tz.TZDateTime(
          tz.local,
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9,
        );
        if (!scheduled.isAfter(now)) continue;

        final notificationId = _notificationId(
          '${subscription.id}|${renewal.toIso8601String()}|$leadDays',
        );
        final title = isArabic
            ? 'موعد تجديد قريب: ${subscription.name}'
            : '${subscription.name} renews soon';
        final body = isArabic
            ? 'التجديد خلال $leadDays يوم • ${subscription.amount.toStringAsFixed(2)} ${subscription.currency}'
            : 'Renews in $leadDays day(s) • ${subscription.amount.toStringAsFixed(2)} ${subscription.currency}';

        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: subscription.id,
        );
      }
    }
  }

  Future<void> cancelForSubscription(String subscriptionId) async {
    if (!_initialized) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      if (notification.payload == subscriptionId) {
        await _plugin.cancel(notification.id);
      }
    }
  }

  int _notificationId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
