import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/vault_strings.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/vault_item_card.dart';
import 'add_edit_item_screen.dart';
import 'lock_screen.dart';
import 'settings_screen.dart';
import 'subscription_tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isArabic = false;

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

  void _showAddCategorySheet(BuildContext context, VaultStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.isArabic ? 'إضافة إلى الخزنة' : 'Add to your vault', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(s.isArabic ? 'اختر نوع البيانات التي تريد حفظها' : 'Choose what you want to keep protected', style: const TextStyle(color: VaultTheme.textSecondary)),
            const SizedBox(height: 20),
            _categoryOption(ctx, ItemCategory.apiKey, s.isArabic ? 'مفاتيح API والأسرار' : 'API keys & tokens', Icons.key_rounded, VaultTheme.primary),
            _categoryOption(ctx, ItemCategory.creditCard, s.isArabic ? 'البطاقات البنكية' : 'Bank cards', Icons.credit_card_rounded, const Color(0xFF818CF8)),
            _categoryOption(ctx, ItemCategory.secureNote, s.isArabic ? 'ملاحظات سرية' : 'Secure notes', Icons.sticky_note_2_rounded, const Color(0xFFFBBF24)),
            _categoryOption(ctx, ItemCategory.photoDocument, s.isArabic ? 'الصور والمستندات' : 'Photos & documents', Icons.folder_copy_rounded, const Color(0xFFF472B6)),
          ]),
        ),
      ),
    );
  }

  Widget _categoryOption(BuildContext context, ItemCategory category, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: VaultTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditItemScreen(initialCategory: category)));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color)),
              const SizedBox(width: 13),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: VaultTheme.textMuted),
            ]),
          ),
        ),
      ),
    );
  }

  void _lockVault() {
    AuthService.instance.lock();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockScreen()));
  }

  void _openSettings() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));

  void _openSubscriptions() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionTrackerScreen(isArabic: _isArabic),
        ),
      );

  Widget _statCard(String label, String value, IconData icon, Color tint) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: VaultTheme.surface, borderRadius: BorderRadius.circular(19), border: Border.all(color: VaultTheme.border.withOpacity(.7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: tint, size: 19),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -.8)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: VaultTheme.textSecondary, letterSpacing: .8, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _shortcut(String label, IconData icon, Color tint, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: VaultTheme.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
            child: Column(children: [
              Icon(icon, color: tint, size: 22),
              const SizedBox(height: 8),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _subscriptionShortcut(VaultStrings s) {
    return Material(
      color: VaultTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _openSubscriptions,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: VaultTheme.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: VaultTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.isArabic ? 'متابع الاشتراكات' : 'Subscription Tracker', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  s.isArabic ? 'تابع التجديدات قبل خصم الفيزا' : 'Stay ahead of renewals and card charges',
                  style: const TextStyle(fontSize: 10, color: VaultTheme.textSecondary),
                ),
              ],
            )),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: VaultTheme.textMuted),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VaultProvider>();
    final s = VaultStrings.of(context, _isArabic);
    final content = Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.greeting, style: const TextStyle(color: VaultTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(s.overview, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.6)),
            const SizedBox(height: 17),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF124B42), Color(0xFF12302F), Color(0xFF17243A)]),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: VaultTheme.primary.withOpacity(.25)),
                boxShadow: [BoxShadow(color: VaultTheme.primary.withOpacity(.08), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.verified_user_rounded, color: Color(0xFF6EE7B7), size: 15), const SizedBox(width: 6), Text(s.secureStorage, style: const TextStyle(color: Color(0xFFB6F3DC), fontSize: 11, fontWeight: FontWeight.w700))]),
                  const SizedBox(height: 13),
                  Text(s.isArabic ? 'كل أسرارك في مكان واحد' : 'Everything important.\nOne secure place.', style: const TextStyle(fontSize: 19, height: 1.25, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 13),
                  Text(s.isArabic ? 'بدون حسابات أو مزامنة سحابية' : 'Private by design • Offline first', style: const TextStyle(color: Color(0xFFB6C9C6), fontSize: 11)),
                ])),
                const SizedBox(width: 8),
                Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white.withOpacity(.09), shape: BoxShape.circle), child: const Icon(Icons.shield_moon_rounded, color: Color(0xFF6EE7B7), size: 31)),
              ]),
            ),
            const SizedBox(height: 13),
            Row(children: [
              _statCard(s.totalItems, provider.items.length.toString(), Icons.inventory_2_outlined, VaultTheme.primary),
              const SizedBox(width: 10),
              _statCard(s.favorites, provider.items.where((e) => e.isFavorite).length.toString(), Icons.star_rounded, const Color(0xFFFBBF24)),
            ]),
            const SizedBox(height: 20),
            Text(s.quickAccess, style: const TextStyle(fontSize: 11, letterSpacing: 1.1, color: VaultTheme.textSecondary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(children: [
              _shortcut(s.passwords, Icons.password_rounded, const Color(0xFF93C5FD), () => _showAddCategorySheet(context, s)),
              const SizedBox(width: 8),
              _shortcut(s.wifi, Icons.wifi_rounded, const Color(0xFFC4B5FD), () => _showAddCategorySheet(context, s)),
              const SizedBox(width: 8),
              _shortcut(s.security, Icons.security_rounded, VaultTheme.primary, _openSettings),
              const SizedBox(width: 8),
              _shortcut(s.backup, Icons.backup_rounded, const Color(0xFFFBBF24), _openSettings),
            ]),
            const SizedBox(height: 10),
            _subscriptionShortcut(s),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: TextField(
            controller: _searchController,
            onChanged: provider.setSearchQuery,
            decoration: InputDecoration(
              hintText: s.search,
              prefixIcon: const Icon(Icons.search_rounded, color: VaultTheme.textMuted),
              suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchController.clear(); provider.clearSearch(); setState(() {}); }) : null,
            ),
          ),
        ),
        CategoryFilterChips(selectedCategory: provider.selectedCategory, showFavoritesOnly: provider.showFavoritesOnly, onCategorySelected: provider.setCategory, onToggleFavorites: provider.toggleFavoritesOnly),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 8),
          child: Row(children: [Text(s.recent, style: const TextStyle(fontSize: 11, letterSpacing: 1.1, color: VaultTheme.textSecondary, fontWeight: FontWeight.w800)), const Spacer(), Text('${provider.filteredItems.length}', style: const TextStyle(color: VaultTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))]),
        ),
        Expanded(child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.filteredItems.isEmpty
            ? _buildEmptyState(provider, s)
            : ListView.builder(padding: const EdgeInsets.only(top: 2, bottom: 90), itemCount: provider.filteredItems.length, itemBuilder: (_, i) => VaultItemCard(item: provider.filteredItems[i]))),
      ]),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(gradient: const LinearGradient(colors: [VaultTheme.primary, Color(0xFF0E7490)]), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.shield_rounded, size: 20, color: Colors.white)),
          const SizedBox(width: 10),
          Text(s.appName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        actions: [
          TextButton(onPressed: () => setState(() => _isArabic = !_isArabic), child: Text(s.language, style: const TextStyle(color: VaultTheme.primary, fontWeight: FontWeight.w800))),
          IconButton(tooltip: s.settings, onPressed: _openSettings, icon: const Icon(Icons.tune_rounded)),
          IconButton(tooltip: s.lock, onPressed: _lockVault, icon: const Icon(Icons.lock_outline_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddCategorySheet(context, s), icon: const Icon(Icons.add_rounded), label: Text(s.addItem, style: const TextStyle(fontWeight: FontWeight.w800))),
    );
  }

  Widget _buildEmptyState(VaultProvider provider, VaultStrings s) {
    final filtered = provider.searchQuery.isNotEmpty || provider.selectedCategory != null || provider.showFavoritesOnly;
    return Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 76, height: 76, decoration: BoxDecoration(color: VaultTheme.primary.withOpacity(.10), shape: BoxShape.circle), child: Icon(filtered ? Icons.search_off_rounded : Icons.lock_open_rounded, size: 34, color: VaultTheme.primary)),
      const SizedBox(height: 15),
      Text(filtered ? s.noResults : s.noItems, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      Text(filtered ? (s.isArabic ? 'جرّب كلمة بحث أخرى أو امسح التصفية.' : 'Try another search or clear the filters.') : s.noItemsHint, textAlign: TextAlign.center, style: const TextStyle(color: VaultTheme.textSecondary, height: 1.5)),
      if (filtered) TextButton(onPressed: () { _searchController.clear(); provider.clearSearch(); provider.setCategory(null); if (provider.showFavoritesOnly) provider.toggleFavoritesOnly(); setState(() {}); }, child: Text(s.clearFilters)),
    ])));
  }
}
