// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-written adapter for PriceRecord (typeId: 6)

part of 'price_record.dart';

class PriceRecordAdapter extends TypeAdapter<PriceRecord> {
  @override
  final int typeId = 6;

  @override
  PriceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceRecord(
      amount: fields[0] as double,
      effectiveFrom: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PriceRecord obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.effectiveFrom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
