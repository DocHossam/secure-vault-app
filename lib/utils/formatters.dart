import 'package:flutter/services.dart';

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 19) {
      text = text.substring(0, 19);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text.replaceAll('/', '');
    if (newText.length > 4) {
      newText = newText.substring(0, 4);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != newText.length) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CardBrandHelper {
  static String detectBrand(String cardNumber) {
    final clean = cardNumber.replaceAll(' ', '');
    if (clean.isEmpty) return 'Unknown';

    // Egyptian Meeza Card check
    if (clean.startsWith('5078') || clean.startsWith('5079')) {
      return 'Meeza';
    }

    // Visa
    if (clean.startsWith('4')) {
      return 'Visa';
    }

    // Mastercard
    if (clean.startsWith(RegExp(r'^5[1-5]')) ||
        clean.startsWith(RegExp(r'^2(22[1-9]|2[3-9][0-9]|[3-6][0-9]{2}|7[01][0-9]|720)'))) {
      return 'Mastercard';
    }

    // American Express
    if (clean.startsWith('34') || clean.startsWith('37')) {
      return 'Amex';
    }

    // Discover
    if (clean.startsWith('6011') || clean.startsWith('65')) {
      return 'Discover';
    }

    return 'Generic';
  }

  static String maskCardNumber(String? cardNumber) {
    if (cardNumber == null || cardNumber.isEmpty) return '•••• •••• •••• ••••';
    final clean = cardNumber.replaceAll(' ', '');
    if (clean.length <= 4) return clean;

    final last4 = clean.substring(clean.length - 4);
    return '•••• •••• •••• $last4';
  }
}
