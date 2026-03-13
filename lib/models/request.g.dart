// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RequestItemAdapter extends TypeAdapter<RequestItem> {
  @override
  final int typeId = 0;

  @override
  RequestItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RequestItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      contractor: fields[3] as String,
      serviceType: fields[4] as String,
      durationLabel: fields[5] as String,
      revenue: fields[6] as double,
      cost: fields[7] as double,
      isDone: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RequestItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.contractor)
      ..writeByte(4)
      ..write(obj.serviceType)
      ..writeByte(5)
      ..write(obj.durationLabel)
      ..writeByte(6)
      ..write(obj.revenue)
      ..writeByte(7)
      ..write(obj.cost)
      ..writeByte(8)
      ..write(obj.isDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
