// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_list_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionListAdapter extends TypeAdapter<SubscriptionList> {
  @override
  final int typeId = 4;

  @override
  SubscriptionList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionList(
      id: fields[0] as String,
      name: fields[1] as String,
      order: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionList obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
