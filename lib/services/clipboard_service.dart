import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  static final ClipboardService instance = ClipboardService._internal();
  ClipboardService._internal();

  Timer? _clearTimer;
  int autoClearSeconds = 30; // default 30s auto clear

  /// Copy text to system clipboard and set up auto-clear timer
  Future<void> copyToClipboard(String text, {int? timeoutSeconds}) async {
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));

    // Reset any existing timer
    _clearTimer?.cancel();

    final duration = timeoutSeconds ?? autoClearSeconds;
    if (duration > 0) {
      _clearTimer = Timer(Duration(seconds: duration), () async {
        await _clearIfMatches(text);
      });
    }
  }

  /// Automatically clears clipboard if it still contains the sensitive text
  Future<void> _clearIfMatches(String expectedText) async {
    try {
      final currentData = await Clipboard.getData(Clipboard.kTextPlain);
      if (currentData?.text == expectedText) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (_) {}
  }

  /// Manually clear clipboard immediately
  Future<void> clearImmediately() async {
    _clearTimer?.cancel();
    await Clipboard.setData(const ClipboardData(text: ''));
  }
}
