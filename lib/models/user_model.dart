import 'package:hive/hive.dart';
import 'sensor_value.dart'; // make sure SensorValue is Hive-compatible too

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String gender;

  @HiveField(2)
  int age;

  @HiveField(3)
  double weight;

  @HiveField(4)
  double height;

  /// Final baseline threshold (average MFI)
  @HiveField(5)
  double threshold;

  /// Raw EMG signal (timestamp + value pairs)
  @HiveField(6)
  List<SensorValue> readings;

  /// Computed MFI values per window
  @HiveField(7)
  List<SensorValue> mfSeries;


  UserModel({
    required this.userId,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.readings,
    required this.mfSeries,
    required this.threshold,
  });
}
