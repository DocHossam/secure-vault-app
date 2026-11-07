enum BillingCycle { weekly, monthly, quarterly, yearly }

enum SubscriptionCategory { streaming, productivity, cloudAi, utilities, work, other }

enum SubscriptionStatus { active, paused, cancelled }

class Subscription {
  final String id;
  final String name;
  final double amount;
  final String currency;
  final DateTime nextRenewalDate;
  final BillingCycle cycle;
  final SubscriptionCategory category;
  final SubscriptionStatus status;
  final bool autoRenew;
  final bool remindersEnabled;
  final List<int> reminderDays;
  final String? paymentMethod;
  final String? cardLastFour;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.nextRenewalDate,
    required this.cycle,
    required this.category,
    this.status = SubscriptionStatus.active,
    this.autoRenew = true,
    this.remindersEnabled = true,
    this.reminderDays = const [7, 3, 1],
    this.paymentMethod,
    this.cardLastFour,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == SubscriptionStatus.active;

  DateTime nextDueDate({DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var due = DateTime(nextRenewalDate.year, nextRenewalDate.month, nextRenewalDate.day);
    while (due.isBefore(today)) {
      due = _advance(due);
    }
    return due;
  }

  int daysUntilDue({DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextDueDate(reference: now).difference(today).inDays;
  }

  List<DateTime> upcomingRenewalDates({int count = 5, DateTime? reference}) {
    if (count <= 0) return const [];
    final dates = <DateTime>[];
    var due = nextDueDate(reference: reference);
    for (var i = 0; i < count; i++) {
      dates.add(due);
      due = _advance(due);
    }
    return dates;
  }

  DateTime _advance(DateTime date) {
    if (cycle == BillingCycle.weekly) {
      return date.add(const Duration(days: 7));
    }
    final months = switch (cycle) {
      BillingCycle.monthly => 1,
      BillingCycle.quarterly => 3,
      BillingCycle.yearly => 12,
      BillingCycle.weekly => 0,
    };
    final monthIndex = date.year * 12 + (date.month - 1) + months;
    final year = monthIndex ~/ 12;
    final month = (monthIndex % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final anchorDay = nextRenewalDate.day;
    return DateTime(year, month, anchorDay > lastDay ? lastDay : anchorDay);
  }

  Subscription copyWith({
    SubscriptionStatus? status,
    DateTime? nextRenewalDate,
    bool? remindersEnabled,
    List<int>? reminderDays,
    bool? autoRenew,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id,
      name: name,
      amount: amount,
      currency: currency,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
      cycle: cycle,
      category: category,
      status: status ?? this.status,
      autoRenew: autoRenew ?? this.autoRenew,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderDays: reminderDays ?? this.reminderDays,
      paymentMethod: paymentMethod,
      cardLastFour: cardLastFour,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'currency': currency,
        'nextRenewalDate': nextRenewalDate.toIso8601String(),
        'cycle': cycle.name,
        'category': category.name,
        'status': status.name,
        'autoRenew': autoRenew,
        'remindersEnabled': remindersEnabled,
        'reminderDays': reminderDays,
        'paymentMethod': paymentMethod,
        'cardLastFour': cardLastFour,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Subscription.fromMap(Map<String, dynamic> map) {
    T enumValue<T extends Enum>(List<T> values, dynamic raw, T fallback) {
      return values.firstWhere(
        (value) => value.name == raw,
        orElse: () => fallback,
      );
    }

    return Subscription(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Untitled subscription',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'EGP',
      nextRenewalDate:
          DateTime.tryParse(map['nextRenewalDate'] as String? ?? '') ?? DateTime.now(),
      cycle: enumValue(BillingCycle.values, map['cycle'], BillingCycle.monthly),
      category: enumValue(
        SubscriptionCategory.values,
        map['category'],
        SubscriptionCategory.other,
      ),
      status: enumValue(
        SubscriptionStatus.values,
        map['status'],
        SubscriptionStatus.active,
      ),
      autoRenew: map['autoRenew'] as bool? ?? true,
      remindersEnabled: map['remindersEnabled'] as bool? ?? true,
      reminderDays: (map['reminderDays'] as List<dynamic>? ?? const [7, 3, 1])
          .map((value) => (value as num).toInt())
          .where((value) => const [1, 3, 7, 14].contains(value))
          .toList(),
      paymentMethod: map['paymentMethod'] as String?,
      cardLastFour: map['cardLastFour'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
