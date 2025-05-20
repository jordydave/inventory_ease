// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockLogModelAdapter extends TypeAdapter<StockLogModel> {
  @override
  final int typeId = 2;

  @override
  StockLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockLogModel(
      id: fields[0] as int,
      productId: fields[1] as int,
      change: fields[2] as int,
      timestamp: fields[3] as DateTime,
      note: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StockLogModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.change)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
