import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/subscriptions/data/service_model.dart';
import '../../features/subscriptions/data/subscription_model.dart';
import '../../features/subscriptions/data/price_record.dart';
import '../../features/analytics/data/monthly_spend_record.dart';
import '../constants/default_services.dart';
import '../../features/settings/data/subscription_list_model.dart';
import '../../features/settings/data/category_model.dart';
import '../../features/settings/data/payment_method_model.dart';

class HiveService {
  static const String subscriptionBoxName = 'subscriptions_v1';
  static const String settingsBoxName = 'settings_v1';
  static const String servicesBoxName = 'services_v1';
  static const String listsBoxName = 'subscription_lists_v1';
  static const String categoriesBoxName = 'categories_v1';
  static const String paymentMethodsBoxName = 'payment_methods_v1';
  static const String spendHistoryBoxName = 'spend_history_v1';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    Hive.registerAdapter(SubscriptionAdapter());
    Hive.registerAdapter(BillingCycleAdapter());
    Hive.registerAdapter(ServiceModelAdapter());
    Hive.registerAdapter(SubscriptionListAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(PaymentMethodAdapter());
    Hive.registerAdapter(PriceRecordAdapter());
    Hive.registerAdapter(MonthlySpendRecordAdapter());

    // Open Boxes
    await Hive.openBox<Subscription>(subscriptionBoxName);
    await Hive.openBox(settingsBoxName);
    final servicesBox = await Hive.openBox<ServiceModel>(servicesBoxName);
    final listsBox = await Hive.openBox<SubscriptionList>(listsBoxName);
    final categoriesBox = await Hive.openBox<CategoryModel>(categoriesBoxName);
    await Hive.openBox<PaymentMethod>(paymentMethodsBoxName);
    await Hive.openBox<MonthlySpendRecord>(spendHistoryBoxName);

    // Seed Services if empty
    if (servicesBox.isEmpty) {
      await servicesBox.addAll(DefaultServices.list);
    }

    // Seed Lists if empty
    if (listsBox.isEmpty) {
      await listsBox.addAll([
        SubscriptionList.create(name: 'Personal', order: 0),
        SubscriptionList.create(name: 'Family', order: 1),
        SubscriptionList.create(name: 'Business', order: 2),
      ]);
    }

    // Seed Categories if empty
    if (categoriesBox.isEmpty) {
      await categoriesBox.addAll([
        CategoryModel.create(name: 'Streaming', order: 0),
        CategoryModel.create(name: 'Music', order: 1),
        CategoryModel.create(name: 'Gaming', order: 2),
        CategoryModel.create(name: 'Utilities', order: 3),
        CategoryModel.create(name: 'Other', order: 4),
      ]);
    }
  }

  static Box<Subscription> get subscriptionBox =>
      Hive.box<Subscription>(subscriptionBoxName);

  static Box<ServiceModel> get servicesBox =>
      Hive.box<ServiceModel>(servicesBoxName);
  
  static Box<SubscriptionList> get listsBox =>
      Hive.box<SubscriptionList>(listsBoxName);

  static Box<CategoryModel> get categoriesBox =>
      Hive.box<CategoryModel>(categoriesBoxName);

  static Box<PaymentMethod> get paymentMethodsBox =>
      Hive.box<PaymentMethod>(paymentMethodsBoxName);

  static Box get settingsBox => Hive.box(settingsBoxName);

  static Box<MonthlySpendRecord> get spendHistoryBox =>
      Hive.box<MonthlySpendRecord>(spendHistoryBoxName);
}
