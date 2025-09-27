import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0) // unique id for adapter
class UserModel extends HiveObject {
  @HiveField(0)
  int userId;

  @HiveField(1)
  String gender;

  @HiveField(2)
  double weight;

  @HiveField(3)
  double height;

  @HiveField(4)
  int tr1;

  @HiveField(5)
  int tr2;

  @HiveField(6)
  int tr3;

  @HiveField(7)
  double threshold;

  @HiveField(8)
  List<int> reading;

  @HiveField(9)
  double mfi;

  UserModel({
    required this.userId,
    required this.gender,
    required this.weight,
    required this.height,
    required this.tr1,
    required this.tr2,
    required this.tr3,
    required this.threshold,
    required this.reading,
    required this.mfi,
  });
}

