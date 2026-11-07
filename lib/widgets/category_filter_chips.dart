import 'package:flutter/material.dart';
import '../models/vault_item.dart';
import '../utils/theme.dart';

class CategoryFilterChips extends StatelessWidget {
  final ItemCategory? selectedCategory;
  final bool showFavoritesOnly;
  final ValueChanged<ItemCategory?> onCategorySelected;
  final VoidCallback onToggleFavorites;

  const CategoryFilterChips({
    super.key,
    required this.selectedCategory,
    required this.showFavoritesOnly,
    required this.onCategorySelected,
    required this.onToggleFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Favorite Filter Button
          _FilterChip(
            label: 'Favorites',
            icon: Icons.star_rounded,
            isSelected: showFavoritesOnly,
            selectedColor: Colors.amber,
            onTap: onToggleFavorites,
          ),
          const SizedBox(width: 8),

          // All Items Chip
          _FilterChip(
            label: 'All Items',
            icon: Icons.grid_view_rounded,
            isSelected: selectedCategory == null && !showFavoritesOnly,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),

          // API Keys Chip
          _FilterChip(
            label: 'API Keys',
            icon: Icons.vpn_key_rounded,
            isSelected: selectedCategory == ItemCategory.apiKey,
            onTap: () => onCategorySelected(ItemCategory.apiKey),
          ),
          const SizedBox(width: 8),

          // Cards Chip
          _FilterChip(
            label: 'Credit Cards',
            icon: Icons.credit_card_rounded,
            isSelected: selectedCategory == ItemCategory.creditCard,
            onTap: () => onCategorySelected(ItemCategory.creditCard),
          ),
          const SizedBox(width: 8),

          // Secure Notes Chip
          _FilterChip(
            label: 'Notes',
            icon: Icons.note_alt_rounded,
            isSelected: selectedCategory == ItemCategory.secureNote,
            onTap: () => onCategorySelected(ItemCategory.secureNote),
          ),
          const SizedBox(width: 8),

          // Photos Chip
          _FilterChip(
            label: 'Media',
            icon: Icons.photo_library_rounded,
            isSelected: selectedCategory == ItemCategory.photoDocument,
            onTap: () => onCategorySelected(ItemCategory.photoDocument),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedColor ?? VaultTheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.18) : VaultTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : VaultTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : VaultTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : VaultTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
