import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  CategoryModel({required this.id, required this.name});

  CategoryModel copyWith({int? id, String? name}) {
    return CategoryModel(id: id ?? this.id, name: name ?? this.name);
  }
}
