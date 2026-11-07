import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _auth = AuthService.instance;
  bool _isFirstTime = false;
  bool _isConfirming = false;
  String _pin = '';
  String _confirmPin = '';
  String _errorMessage = '';
  bool _canBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkInitStatus();
  }

  Future<void> _checkInitStatus() async {
    final hasPin = await _auth.isPinSet();
    final canBio = await _auth.canUseBiometrics();
    final bioEnabled = await _auth.isBiometricsEnabled();

    setState(() {
      _isFirstTime = !hasPin;
      _canBiometrics = canBio && bioEnabled;
    });

    if (!_isFirstTime && _canBiometrics) {
      _tryBiometricAuth();
    }
  }

  Future<void> _tryBiometricAuth() async {
    final success = await _auth.authenticateWithBiometrics();
    if (success && mounted) {
      _navigateToHome();
    }
  }

  void _onDigitPressed(String digit) {
    if (_pin.length >= 6) return;

    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = '';
      _pin += digit;
    });

    if (_pin.length == 6) {
      _handleCompletedPin();
    }
  }

  void _onBackspacePressed() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = '';
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _handleCompletedPin() async {
    if (_isFirstTime) {
      if (!_isConfirming) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
      } else {
        if (_pin == _confirmPin) {
          // Setup PIN successfully
          await _auth.setupPin(_pin);
          if (mounted) {
            _navigateToHome();
          }
        } else {
          setState(() {
            _errorMessage = 'PINs do not match. Try again.';
            _pin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      }
    } else {
      // Verification mode
      final isValid = await _auth.verifyPin(_pin);
      if (isValid) {
        if (mounted) {
          _navigateToHome();
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _pin = '';
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Unlock Secure Vault';
    String subtitle = 'Enter your 6-digit Master PIN';

    if (_isFirstTime) {
      if (!_isConfirming) {
        title = 'Create Master PIN';
        subtitle = 'Choose a secure 6-digit PIN to protect your local vault';
      } else {
        title = 'Confirm Master PIN';
        subtitle = 'Re-enter your 6-digit PIN to confirm';
      }
    }

    return Scaffold(
      backgroundColor: VaultTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Shield Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: VaultTheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: VaultTheme.primary.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 44,
                color: VaultTheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title & Subtitle
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: VaultTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: VaultTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? VaultTheme.primary : VaultTheme.surfaceLight,
                    border: Border.all(
                      color: isFilled ? VaultTheme.primary : VaultTheme.border,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: VaultTheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const Spacer(flex: 3),

            // Number Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button (if available)
                      _canBiometrics && !_isFirstTime
                          ? _KeypadButton(
                              icon: Icons.fingerprint_rounded,
                              onTap: _tryBiometricAuth,
                            )
                          : const SizedBox(width: 72, height: 72),
                      _KeypadButton(
                        text: '0',
                        onTap: () => _onDigitPressed('0'),
                      ),
                      _KeypadButton(
                        icon: Icons.backspace_rounded,
                        onTap: _onBackspacePressed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),

            // 100% Offline Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 14, color: VaultTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  '100% Offline & Locally Encrypted (AES-256)',
                  style: TextStyle(fontSize: 12, color: VaultTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) {
        return _KeypadButton(
          text: digit,
          onTap: () => _onDigitPressed(digit),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadButton({this.text, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VaultTheme.surfaceLight,
          border: Border.all(color: VaultTheme.border),
        ),
        child: text != null
            ? Text(
                text!,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: VaultTheme.textPrimary,
                ),
              )
            : Icon(
                icon,
                color: VaultTheme.textPrimary,
                size: 26,
              ),
      ),
    );
  }
}
