import 'package:hive/hive.dart';

part 'sensor_value.g.dart';

@HiveType(typeId: 1) // unique across models
class SensorValue {
  @HiveField(0)
  final Duration timestamp;

  @HiveField(1)
  final double value;

  SensorValue({
    required this.timestamp,
    required this.value,
  });
}



class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 2; // unique ID, don’t reuse from other models

  @override
  Duration read(BinaryReader reader) {
    return Duration(milliseconds: reader.readInt()); // 👈 always int
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMilliseconds); // 👈 always int
  }
}


