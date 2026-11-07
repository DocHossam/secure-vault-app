import 'package:flutter/material.dart';
import '../models/vault_item.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../services/clipboard_service.dart';

class CreditCardWidget extends StatefulWidget {
  final VaultItem item;
  final bool isInteractive;

  const CreditCardWidget({
    super.key,
    required this.item,
    this.isInteractive = true,
  });

  @override
  State<CreditCardWidget> createState() => _CreditCardWidgetState();
}

class _CreditCardWidgetState extends State<CreditCardWidget> {
  bool _revealDetails = false;

  @override
  Widget build(BuildContext context) {
    final gradientColors = VaultTheme.cardGradients[
      widget.item.cardColorIndex % VaultTheme.cardGradients.length
    ];

    final cardNumber = widget.item.cardNumber ?? '•••• •••• •••• ••••';
    final cardHolder = (widget.item.cardHolder ?? 'CARDHOLDER NAME').toUpperCase();
    final expiry = widget.item.expiryDate ?? 'MM/YY';
    final cvv = widget.item.cvv ?? '•••';
    final brand = widget.item.cardBrand ?? CardBrandHelper.detectBrand(cardNumber);

    return Container(
      width: double.infinity,
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Background subtle watermarks
          Positioned(
            right: -25,
            bottom: -25,
            child: Icon(
              Icons.credit_card_rounded,
              size: 160,
              color: Colors.white.withOpacity(0.05),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header: Bank / Title & Card Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.item.title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      brand.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              // Chip and Contactless Icon
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200, width: 0.8),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ChipLinesPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.contactless_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 24,
                  ),
                  const Spacer(),
                  if (widget.isInteractive)
                    IconButton(
                      icon: Icon(
                        _revealDetails ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _revealDetails = !_revealDetails;
                        });
                      },
                      tooltip: _revealDetails ? 'Hide Details' : 'Reveal Details',
                    ),
                ],
              ),

              // Card Number with Click to Copy
              InkWell(
                onTap: widget.isInteractive
                    ? () {
                        final clean = cardNumber.replaceAll(' ', '');
                        ClipboardService.instance.copyToClipboard(clean);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Card number copied to clipboard! (Auto-clears in 30s)'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        _revealDetails ? cardNumber : CardBrandHelper.maskCardNumber(cardNumber),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.2,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),

              // Card Holder, Expiry & CVV
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Holder Name
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cardHolder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Expiry
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'EXPIRES',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expiry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CVV
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: widget.isInteractive
                          ? () {
                              if (cvv.isNotEmpty) {
                                ClipboardService.instance.copyToClipboard(cvv);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('CVV copied to clipboard! (Auto-clears in 30s)'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'CVV',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _revealDetails ? cvv : '•••',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), paint);
    canvas.drawLine(Offset(0, size.height * 0.6), Offset(size.width, size.height * 0.6), paint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
