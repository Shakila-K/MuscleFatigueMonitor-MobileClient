import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:muscle_fatigue_monitor/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  static const String _boxName = 'users';
  UserModel? _currentUser;

  /// Get the current user in memory
  UserModel? get user => _currentUser;

  /// Check if a user exists with given [userId]
  bool userExists(int userId) {
    final box = Hive.box<UserModel>(_boxName);
    return box.containsKey(userId);
  }

  /// Get all users
  List<UserModel> getAllUsers() {
    final box = Hive.box<UserModel>(_boxName);
    return box.values.toList();
  }

  /// Save a new user (with default values for training/threshold/reading)
  Future<void> addUser({
    required int userId,
    required String gender,
    required double weight,
    required double height,
    double? mfi,
  }) async {
    final box = Hive.box<UserModel>(_boxName);

    final user = UserModel(
      userId: userId,
      gender: gender,
      weight: weight,
      height: height,
      tr1: 0,
      tr2: 0,
      tr3: 0,
      threshold: 0.0,
      reading: [],
      mfi: mfi ?? 0.0,
    );

    await box.put(userId, user);
    _currentUser = user;
    notifyListeners();
  }

  /// Get a specific user by [userId]
  UserModel? getUser(int userId) {
    final box = Hive.box<UserModel>(_boxName);
    _currentUser = box.get(userId);
    notifyListeners();
    return _currentUser;
  }

  /// Update an existing user
  Future<void> updateUser(UserModel user) async {
    final box = Hive.box<UserModel>(_boxName);
    await box.put(user.userId, user);
    _currentUser = user;
    notifyListeners();
  }

  /// Update only specific fields of a user
  Future<void> updateUserFields(int userId, {
    String? gender,
    double? weight,
    double? height,
    int? tr1,
    int? tr2,
    int? tr3,
    double? threshold,
    List<int>? reading,
    double? mfi,
  }) async {
    final box = Hive.box<UserModel>(_boxName);
    final user = box.get(userId);

    if (user != null) {
      final updatedUser = UserModel(
        userId: user.userId,
        gender: gender ?? user.gender,
        weight: weight ?? user.weight,
        height: height ?? user.height,
        tr1: tr1 ?? user.tr1,
        tr2: tr2 ?? user.tr2,
        tr3: tr3 ?? user.tr3,
        threshold: threshold ?? user.threshold,
        reading: reading ?? user.reading,
        mfi: mfi ?? user.mfi,
      );

      await box.put(userId, updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    }
  }

  /// Check if _currentUser is set
  bool hasCurrentUser() {
    return _currentUser != null;
  }

  /// Optionally clear current user (logout-like behavior)
  void clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
  }

  /// Delete a user by userId
  Future<void> deleteUser(int userId) async {
    final box = Hive.box<UserModel>(_boxName);
    await box.delete(userId);

    // If the deleted user was the current user, clear it
    if (_currentUser?.userId == userId) {
      _currentUser = null;
    }

    notifyListeners();
  }
}
