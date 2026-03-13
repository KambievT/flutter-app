// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contractor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContractorAdapter extends TypeAdapter<Contractor> {
  @override
  final int typeId = 1;

  @override
  Contractor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Contractor(
      name: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Contractor obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContractorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
