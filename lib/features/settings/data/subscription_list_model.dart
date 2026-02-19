import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'subscription_list_model.g.dart';

@HiveType(typeId: 4)
class SubscriptionList extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int order;

  SubscriptionList({
    required this.id,
    required this.name,
    required this.order,
  });

  factory SubscriptionList.create({required String name, int order = 0}) {
    return SubscriptionList(
      id: const Uuid().v4(),
      name: name,
      order: order,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
      };

  factory SubscriptionList.fromJson(Map<String, dynamic> j) => SubscriptionList(
        id: j['id'] as String,
        name: j['name'] as String,
        order: j['order'] as int? ?? 0,
      );
}
