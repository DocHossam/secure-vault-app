import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/secret_display_box.dart';
import 'add_edit_item_screen.dart';
import 'full_image_viewer_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  void _confirmDelete(BuildContext context, VaultProvider provider, VaultItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VaultTheme.surface,
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to permanently delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: VaultTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VaultTheme.error),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await provider.deleteItem(item.id);
              if (context.mounted) {
                Navigator.pop(context); // Close details screen
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VaultProvider>(context);
    final itemIndex = provider.items.indexWhere((e) => e.id == itemId);

    if (itemIndex == -1) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found')),
      );
    }

    final item = provider.items[itemIndex];
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          IconButton(
            icon: Icon(
              item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: item.isFavorite ? Colors.amber : VaultTheme.textSecondary,
            ),
            tooltip: 'Favorite',
            onPressed: () => provider.toggleFavorite(item.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditItemScreen(itemToEdit: item),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: VaultTheme.error),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, provider, item),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: VaultTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VaultTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_outlined, size: 14, color: VaultTheme.accent),
                  const SizedBox(width: 6),
                  Text(
                    item.category.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VaultTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Credit Card Specific View
            if (item.category == ItemCategory.creditCard) ...[
              CreditCardWidget(item: item, isInteractive: true),
              const SizedBox(height: 16),
            ],

            // API Key Specific View
            if (item.category == ItemCategory.apiKey) ...[
              if (item.environment != null && item.environment!.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('Environment: ', style: TextStyle(color: VaultTheme.textSecondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: VaultTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.environment!,
                        style: const TextStyle(
                          color: VaultTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              SecretDisplayBox(
                label: 'PRIMARY API KEY / TOKEN',
                secretValue: item.secretValue ?? '',
                subtitle: 'Tap to copy',
              ),
              if (item.secondarySecret != null && item.secondarySecret!.isNotEmpty)
                SecretDisplayBox(
                  label: 'CLIENT SECRET / KEY ID',
                  secretValue: item.secondarySecret!,
                ),
              if (item.apiUrl != null && item.apiUrl!.isNotEmpty)
                _buildInfoRow(
                  context,
                  label: 'API URL / Endpoint',
                  value: item.apiUrl!,
                  canCopy: true,
                  onCopy: () => provider.copyItemValue(
                    context,
                    item,
                    customValue: item.apiUrl,
                    label: 'API URL',
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Photos and Documents View
            if (item.imagePaths.isNotEmpty) ...[
              const Text(
                'ATTACHED PHOTOS & DOCUMENTS',
                style: TextStyle(
                  color: VaultTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildImageGrid(context, item.imagePaths),
              const SizedBox(height: 16),
            ],

            // Notes Section
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const Text(
                'NOTES & DETAILS',
                style: TextStyle(
                  color: VaultTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VaultTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VaultTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      item.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: VaultTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Notes'),
                        style: TextButton.styleFrom(
                          foregroundColor: VaultTheme.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => provider.copyItemValue(
                          context,
                          item,
                          customValue: item.notes,
                          label: 'Notes',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Tags Section
            if (item.tags.isNotEmpty) ...[
              const Text(
                'TAGS',
                style: TextStyle(
                  color: VaultTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: item.tags.map((tag) {
                  return Chip(
                    backgroundColor: VaultTheme.surfaceLight,
                    side: const BorderSide(color: VaultTheme.border),
                    label: Text('#$tag', style: const TextStyle(color: VaultTheme.accent, fontSize: 12)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Timestamps
            Divider(color: VaultTheme.border.withOpacity(0.6)),
            const SizedBox(height: 8),
            Text(
              'Created: ${dateFormat.format(item.createdAt)}',
              style: const TextStyle(color: VaultTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: ${dateFormat.format(item.updatedAt)}',
              style: const TextStyle(color: VaultTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool canCopy = false,
    VoidCallback? onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: VaultTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VaultTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: VaultTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: VaultTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: VaultTheme.primary),
              onPressed: onCopy,
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<String> paths) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paths.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (ctx, index) {
        final path = paths[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullImageViewerScreen(imagePath: path),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: VaultTheme.surfaceLight,
              child: FutureBuilder(
                future: StorageService.instance.getImageBytes(path),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    );
                  }
                  return const Center(
                    child: Icon(Icons.image_rounded, color: VaultTheme.textMuted),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
