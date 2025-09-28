// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_value.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SensorValueAdapter extends TypeAdapter<SensorValue> {
  @override
  final int typeId = 1;

  @override
  SensorValue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorValue(
      timestamp: fields[0] as Duration,
      value: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SensorValue obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorValueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
