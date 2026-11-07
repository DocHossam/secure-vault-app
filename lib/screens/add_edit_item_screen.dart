import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/credit_card_widget.dart';

class AddEditItemScreen extends StatefulWidget {
  final VaultItem? itemToEdit;
  final ItemCategory? initialCategory;

  const AddEditItemScreen({
    super.key,
    this.itemToEdit,
    this.initialCategory,
  });

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late ItemCategory _category;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _tagsController;

  // API Key Controllers
  late TextEditingController _secretValueController;
  late TextEditingController _secondarySecretController;
  late TextEditingController _apiUrlController;
  String _environment = 'Production';

  // Credit Card Controllers
  late TextEditingController _cardNumberController;
  late TextEditingController _cardHolderController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;
  int _cardColorIndex = 0;

  // Attached images
  List<String> _imagePaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _category = item?.category ?? widget.initialCategory ?? ItemCategory.apiKey;

    _titleController = TextEditingController(text: item?.title ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _tagsController = TextEditingController(text: item?.tags.join(', ') ?? '');

    _secretValueController = TextEditingController(text: item?.secretValue ?? '');
    _secondarySecretController = TextEditingController(text: item?.secondarySecret ?? '');
    _apiUrlController = TextEditingController(text: item?.apiUrl ?? '');
    _environment = item?.environment ?? 'Production';

    _cardNumberController = TextEditingController(text: item?.cardNumber ?? '');
    _cardHolderController = TextEditingController(text: item?.cardHolder ?? '');
    _expiryController = TextEditingController(text: item?.expiryDate ?? '');
    _cvvController = TextEditingController(text: item?.cvv ?? '');
    _cardColorIndex = item?.cardColorIndex ?? 0;

    _imagePaths = List.from(item?.imagePaths ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _secretValueController.dispose();
    _secondarySecretController.dispose();
    _apiUrlController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null) {
        setState(() => _isSaving = true);
        final savedPath = await StorageService.instance.saveImageAttachment(File(picked.path));
        setState(() {
          _imagePaths.add(savedPath);
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = Provider.of<VaultProvider>(context, listen: false);

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final now = DateTime.now();

    final cardBrand = _category == ItemCategory.creditCard
        ? CardBrandHelper.detectBrand(_cardNumberController.text)
        : null;

    final item = VaultItem(
      id: widget.itemToEdit?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      category: _category,
      secretValue: _secretValueController.text.trim().isEmpty ? null : _secretValueController.text.trim(),
      secondarySecret: _secondarySecretController.text.trim().isEmpty ? null : _secondarySecretController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      tags: tags,
      isFavorite: widget.itemToEdit?.isFavorite ?? false,
      createdAt: widget.itemToEdit?.createdAt ?? now,
      updatedAt: now,
      cardNumber: _cardNumberController.text.trim().isEmpty ? null : _cardNumberController.text.trim(),
      cardHolder: _cardHolderController.text.trim().isEmpty ? null : _cardHolderController.text.trim(),
      expiryDate: _expiryController.text.trim().isEmpty ? null : _expiryController.text.trim(),
      cvv: _cvvController.text.trim().isEmpty ? null : _cvvController.text.trim(),
      cardBrand: cardBrand,
      cardColorIndex: _cardColorIndex,
      apiUrl: _apiUrlController.text.trim().isEmpty ? null : _apiUrlController.text.trim(),
      environment: _category == ItemCategory.apiKey ? _environment : null,
      imagePaths: _imagePaths,
    );

    if (widget.itemToEdit == null) {
      await provider.addItem(item);
    } else {
      await provider.updateItem(item);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'New Vault Item'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded, color: VaultTheme.primary),
              label: const Text('Save', style: TextStyle(color: VaultTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Selector
            const Text('CATEGORY', style: TextStyle(color: VaultTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: VaultTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VaultTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ItemCategory>(
                  value: _category,
                  isExpanded: true,
                  dropdownColor: VaultTheme.surface,
                  items: ItemCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.displayName, style: const TextStyle(color: VaultTheme.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    if (cat != null) setState(() => _category = cat);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _category == ItemCategory.creditCard
                    ? 'Card Label / Bank (e.g. NBE Platinum Visa)'
                    : _category == ItemCategory.apiKey
                        ? 'Key Name (e.g. OpenAI Production Key)'
                        : 'Title',
                prefixIcon: const Icon(Icons.title_rounded, color: VaultTheme.textMuted),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------
            // Specific Form: CREDIT CARD
            // ----------------------------------------------------
            if (_category == ItemCategory.creditCard) ...[
              // Live Interactive Card Preview
              CreditCardWidget(
                item: VaultItem(
                  id: 'preview',
                  title: _titleController.text.isEmpty ? 'BANK NAME' : _titleController.text,
                  category: ItemCategory.creditCard,
                  cardNumber: _cardNumberController.text.isEmpty ? '•••• •••• •••• ••••' : _cardNumberController.text,
                  cardHolder: _cardHolderController.text.isEmpty ? 'CARDHOLDER NAME' : _cardHolderController.text,
                  expiryDate: _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text,
                  cvv: _cvvController.text.isEmpty ? '•••' : _cvvController.text,
                  cardColorIndex: _cardColorIndex,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
                isInteractive: false,
              ),
              const SizedBox(height: 12),

              // Gradient Selector
              const Text('CARD THEME', style: TextStyle(color: VaultTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: VaultTheme.cardGradients.length,
                  itemBuilder: (ctx, idx) {
                    final isSel = _cardColorIndex == idx;
                    return GestureDetector(
                      onTap: () => setState(() => _cardColorIndex = idx),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: VaultTheme.cardGradients[idx]),
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: isSel ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Card Number
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [CardNumberInputFormatter()],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '4000 1234 5678 9010',
                  prefixIcon: Icon(Icons.credit_card_rounded, color: VaultTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),

              // Card Holder
              TextFormField(
                controller: _cardHolderController,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'AHMED MOHAMED',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: VaultTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),

              // Expiry & CVV Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CardExpiryInputFormatter()],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        prefixIcon: Icon(Icons.calendar_today_rounded, color: VaultTheme.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        counterText: '',
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: VaultTheme.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ----------------------------------------------------
            // Specific Form: API KEYS & SECRETS
            // ----------------------------------------------------
            if (_category == ItemCategory.apiKey) ...[
              // Environment Selector
              Row(
                children: ['Production', 'Staging', 'Development'].map((env) {
                  final isSelected = _environment == env;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _environment = env),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? VaultTheme.primary.withOpacity(0.18) : VaultTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? VaultTheme.primary : VaultTheme.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          env,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? VaultTheme.primary : VaultTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Secret Value (The API Key)
              TextFormField(
                controller: _secretValueController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'API Key / Secret Token',
                  hintText: 'sk-proj-... or bearer token',
                  prefixIcon: Icon(Icons.key_rounded, color: VaultTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Secret
              TextFormField(
                controller: _secondarySecretController,
                decoration: const InputDecoration(
                  labelText: 'Client Secret / Key ID (Optional)',
                  hintText: 'Client Secret or Key ID',
                  prefixIcon: Icon(Icons.password_rounded, color: VaultTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),

              // API Endpoint
              TextFormField(
                controller: _apiUrlController,
                decoration: const InputDecoration(
                  labelText: 'API Endpoint / Documentation URL (Optional)',
                  hintText: 'https://api.openai.com/v1',
                  prefixIcon: Icon(Icons.link_rounded, color: VaultTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ----------------------------------------------------
            // Specific Form: PHOTOS & ATTACHMENTS
            // ----------------------------------------------------
            const Text('ATTACHED PHOTOS & DOCUMENTS', style: TextStyle(color: VaultTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._imagePaths.map((path) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: VaultTheme.surfaceLight,
                          child: FutureBuilder(
                            future: StorageService.instance.getImageBytes(path),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                return Image.memory(snapshot.data!, fit: BoxFit.cover);
                              }
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _imagePaths.remove(path)),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                // Add from Camera
                InkWell(
                  onTap: () => _pickImage(ImageSource.camera),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: VaultTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VaultTheme.border, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: VaultTheme.primary, size: 22),
                        SizedBox(height: 4),
                        Text('Camera', style: TextStyle(fontSize: 10, color: VaultTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
                // Add from Gallery
                InkWell(
                  onTap: () => _pickImage(ImageSource.gallery),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: VaultTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VaultTheme.border, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, color: VaultTheme.accent, size: 22),
                        SizedBox(height: 4),
                        Text('Gallery', style: TextStyle(fontSize: 10, color: VaultTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notes field
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes & Extra Details',
                hintText: 'Write any confidential notes, recovery phrases or instructions...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Tags field
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (separated by comma)',
                hintText: 'work, personal, dev, bank, egypt',
                prefixIcon: Icon(Icons.tag_rounded, color: VaultTheme.textMuted),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text(isEditing ? 'Save Changes' : 'Add to Vault'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
