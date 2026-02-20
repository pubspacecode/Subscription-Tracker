import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'price_record.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 0)
enum BillingCycle {
  @HiveField(0)
  weekly,
  @HiveField(1)
  monthly,
  @HiveField(2)
  yearly,
}

@HiveType(typeId: 1)
class Subscription extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String currency;

  @HiveField(4)
  BillingCycle billingCycle;

  @HiveField(5)
  DateTime nextRenewalDate;

  @HiveField(6)
  String category;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  bool reminderEnabled;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  String? url;

  @HiveField(12)
  String? paymentMethod;

  @HiveField(13)
  bool isFreeTrial;

  @HiveField(14)
  String? listName;

  @HiveField(15)
  int? iconCodePoint;

  @HiveField(16)
  int? colorValue;

  @HiveField(17)
  String? imagePath;

  @HiveField(18)
  bool isDeleted;

  @HiveField(19)
  int recurrenceFrequency; // Default 1

  @HiveField(20)
  String recurrencePeriod; // 'Day', 'Week', 'Month', 'Year'

  @HiveField(21)
  DateTime? startDate;

  @HiveField(23)
  String? usageNotificationFrequency;

  @HiveField(24)
  int renewalReminderDays; // 0 for Same day, 1 for 1 day before, etc.

  @HiveField(25)
  List<PriceRecord>? priceHistory;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.nextRenewalDate,
    required this.category,
    this.isActive = true,
    this.notes,
    this.reminderEnabled = true,
    required this.createdAt,
    this.url,
    this.paymentMethod,
    this.isFreeTrial = false,
    this.listName,
    this.iconCodePoint,
    this.colorValue,
    this.imagePath,
    this.isDeleted = false,
    this.recurrenceFrequency = 1,
    this.recurrencePeriod = 'Month',
    this.startDate,
    this.usageNotificationFrequency,
    this.renewalReminderDays = 1, // Default to 1 day before
    this.priceHistory,
  });

  factory Subscription.create({
    required String name,
    required double amount,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime nextRenewalDate,
    required String category,
    String? notes,
    bool reminderEnabled = true,
    String? url,
    String? paymentMethod,
    bool isFreeTrial = false,
    String? listName,
    int? iconCodePoint,
    int? colorValue,
    String? imagePath,
    int recurrenceFrequency = 1,
    String recurrencePeriod = 'Month',
    DateTime? startDate,
    String? usageNotificationFrequency,
    int renewalReminderDays = 1,
    List<PriceRecord>? priceHistory,
  }) {
    return Subscription(
      id: const Uuid().v4(),
      name: name,
      amount: amount,
      currency: currency,
      billingCycle: billingCycle,
      nextRenewalDate: nextRenewalDate,
      category: category,
      notes: notes,
      reminderEnabled: reminderEnabled,
      createdAt: DateTime.now(),
      url: url,
      paymentMethod: paymentMethod,
      isFreeTrial: isFreeTrial,
      listName: listName,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      imagePath: imagePath,
      isDeleted: false,
      recurrenceFrequency: recurrenceFrequency,
      recurrencePeriod: recurrencePeriod,
      startDate: startDate,
      usageNotificationFrequency: usageNotificationFrequency,
      renewalReminderDays: renewalReminderDays,
      priceHistory: priceHistory,
    );
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'currency': currency,
        'billingCycle': billingCycle.index,
        'nextRenewalDate': nextRenewalDate.toIso8601String(),
        'category': category,
        'isActive': isActive,
        'notes': notes,
        'reminderEnabled': reminderEnabled,
        'createdAt': createdAt.toIso8601String(),
        'url': url,
        'paymentMethod': paymentMethod,
        'isFreeTrial': isFreeTrial,
        'listName': listName,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'imagePath': imagePath,
        'isDeleted': isDeleted,
        'recurrenceFrequency': recurrenceFrequency,
        'recurrencePeriod': recurrencePeriod,
        'startDate': startDate?.toIso8601String(),
        'usageNotificationFrequency': usageNotificationFrequency,
        'renewalReminderDays': renewalReminderDays,
        'priceHistory': priceHistory
            ?.map((p) => {'amount': p.amount, 'effectiveFrom': p.effectiveFrom.toIso8601String()})
            .toList(),
      };

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String,
        billingCycle: BillingCycle.values[j['billingCycle'] as int],
        nextRenewalDate: DateTime.parse(j['nextRenewalDate'] as String),
        category: j['category'] as String,
        isActive: j['isActive'] as bool? ?? true,
        notes: j['notes'] as String?,
        reminderEnabled: j['reminderEnabled'] as bool? ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
        url: j['url'] as String?,
        paymentMethod: j['paymentMethod'] as String?,
        isFreeTrial: j['isFreeTrial'] as bool? ?? false,
        listName: j['listName'] as String?,
        iconCodePoint: j['iconCodePoint'] as int?,
        colorValue: j['colorValue'] as int?,
        imagePath: j['imagePath'] as String?,
        isDeleted: j['isDeleted'] as bool? ?? false,
        recurrenceFrequency: j['recurrenceFrequency'] as int? ?? 1,
        recurrencePeriod: j['recurrencePeriod'] as String? ?? 'Month',
        startDate: j['startDate'] != null ? DateTime.parse(j['startDate'] as String) : null,
        usageNotificationFrequency: j['usageNotificationFrequency'] as String?,
        renewalReminderDays: j['renewalReminderDays'] as int? ?? 1,
        priceHistory: (j['priceHistory'] as List<dynamic>?)
            ?.map((p) => PriceRecord(
                  amount: (p['amount'] as num).toDouble(),
                  effectiveFrom: DateTime.parse(p['effectiveFrom'] as String),
                ))
            .toList(),
      );
}
