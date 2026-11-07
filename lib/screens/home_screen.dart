import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/vault_item_card.dart';
import 'add_edit_item_screen.dart';
import 'lock_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VaultProvider>(context, listen: false).loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to Vault',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: VaultTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose what you want to store securely',
                style: TextStyle(fontSize: 13, color: VaultTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              _buildCategoryOption(
                ctx,
                category: ItemCategory.apiKey,
                title: 'API Key & Token',
                subtitle: 'Save API credentials, private tokens & secrets',
                icon: Icons.vpn_key_rounded,
                color: VaultTheme.primary,
              ),
              _buildCategoryOption(
                ctx,
                category: ItemCategory.creditCard,
                title: 'Credit / Debit Card',
                subtitle: 'Visa, Mastercard, Meeza with card number & CVV',
                icon: Icons.credit_card_rounded,
                color: const Color(0xFF6366F1),
              ),
              _buildCategoryOption(
                ctx,
                category: ItemCategory.photoDocument,
                title: 'Photo & Document',
                subtitle: 'Attach photos, IDs, receipts saved encrypted',
                icon: Icons.photo_library_rounded,
                color: const Color(0xFFEC4899),
              ),
              _buildCategoryOption(
                ctx,
                category: ItemCategory.secureNote,
                title: 'Secure Note',
                subtitle: 'Encrypted multi-line notes, recovery codes & text',
                icon: Icons.note_alt_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryOption(
    BuildContext context, {
    required ItemCategory category,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: VaultTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditItemScreen(initialCategory: category),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: VaultTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: VaultTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: VaultTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _lockVault() {
    AuthService.instance.lock();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LockScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VaultProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: VaultTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: VaultTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Secure Vault'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded),
            tooltip: 'Lock Vault',
            onPressed: _lockVault,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search keys, cards, notes, or tags...',
                prefixIcon: const Icon(Icons.search_rounded, color: VaultTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearSearch();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Categories Horizontal Bar
          CategoryFilterChips(
            selectedCategory: provider.selectedCategory,
            showFavoritesOnly: provider.showFavoritesOnly,
            onCategorySelected: provider.setCategory,
            onToggleFavorites: provider.toggleFavoritesOnly,
          ),

          // Content List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.filteredItems.isEmpty
                    ? _buildEmptyState(provider)
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 80),
                        itemCount: provider.filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = provider.filteredItems[index];
                          return VaultItemCard(item: item);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategorySheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(VaultProvider provider) {
    final isSearching = provider.searchQuery.isNotEmpty ||
        provider.selectedCategory != null ||
        provider.showFavoritesOnly;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.lock_open_rounded,
              size: 64,
              color: VaultTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No matching items found' : 'Your vault is empty',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: VaultTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try searching with a different term or clear the filter.'
                  : 'Start adding your API keys, credit cards, or private photos securely.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: VaultTheme.textSecondary),
            ),
            if (isSearching) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  provider.clearSearch();
                  provider.setCategory(null);
                  if (provider.showFavoritesOnly) {
                    provider.toggleFavoritesOnly();
                  }
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
