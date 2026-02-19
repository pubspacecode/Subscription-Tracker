import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    required this.order,
  });

  factory CategoryModel.create({required String name, int order = 0}) {
    return CategoryModel(
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

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: j['id'] as String,
        name: j['name'] as String,
        order: j['order'] as int? ?? 0,
      );
}
