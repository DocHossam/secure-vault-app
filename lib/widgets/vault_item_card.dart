import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../utils/theme.dart';
import '../screens/item_detail_screen.dart';

class VaultItemCard extends StatelessWidget {
  final VaultItem item;

  const VaultItemCard({super.key, required this.item});

  IconData _getCategoryIcon(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.apiKey:
        return Icons.vpn_key_rounded;
      case ItemCategory.creditCard:
        return Icons.credit_card_rounded;
      case ItemCategory.secureNote:
        return Icons.note_alt_rounded;
      case ItemCategory.photoDocument:
        return Icons.photo_library_rounded;
    }
  }

  Color _getCategoryColor(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.apiKey:
        return VaultTheme.primary;
      case ItemCategory.creditCard:
        return const Color(0xFF6366F1); // Indigo
      case ItemCategory.secureNote:
        return const Color(0xFFF59E0B); // Amber
      case ItemCategory.photoDocument:
        return const Color(0xFFEC4899); // Pink
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VaultProvider>(context, listen: false);
    final catColor = _getCategoryColor(item.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: VaultTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VaultTheme.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(itemId: item.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Category Icon Pill
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: catColor.withOpacity(0.25)),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: catColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: VaultTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isFavorite)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.displaySubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: VaultTheme.textSecondary,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: item.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: VaultTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: VaultTheme.textMuted,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Quick One-Tap Copy Action Button
                if (item.primaryCopyableValue.isNotEmpty)
                  Tooltip(
                    message: 'One-Tap Copy',
                    child: InkWell(
                      onTap: () {
                        provider.copyItemValue(context, item);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: VaultTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VaultTheme.border),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: VaultTheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
