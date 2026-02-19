// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-written adapter for MonthlySpendRecord (typeId: 7)

part of 'monthly_spend_record.dart';

class MonthlySpendRecordAdapter extends TypeAdapter<MonthlySpendRecord> {
  @override
  final int typeId = 7;

  @override
  MonthlySpendRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlySpendRecord(
      monthKey: fields[0] as String,
      totalSpend: fields[1] as double,
      recordedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlySpendRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.monthKey)
      ..writeByte(1)
      ..write(obj.totalSpend)
      ..writeByte(2)
      ..write(obj.recordedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlySpendRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
