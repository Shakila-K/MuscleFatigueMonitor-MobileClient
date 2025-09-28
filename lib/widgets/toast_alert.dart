import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/main.dart';
import 'package:toastification/toastification.dart';

void showToastSafe(String message, ToastificationType type) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;
  toastification.show(
    context: ctx,
    type: type,
    style: ToastificationStyle.fillColored,
    autoCloseDuration: const Duration(seconds: 3),
    alignment: Alignment.bottomCenter,
    title: Text(message),
  );
}