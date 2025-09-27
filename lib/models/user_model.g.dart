// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      userId: fields[0] as int,
      gender: fields[1] as String,
      weight: fields[2] as double,
      height: fields[3] as double,
      tr1: fields[4] as int,
      tr2: fields[5] as int,
      tr3: fields[6] as int,
      threshold: fields[7] as double,
      reading: (fields[8] as List).cast<int>(),
      mfi: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.gender)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.tr1)
      ..writeByte(5)
      ..write(obj.tr2)
      ..writeByte(6)
      ..write(obj.tr3)
      ..writeByte(7)
      ..write(obj.threshold)
      ..writeByte(8)
      ..write(obj.reading)
      ..writeByte(9)
      ..write(obj.mfi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
