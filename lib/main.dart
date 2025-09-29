import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muscle_fatigue_monitor/models/sensor_value.dart';
import 'package:muscle_fatigue_monitor/models/user_model.dart';
import 'package:muscle_fatigue_monitor/screens/homepage.dart';
import 'package:muscle_fatigue_monitor/services/user_provider.dart';
import 'package:muscle_fatigue_monitor/services/websocket_provider.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async{

  runZonedGuarded(
    () async{

      WidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();
      Hive.registerAdapter(UserModelAdapter());
      Hive.registerAdapter(SensorValueAdapter()); 
      Hive.registerAdapter(DurationAdapter());

      // await Hive.deleteFromDisk();

      await Hive.openBox<UserModel>('users');

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };

      runApp(
        MultiProvider(
          providers: [
              ChangeNotifierProvider( create: (_) => WebSocketProvider()),
              ChangeNotifierProvider(create: (_) => UserProvider()),
            ],
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
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}