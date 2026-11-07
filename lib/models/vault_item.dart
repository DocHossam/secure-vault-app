import 'dart:convert';

enum ItemCategory {
  apiKey,
  creditCard,
  secureNote,
  photoDocument,
}

extension ItemCategoryExtension on ItemCategory {
  String get displayName {
    switch (this) {
      case ItemCategory.apiKey:
        return 'API Keys & Secrets';
      case ItemCategory.creditCard:
        return 'Credit & Debit Cards';
      case ItemCategory.secureNote:
        return 'Secure Notes';
      case ItemCategory.photoDocument:
        return 'Photos & Documents';
    }
  }

  String get displayNameAr {
    switch (this) {
      case ItemCategory.apiKey:
        return 'مفاتيح API وأسرار';
      case ItemCategory.creditCard:
        return 'بطاقات بنكية وفيزا';
      case ItemCategory.secureNote:
        return 'ملاحظات سرية';
      case ItemCategory.photoDocument:
        return 'صور ومستندات';
    }
  }

  String get iconName {
    switch (this) {
      case ItemCategory.apiKey:
        return 'vpn_key_rounded';
      case ItemCategory.creditCard:
        return 'credit_card_rounded';
      case ItemCategory.secureNote:
        return 'note_alt_rounded';
      case ItemCategory.photoDocument:
        return 'photo_library_rounded';
    }
  }
}

class VaultItem {
  final String id;
  final String title;
  final ItemCategory category;
  final String? secretValue; // Main API Key or Secret Token or Passphrase
  final String? secondarySecret; // Client Secret, Key ID, or Second Token
  final String? notes;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Credit Card Specific Fields
  final String? cardNumber;
  final String? cardHolder;
  final String? expiryDate; // MM/YY
  final String? cvv;
  final String? cardBrand; // Visa, Mastercard, Meeza, Amex, etc.
  final int cardColorIndex;

  // API Key Specific Fields
  final String? apiUrl;
  final String? environment; // Production, Staging, Dev

  // Photo & Document Attachments (Local storage paths)
  final List<String> imagePaths;

  VaultItem({
    required this.id,
    required this.title,
    required this.category,
    this.secretValue,
    this.secondarySecret,
    this.notes,
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.cardNumber,
    this.cardHolder,
    this.expiryDate,
    this.cvv,
    this.cardBrand,
    this.cardColorIndex = 0,
    this.apiUrl,
    this.environment,
    this.imagePaths = const [],
  });

  /// Get the primary copyable value when tapped from home list
  String get primaryCopyableValue {
    switch (category) {
      case ItemCategory.apiKey:
        return secretValue ?? '';
      case ItemCategory.creditCard:
        return (cardNumber ?? '').replaceAll(' ', '');
      case ItemCategory.secureNote:
        return notes ?? secretValue ?? '';
      case ItemCategory.photoDocument:
        return notes ?? title;
    }
  }

  /// Get subtitle or preview label for list tile
  String get displaySubtitle {
    switch (category) {
      case ItemCategory.apiKey:
        if (environment != null && environment!.isNotEmpty) {
          return '[$environment] ••••••••';
        }
        return '••••••••';
      case ItemCategory.creditCard:
        final cleanNumber = (cardNumber ?? '').replaceAll(' ', '');
        final last4 = cleanNumber.length >= 4
            ? cleanNumber.substring(cleanNumber.length - 4)
            : '••••';
        final brand = cardBrand ?? 'Card';
        return '$brand ending in $last4 | Exp: ${expiryDate ?? '--/--'}';
      case ItemCategory.secureNote:
        if (notes != null && notes!.isNotEmpty) {
          final firstLine = notes!.split('\n').first;
          return firstLine.length > 40 ? '${firstLine.substring(0, 40)}...' : firstLine;
        }
        return 'No notes preview';
      case ItemCategory.photoDocument:
        final count = imagePaths.length;
        return '$count ${count == 1 ? 'image' : 'images'} attached';
    }
  }

  VaultItem copyWith({
    String? id,
    String? title,
    ItemCategory? category,
    String? secretValue,
    String? secondarySecret,
    String? notes,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cardNumber,
    String? cardHolder,
    String? expiryDate,
    String? cvv,
    String? cardBrand,
    int? cardColorIndex,
    String? apiUrl,
    String? environment,
    List<String>? imagePaths,
  }) {
    return VaultItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      secretValue: secretValue ?? this.secretValue,
      secondarySecret: secondarySecret ?? this.secondarySecret,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      cardBrand: cardBrand ?? this.cardBrand,
      cardColorIndex: cardColorIndex ?? this.cardColorIndex,
      apiUrl: apiUrl ?? this.apiUrl,
      environment: environment ?? this.environment,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'secretValue': secretValue,
      'secondarySecret': secondarySecret,
      'notes': notes,
      'tags': tags,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardBrand': cardBrand,
      'cardColorIndex': cardColorIndex,
      'apiUrl': apiUrl,
      'environment': environment,
      'imagePaths': imagePaths,
    };
  }

  factory VaultItem.fromMap(Map<String, dynamic> map) {
    return VaultItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: ItemCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ItemCategory.apiKey,
      ),
      secretValue: map['secretValue'] as String?,
      secondarySecret: map['secondarySecret'] as String?,
      notes: map['notes'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      cardNumber: map['cardNumber'] as String?,
      cardHolder: map['cardHolder'] as String?,
      expiryDate: map['expiryDate'] as String?,
      cvv: map['cvv'] as String?,
      cardBrand: map['cardBrand'] as String?,
      cardColorIndex: map['cardColorIndex'] as int? ?? 0,
      apiUrl: map['apiUrl'] as String?,
      environment: map['environment'] as String?,
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory VaultItem.fromJson(String source) =>
      VaultItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
