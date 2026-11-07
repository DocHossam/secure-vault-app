import 'package:flutter_test/flutter_test.dart';
import 'package:secure_vault_app/models/subscription.dart';
import 'package:secure_vault_app/models/vault_item.dart';
import 'package:secure_vault_app/utils/formatters.dart';
import 'package:secure_vault_app/utils/vault_strings.dart';

void main() {
  group('Vault Unit Tests', () {
    test('Detect Card Brand correctly', () {
      expect(CardBrandHelper.detectBrand('4123 4567 8901 2345'), 'Visa');
      expect(CardBrandHelper.detectBrand('5123 4567 8901 2345'), 'Mastercard');
      expect(CardBrandHelper.detectBrand('5078 0300 0000 0000'), 'Meeza');
    });

    test('Mask Card Number correctly', () {
      expect(CardBrandHelper.maskCardNumber('4123 4567 8901 2345'), '•••• •••• •••• 2345');
    });

    test('VaultItem serialization works', () {
      final now = DateTime.now();
      final item = VaultItem(id: 'test-1', title: 'OpenAI API Key', category: ItemCategory.apiKey, secretValue: 'sk-test-12345', createdAt: now, updatedAt: now);
      final restored = VaultItem.fromMap(item.toMap());
      expect(restored.id, 'test-1');
      expect(restored.title, 'OpenAI API Key');
      expect(restored.primaryCopyableValue, 'sk-test-12345');
    });

    test('Dashboard copy supports Arabic and English', () {
      expect(const VaultStrings(false).appName, 'Secure Vault');
      expect(const VaultStrings(true).appName, 'الخزنة الآمنة');
      expect(const VaultStrings(true).addItem, 'إضافة عنصر');
    });

    test('Subscription serialization preserves reminder settings', () {
      final now = DateTime(2026, 11, 7);
      final subscription = Subscription(
        id: 'subscription-1',
        name: 'ChatGPT',
        amount: 20,
        currency: 'USD',
        nextRenewalDate: DateTime(2026, 12, 7),
        cycle: BillingCycle.monthly,
        category: SubscriptionCategory.cloudAi,
        reminderDays: const [7, 3, 1],
        cardLastFour: '1234',
        createdAt: now,
        updatedAt: now,
      );

      final restored = Subscription.fromMap(subscription.toMap());
      expect(restored.name, 'ChatGPT');
      expect(restored.amount, 20);
      expect(restored.reminderDays, [7, 3, 1]);
      expect(restored.cardLastFour, '1234');
    });

    test('Monthly renewal dates keep the original billing day', () {
      final subscription = Subscription(
        id: 'billing-day',
        name: 'Example',
        amount: 10,
        currency: 'EGP',
        nextRenewalDate: DateTime(2027, 1, 31),
        cycle: BillingCycle.monthly,
        category: SubscriptionCategory.other,
        createdAt: DateTime(2026, 11, 7),
        updatedAt: DateTime(2026, 11, 7),
      );

      final dates = subscription.upcomingRenewalDates(
        count: 3,
        reference: DateTime(2027, 1, 1),
      );
      expect(dates, [
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
        DateTime(2027, 3, 31),
      ]);
    });

    test('Past renewal dates advance to the next billing cycle', () {
      final subscription = Subscription(
        id: 'past-due',
        name: 'Example',
        amount: 10,
        currency: 'EGP',
        nextRenewalDate: DateTime(2026, 10, 15),
        cycle: BillingCycle.monthly,
        category: SubscriptionCategory.other,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(
        subscription.nextDueDate(reference: DateTime(2026, 11, 7)),
        DateTime(2026, 11, 15),
      );
      expect(
        subscription.daysUntilDue(reference: DateTime(2026, 11, 7)),
        8,
      );
    });
  });
}
