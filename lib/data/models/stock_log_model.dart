import 'package:hive/hive.dart';

part 'stock_log_model.g.dart';

@HiveType(typeId: 2)
class StockLogModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int productId;

  @HiveField(2)
  final int change; // Positive for stock-in, negative for stock-out

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String note;

  StockLogModel({
    required this.id,
    required this.productId,
    required this.change,
    required this.timestamp,
    required this.note,
  });

  StockLogModel copyWith({
    int? id,
    int? productId,
    int? change,
    DateTime? timestamp,
    String? note,
  }) {
    return StockLogModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      change: change ?? this.change,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }
}
