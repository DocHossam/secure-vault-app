import 'package:flutter_test/flutter_test.dart';
import 'package:secure_vault_app/models/vault_item.dart';
import 'package:secure_vault_app/utils/formatters.dart';

void main() {
  group('Vault Unit Tests', () {
    test('Detect Card Brand correctly', () {
      expect(CardBrandHelper.detectBrand('4123 4567 8901 2345'), 'Visa');
      expect(CardBrandHelper.detectBrand('5123 4567 8901 2345'), 'Mastercard');
      expect(CardBrandHelper.detectBrand('5078 0300 0000 0000'), 'Meeza');
    });

    test('Mask Card Number correctly', () {
      final masked = CardBrandHelper.maskCardNumber('4123 4567 8901 2345');
      expect(masked, '•••• •••• •••• 2345');
    });

    test('VaultItem serialization works', () {
      final now = DateTime.now();
      final item = VaultItem(
        id: 'test-1',
        title: 'OpenAI API Key',
        category: ItemCategory.apiKey,
        secretValue: 'sk-test-12345',
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toMap();
      final restored = VaultItem.fromMap(map);

      expect(restored.id, 'test-1');
      expect(restored.title, 'OpenAI API Key');
      expect(restored.primaryCopyableValue, 'sk-test-12345');
    });
  });
}
