import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_notification_service.dart';
import '../utils/theme.dart';

class SubscriptionTrackerScreen extends StatefulWidget {
  final bool isArabic;

  const SubscriptionTrackerScreen({super.key, this.isArabic = false});

  @override
  State<SubscriptionTrackerScreen> createState() =>
      _SubscriptionTrackerScreenState();
}

class _SubscriptionTrackerScreenState extends State<SubscriptionTrackerScreen> {
  late bool _isArabic;

  String _t(String english, String arabic) => _isArabic ? arabic : english;

  @override
  void initState() {
    super.initState();
    _isArabic = widget.isArabic;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().load(isArabic: _isArabic);
    });
  }

  Future<void> _toggleLanguage() async {
    setState(() => _isArabic = !_isArabic);
    await context
        .read<SubscriptionProvider>()
        .load(isArabic: _isArabic);
  }

  Future<void> _openEditor([Subscription? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    final paymentController =
        TextEditingController(text: existing?.paymentMethod ?? '');
    final lastFourController =
        TextEditingController(text: existing?.cardLastFour ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    var renewalDate = existing?.nextDueDate() ??
        DateTime.now().add(const Duration(days: 30));
    var cycle = existing?.cycle ?? BillingCycle.monthly;
    var category = existing?.category ?? SubscriptionCategory.streaming;
    var currency = existing?.currency ?? 'EGP';
    var autoRenew = existing?.autoRenew ?? true;
    var remindersEnabled = existing?.remindersEnabled ?? true;
    var reminderDays = <int>{...(existing?.reminderDays ?? const [7, 3, 1])};

    final saved = await showModalBottomSheet<Subscription>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> chooseDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: renewalDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: VaultTheme.primary,
                        surface: VaultTheme.surface,
                      ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setSheetState(() {
                renewalDate = DateTime(picked.year, picked.month, picked.day);
              });
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? _t('Add subscription', 'إضافة اشتراك')
                          : _t('Edit subscription', 'تعديل الاشتراك'),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: _t('Service name', 'اسم الخدمة'),
                        hintText: 'Netflix, Spotify, ChatGPT...',
                        prefixIcon: const Icon(Icons.subscriptions_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: _t('Price', 'السعر'),
                              prefixIcon: const Icon(Icons.payments_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: currency,
                            decoration: InputDecoration(
                              labelText: _t('Currency', 'العملة'),
                            ),
                            items: const ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED']
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setSheetState(() => currency = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BillingCycle>(
                      value: cycle,
                      decoration: InputDecoration(
                        labelText: _t('Billing cycle', 'دورية الدفع'),
                        prefixIcon: const Icon(Icons.repeat_rounded),
                      ),
                      items: BillingCycle.values
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_cycleLabel(value)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setSheetState(() => cycle = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SubscriptionCategory>(
                      value: category,
                      decoration: InputDecoration(
                        labelText: _t('Category', 'التصنيف'),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: SubscriptionCategory.values
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_categoryLabel(value)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: VaultTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        leading: const Icon(
                          Icons.event_available_rounded,
                          color: VaultTheme.primary,
                        ),
                        title: Text(_t('Next renewal date', 'موعد التجديد القادم')),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(renewalDate),
                          style: const TextStyle(
                            color: VaultTheme.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        onTap: chooseDate,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paymentController,
                      decoration: InputDecoration(
                        labelText: _t(
                          'Payment method (optional)',
                          'وسيلة الدفع (اختياري)',
                        ),
                        hintText: _t('Visa, Mastercard, PayPal...', 'فيزا، ماستركارد، باي بال...'),
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastFourController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: _t(
                          'Card last 4 digits only (optional)',
                          'آخر 4 أرقام من البطاقة فقط (اختياري)',
                        ),
                        prefixIcon: const Icon(Icons.credit_card_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: _t('Notes (optional)', 'ملاحظات (اختياري)'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: autoRenew,
                      onChanged: (value) =>
                          setSheetState(() => autoRenew = value),
                      title: Text(_t('Auto-renew is enabled', 'التجديد التلقائي مفعّل')),
                      subtitle: Text(
                        _t('The provider may charge your payment method automatically.',
                            'قد تخصم الخدمة قيمة التجديد تلقائيًا.'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: VaultTheme.textSecondary,
                        ),
                      ),
                      activeColor: VaultTheme.primary,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: remindersEnabled,
                      onChanged: (value) =>
                          setSheetState(() => remindersEnabled = value),
                      title: Text(_t('Renewal notifications', 'تنبيهات التجديد')),
                      activeColor: VaultTheme.primary,
                    ),
                    if (remindersEnabled) ...[
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _t('Remind me before renewal', 'نبّهني قبل التجديد'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: VaultTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [1, 3, 7, 14].map((days) {
                          final selected = reminderDays.contains(days);
                          return FilterChip(
                            label: Text(
                              _isArabic ? 'قبل $days يوم' : '$days day(s) before',
                            ),
                            selected: selected,
                            onSelected: (value) {
                              setSheetState(() {
                                if (value) {
                                  reminderDays.add(days);
                                } else {
                                  reminderDays.remove(days);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded),
                        label: Text(_t('Save subscription', 'حفظ الاشتراك')),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final amount = double.tryParse(
                            amountController.text.trim().replaceAll(',', '.'),
                          );
                          final lastFour = lastFourController.text.trim();
                          if (name.isEmpty || amount == null || amount <= 0) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(_t(
                                  'Enter a service name and a valid price.',
                                  'اكتب اسم الخدمة وسعرًا صحيحًا.',
                                )),
                              ),
                            );
                            return;
                          }
                          if (lastFour.isNotEmpty &&
                              !RegExp(r'^\d{4}$').hasMatch(lastFour)) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(_t(
                                  'Enter exactly 4 card digits, or leave it empty.',
                                  'اكتب آخر 4 أرقام فقط أو اترك الحقل فارغًا.',
                                )),
                              ),
                            );
                            return;
                          }
                          if (remindersEnabled && reminderDays.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(_t(
                                  'Choose at least one reminder day.',
                                  'اختر يوم تنبيه واحدًا على الأقل.',
                                )),
                              ),
                            );
                            return;
                          }
                          final now = DateTime.now();
                          final subscription = Subscription(
                            id: existing?.id ?? const Uuid().v4(),
                            name: name,
                            amount: amount,
                            currency: currency,
                            nextRenewalDate: renewalDate,
                            cycle: cycle,
                            category: category,
                            status: existing?.status ??
                                SubscriptionStatus.active,
                            autoRenew: autoRenew,
                            remindersEnabled: remindersEnabled,
                            reminderDays: reminderDays.toList()
                              ..sort((a, b) => b.compareTo(a)),
                            paymentMethod:
                                paymentController.text.trim().isEmpty
                                    ? null
                                    : paymentController.text.trim(),
                            cardLastFour:
                                lastFour.isEmpty ? null : lastFour,
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            createdAt: existing?.createdAt ?? now,
                            updatedAt: now,
                          );
                          Navigator.pop(sheetContext, subscription);
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        'Never enter your full card number, expiry date or CVV.',
                        'لا تدخل رقم البطاقة كاملًا أو تاريخ الانتهاء أو CVV.',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: VaultTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    nameController.dispose();
    amountController.dispose();
    paymentController.dispose();
    lastFourController.dispose();
    notesController.dispose();

    if (saved == null || !mounted) return;

    if (saved.remindersEnabled) {
      final granted =
          await SubscriptionNotificationService.instance.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(
              'Subscription saved, but notification permission is off. Enable notifications in system settings.',
              'تم حفظ الاشتراك، لكن إذن التنبيهات غير مفعّل. فعّله من إعدادات الجهاز.',
            )),
          ),
        );
      }
    }

    await context
        .read<SubscriptionProvider>()
        .saveSubscription(saved, isArabic: _isArabic);
  }

  String _cycleLabel(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return _t('Weekly', 'أسبوعي');
      case BillingCycle.monthly:
        return _t('Monthly', 'شهري');
      case BillingCycle.quarterly:
        return _t('Every 3 months', 'كل 3 شهور');
      case BillingCycle.yearly:
        return _t('Yearly', 'سنوي');
    }
  }

  String _categoryLabel(SubscriptionCategory category) {
    switch (category) {
      case SubscriptionCategory.streaming:
        return _t('Streaming', 'ترفيه وبث');
      case SubscriptionCategory.productivity:
        return _t('Productivity', 'إنتاجية وبرامج');
      case SubscriptionCategory.cloudAi:
        return _t('Cloud & AI', 'سحابة وذكاء اصطناعي');
      case SubscriptionCategory.utilities:
        return _t('Utilities', 'خدمات');
      case SubscriptionCategory.work:
        return _t('Work', 'عمل');
      case SubscriptionCategory.other:
        return _t('Other', 'أخرى');
    }
  }

  Future<void> _confirmDelete(Subscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VaultTheme.surface,
        title: Text(_t('Delete subscription?', 'حذف الاشتراك؟')),
        content: Text(_t(
          'This removes the saved entry and its scheduled reminders.',
          'سيتم حذف بيانات الاشتراك والتنبيهات المجدولة الخاصة به.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('Keep', 'إلغاء')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _t('Delete', 'حذف'),
              style: const TextStyle(color: VaultTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context
          .read<SubscriptionProvider>()
          .deleteSubscription(subscription.id);
    }
  }

  Future<void> _changeStatus(
    Subscription subscription,
    SubscriptionStatus status,
  ) async {
    await context.read<SubscriptionProvider>().updateStatus(
          subscription,
          status,
          isArabic: _isArabic,
        );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VaultTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VaultTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: VaultTheme.primary, size: 19),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: VaultTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subscriptionCard(Subscription subscription) {
    final due = subscription.nextDueDate();
    final days = subscription.daysUntilDue();
    final isCancelled = subscription.status == SubscriptionStatus.cancelled;
    final isPaused = subscription.status == SubscriptionStatus.paused;
    final dateText = DateFormat('dd/MM/yyyy').format(due);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: VaultTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VaultTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: VaultTheme.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  subscription.name.isEmpty
                      ? '?'
                      : subscription.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: VaultTheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _categoryLabel(subscription.category),
                      style: const TextStyle(
                        color: VaultTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${subscription.amount.toStringAsFixed(2)} ${subscription.currency}',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(height: 1, color: VaultTheme.border),
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(
                Icons.event_repeat_rounded,
                size: 16,
                color: VaultTheme.textSecondary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${_t('Next renewal', 'التجديد القادم')}: $dateText',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                isCancelled
                    ? _t('Cancelled', 'ملغي')
                    : isPaused
                        ? _t('Paused', 'متوقف مؤقتًا')
                        : days == 0
                            ? _t('Today', 'اليوم')
                            : _t('In $days days', 'خلال $days يوم'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: days <= 7 && !isCancelled && !isPaused
                      ? VaultTheme.warning
                      : VaultTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(
                subscription.autoRenew
                    ? Icons.autorenew_rounded
                    : Icons.block_rounded,
                color: subscription.autoRenew
                    ? VaultTheme.accent
                    : VaultTheme.textMuted,
                size: 15,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  subscription.autoRenew
                      ? _t('Auto-renew on', 'التجديد التلقائي مفعّل')
                      : _t('Auto-renew off', 'التجديد التلقائي متوقف'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: VaultTheme.textSecondary,
                  ),
                ),
              ),
              if (subscription.cardLastFour != null)
                Text(
                  '${subscription.paymentMethod ?? _t('Card', 'بطاقة')} •••• ${subscription.cardLastFour}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: VaultTheme.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _openEditor(subscription),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(_t('Edit', 'تعديل')),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _changeStatus(
                    subscription,
                    isPaused
                        ? SubscriptionStatus.active
                        : SubscriptionStatus.paused,
                  ),
                  icon: Icon(
                    isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isPaused ? _t('Resume', 'استئناف') : _t('Pause', 'إيقاف مؤقت'),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: VaultTheme.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'cancel') {
                    _changeStatus(subscription, SubscriptionStatus.cancelled);
                  } else if (value == 'delete') {
                    _confirmDelete(subscription);
                  } else if (value == 'active') {
                    _changeStatus(subscription, SubscriptionStatus.active);
                  }
                },
                itemBuilder: (context) => [
                  if (!isCancelled)
                    PopupMenuItem(
                      value: 'cancel',
                      child: Text(_t('Mark as cancelled', 'تحديد كملغي')),
                    ),
                  if (isCancelled)
                    PopupMenuItem(
                      value: 'active',
                      child: Text(_t('Reactivate', 'إعادة تفعيل')),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(_t('Delete entry', 'حذف السجل')),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final active = provider.activeSubscriptions;
    final dueSoon = provider.upcomingSubscriptions.length;

    return Directionality(
      textDirection: _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t('Subscription Tracker', 'متابع الاشتراكات')),
          actions: [
            TextButton(
              onPressed: _toggleLanguage,
              child: Text(
                _isArabic ? 'EN' : 'ع',
                style: const TextStyle(
                  color: VaultTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add_rounded),
          label: Text(_t('Add subscription', 'إضافة اشتراك')),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => provider.load(isArabic: _isArabic),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF124B42),
                            Color(0xFF12302F),
                            Color(0xFF17243A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Color(0xFF6EE7B7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _t('RENEWAL CONTROL', 'إدارة التجديدات'),
                                style: const TextStyle(
                                  color: Color(0xFFB6F3DC),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _t(
                              'Know before you get charged.',
                              'اعرف موعد الخصم قبل ما يحصل.',
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _t(
                              'Keep every recurring payment and renewal date in one place.',
                              'اجمع كل اشتراكاتك ومواعيد تجديدها في مكان واحد.',
                            ),
                            style: const TextStyle(
                              color: Color(0xFFD1E4DF),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 17),
                          Row(
                            children: [
                              _summaryCard(
                                _t('Active', 'نشطة'),
                                active.length.toString(),
                                Icons.verified_outlined,
                              ),
                              const SizedBox(width: 10),
                              _summaryCard(
                                _t('Due within 30 days', 'مستحقة خلال 30 يوم'),
                                dueSoon.toString(),
                                Icons.notifications_active_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VaultTheme.warning.withOpacity(.09),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: VaultTheme.warning.withOpacity(.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: VaultTheme.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              _t(
                                'Reminders help you act in time; Secure Vault cannot cancel a subscription or stop a card charge for you.',
                                'التنبيهات بتفكّرك في الوقت المناسب؛ التطبيق لا يلغي الاشتراك ولا يوقف خصم الفيزا تلقائيًا.',
                              ),
                              style: const TextStyle(
                                color: VaultTheme.textSecondary,
                                fontSize: 11,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _t('Your subscriptions', 'اشتراكاتك'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          provider.subscriptions.length.toString(),
                          style: const TextStyle(
                            color: VaultTheme.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    if (provider.subscriptions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: VaultTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: VaultTheme.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_note_rounded,
                              color: VaultTheme.primary,
                              size: 38,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _t('No subscriptions yet', 'لا توجد اشتراكات حتى الآن'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _t(
                                'Add a service to start tracking renewals and reminders.',
                                'أضف خدمة لبدء متابعة التجديدات والتنبيهات.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: VaultTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...provider.subscriptions.map(_subscriptionCard),
                  ],
                ),
              ),
      ),
    );
  }
}
