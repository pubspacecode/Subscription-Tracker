// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionAdapter extends TypeAdapter<Subscription> {
  @override
  final int typeId = 1;

  @override
  Subscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscription(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      currency: fields[3] as String,
      billingCycle: fields[4] as BillingCycle,
      nextRenewalDate: fields[5] as DateTime,
      category: fields[6] as String,
      isActive: fields[7] as bool,
      notes: fields[8] as String?,
      reminderEnabled: fields[9] as bool,
      createdAt: fields[10] as DateTime,
      url: fields[11] as String?,
      paymentMethod: fields[12] as String?,
      isFreeTrial: fields[13] as bool,
      listName: fields[14] as String?,
      iconCodePoint: fields[15] as int?,
      colorValue: fields[16] as int?,
      imagePath: fields[17] as String?,
      isDeleted: fields[18] as bool,
      recurrenceFrequency: fields[19] as int,
      recurrencePeriod: fields[20] as String,
      startDate: fields[21] as DateTime?,
      usageNotificationFrequency: fields[22] as String?,
      priceHistory: (fields[23] as List?)?.cast<PriceRecord>(),
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.billingCycle)
      ..writeByte(5)
      ..write(obj.nextRenewalDate)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.reminderEnabled)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.url)
      ..writeByte(12)
      ..write(obj.paymentMethod)
      ..writeByte(13)
      ..write(obj.isFreeTrial)
      ..writeByte(14)
      ..write(obj.listName)
      ..writeByte(15)
      ..write(obj.iconCodePoint)
      ..writeByte(16)
      ..write(obj.colorValue)
      ..writeByte(17)
      ..write(obj.imagePath)
      ..writeByte(18)
      ..write(obj.isDeleted)
      ..writeByte(19)
      ..write(obj.recurrenceFrequency)
      ..writeByte(20)
      ..write(obj.recurrencePeriod)
      ..writeByte(21)
      ..write(obj.startDate)
      ..writeByte(22)
      ..write(obj.usageNotificationFrequency)
      ..writeByte(23)
      ..write(obj.priceHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BillingCycleAdapter extends TypeAdapter<BillingCycle> {
  @override
  final int typeId = 0;

  @override
  BillingCycle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BillingCycle.weekly;
      case 1:
        return BillingCycle.monthly;
      case 2:
        return BillingCycle.yearly;
      default:
        return BillingCycle.weekly;
    }
  }

  @override
  void write(BinaryWriter writer, BillingCycle obj) {
    switch (obj) {
      case BillingCycle.weekly:
        writer.writeByte(0);
        break;
      case BillingCycle.monthly:
        writer.writeByte(1);
        break;
      case BillingCycle.yearly:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingCycleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
