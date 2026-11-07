import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_item.dart';
import '../services/storage_service.dart';
import '../services/clipboard_service.dart';

class VaultProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  List<VaultItem> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ItemCategory? _selectedCategory; // null = all
  bool _showFavoritesOnly = false;

  List<VaultItem> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ItemCategory? get selectedCategory => _selectedCategory;
  bool get showFavoritesOnly => _showFavoritesOnly;

  /// Filtered items based on search query, category, and favorite toggle
  List<VaultItem> get filteredItems {
    return _items.where((item) {
      // Category filter
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }

      // Favorite filter
      if (_showFavoritesOnly && !item.isFavorite) {
        return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final titleMatch = item.title.toLowerCase().contains(query);
        final notesMatch = (item.notes ?? '').toLowerCase().contains(query);
        final tagsMatch = item.tags.any((t) => t.toLowerCase().contains(query));
        final cardHolderMatch = (item.cardHolder ?? '').toLowerCase().contains(query);
        final cardBrandMatch = (item.cardBrand ?? '').toLowerCase().contains(query);
        final apiMatch = (item.apiUrl ?? '').toLowerCase().contains(query);
        final envMatch = (item.environment ?? '').toLowerCase().contains(query);
        
        // Match last 4 card digits
        final cleanCard = (item.cardNumber ?? '').replaceAll(' ', '');
        final cardMatch = cleanCard.contains(query);

        if (!titleMatch &&
            !notesMatch &&
            !tagsMatch &&
            !cardHolderMatch &&
            !cardBrandMatch &&
            !apiMatch &&
            !envMatch &&
            !cardMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Initialize and load items from encrypted local storage
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    _items = _storage.getAllItems();
    _isLoading = false;
    notifyListeners();
  }

  /// Add a new item
  Future<void> addItem(VaultItem item) async {
    await _storage.saveItem(item);
    _items.insert(0, item);
    notifyListeners();
  }

  /// Update an existing item
  Future<void> updateItem(VaultItem item) async {
    await _storage.saveItem(item);
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
    }
  }

  /// Delete an item
  Future<void> deleteItem(String id) async {
    await _storage.deleteItem(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = _items[index].copyWith(
        isFavorite: !_items[index].isFavorite,
        updatedAt: DateTime.now(),
      );
      await _storage.saveItem(updated);
      _items[index] = updated;
      notifyListeners();
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search query
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Filter by category
  void setCategory(ItemCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Toggle favorite only view
  void toggleFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListeners();
  }

  /// One-Tap copy with instant snackbar & haptic feedback
  Future<void> copyItemValue(BuildContext context, VaultItem item, {String? customValue, String? label}) async {
    final valueToCopy = customValue ?? item.primaryCopyableValue;
    if (valueToCopy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No value to copy!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await ClipboardService.instance.copyToClipboard(valueToCopy);

    final displayLabel = label ?? (item.category == ItemCategory.apiKey ? 'API Key' : item.title);
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Copied $displayLabel to clipboard! (Auto-clears in 30s)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
