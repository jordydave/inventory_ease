import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int categoryId;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final double price;

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.quantity,
    required this.price,
  });

  ProductModel copyWith({
    int? id,
    String? name,
    double? price,
    int? quantity,
    int? categoryId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
