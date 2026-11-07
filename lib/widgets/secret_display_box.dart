import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/clipboard_service.dart';
import '../utils/theme.dart';

class SecretDisplayBox extends StatefulWidget {
  final String label;
  final String secretValue;
  final String? subtitle;

  const SecretDisplayBox({
    super.key,
    required this.label,
    required this.secretValue,
    this.subtitle,
  });

  @override
  State<SecretDisplayBox> createState() => _SecretDisplayBoxState();
}

class _SecretDisplayBoxState extends State<SecretDisplayBox> {
  bool _isRevealed = false;
  bool _justCopied = false;

  void _copy() async {
    if (widget.secretValue.isEmpty) return;

    HapticFeedback.lightImpact();
    await ClipboardService.instance.copyToClipboard(widget.secretValue);

    setState(() {
      _justCopied = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: VaultTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Copied ${widget.label} to clipboard! (Auto-clears in 30s)'),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _justCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.secretValue.isEmpty) return const SizedBox.shrink();

    final maskedText = '•' * (widget.secretValue.length > 24 ? 24 : widget.secretValue.length);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VaultTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VaultTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: VaultTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: VaultTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.subtitle!,
                    style: const TextStyle(
                      color: VaultTheme.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Mask Toggle Button
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 18,
                  color: VaultTheme.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _isRevealed = !_isRevealed;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _copy,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: VaultTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _justCopied ? VaultTheme.primary : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isRevealed ? widget.secretValue : maskedText,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: _isRevealed ? VaultTheme.textPrimary : VaultTheme.textMuted,
                        letterSpacing: _isRevealed ? 0.5 : 2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _justCopied
                          ? VaultTheme.primary.withOpacity(0.2)
                          : VaultTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _justCopied ? VaultTheme.primary : VaultTheme.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _justCopied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 14,
                          color: _justCopied ? VaultTheme.primary : VaultTheme.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _justCopied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _justCopied ? VaultTheme.primary : VaultTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
