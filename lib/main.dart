import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/screens/homepage.dart';
import 'package:muscle_fatigue_monitor/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runZonedGuarded(
    () {
      runApp(
        ChangeNotifierProvider(
          create: (_) => WebSocketProvider(),
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      print("🔥 Caught in runZonedGuarded:");
      print("Error: $error");
      print("Stack trace:\n$stack");
    },
  );
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Muscle Fatigue Monitor',
        navigatorKey: navigatorKey,
        home: const HomePage(),
        theme: ThemeData.dark(),
      ),
    );
  }
}