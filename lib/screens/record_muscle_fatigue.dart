import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';
import 'package:muscle_fatigue_monitor/consts/screen_size.dart';
import 'package:muscle_fatigue_monitor/models/sensor_value.dart';
import 'package:muscle_fatigue_monitor/services/calculations.dart';
import 'package:muscle_fatigue_monitor/services/user_provider.dart';
import 'package:muscle_fatigue_monitor/services/websocket_provider.dart';
import 'package:muscle_fatigue_monitor/widgets/button_long.dart';
import 'package:muscle_fatigue_monitor/widgets/emg_graph.dart';
import 'package:muscle_fatigue_monitor/widgets/graph_data_info.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class RecordMuscleFatigue extends StatefulWidget {
  const RecordMuscleFatigue({super.key});

  @override
  State<RecordMuscleFatigue> createState() => _RecordMuscleFatigueState();
}

class _RecordMuscleFatigueState extends State<RecordMuscleFatigue> {

  List<SensorValue> sensorValues = [];
  List<SensorValue> mfValues = [];
  double muscleFatigue = 0;
  late bool recording;
  late bool doneRecording;
  final stopwatch = Stopwatch();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    stopwatch.reset();
    recording = false;
    doneRecording = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (stopwatch.isRunning) {
        calculateMuscleFatigue();
        setState(() {}); 
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  void calculateMuscleFatigue() {
    if (sensorValues.isEmpty) return;

    // A more robust way to get the last second's data
    final Duration timeStamp = stopwatch.elapsed;
    final oneSecondAgo = timeStamp - const Duration(seconds: 1);
    final lastSecondValues = sensorValues
        .where((e) => e.timestamp >= oneSecondAgo && e.timestamp <= timeStamp)
        .toList();

    if (lastSecondValues.isEmpty) return;

    final samplingRate = lastSecondValues.length * 1.0;

    double averageRectifiedValue = Calculations().calculateAverageRectifiedValue(lastSecondValues);
    double meanFrequency = Calculations().calculateMeanFrequency(lastSecondValues.map((e) => e.value).toList(), samplingRate);
    muscleFatigue = meanFrequency/averageRectifiedValue;

    mfValues.add(SensorValue(timestamp: stopwatch.elapsed, value: muscleFatigue));
   
  }

  String getMemoryUsageMB(List<SensorValue> sensorValues) {
    const int bytesPerDouble = 8;
    const int bytesPerFlSpot = bytesPerDouble * 2;

    int totalBytes = sensorValues.length * bytesPerFlSpot;
    double totalMB = totalBytes / (1024 * 1024);

    return totalMB.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {

    final ws = context.watch<WebSocketProvider>();
    final userProvider = context.watch<UserProvider>();

    if((ws.isReading && recording && !doneRecording)){
      if(!stopwatch.isRunning){
        stopwatch.reset();
        stopwatch.start();
        sensorValues.clear();
      }
      sensorValues.add(SensorValue(timestamp: stopwatch.elapsed, value: ws.latestValue.toDouble()));

    }

    if(!ws.isReading && recording && !doneRecording){
      if(stopwatch.isRunning){
        stopwatch.stop();
      }
    }


    return Scaffold(
      backgroundColor: AppColors().backgroundBlack,
      appBar: AppBar(
        title: Text("Record Muscle Fatigue"),
        backgroundColor: AppColors().backgroundBlack,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: ScreenSize().width(context)*0.05),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
          
              (!recording && !ws.isReading && sensorValues.isEmpty) ?
                Text("Press the Start Recording button to begin.") :
          
              (recording && !ws.isReading && sensorValues.isEmpty) ?
                Text("Press the Record button on the device to begin.") :
          
              
          
              Column(
                children: [
                  EmgGraph(sensorValues: sensorValues, timeStamp: stopwatch.elapsed, height: ScreenSize().height(context)*0.25,),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                  ),
                  Row(
                    children: [
                      GraphDataInfo(
                        icon: Icons.radio,
                        iconColor: AppColors().appGreen,
                        title: "Muscle \nFatigue Index",
                        data: muscleFatigue.toStringAsFixed(8),
                      ),
                      const SizedBox(width: 20,),
                      GraphDataInfo(
                        icon: Icons.calculate,
                        iconColor: AppColors().appBlue,
                        title: "Muscle \nFatigue",
                        data: (userProvider.user!.threshold - muscleFatigue).toStringAsFixed(8),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                ],
              ),
          
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.symmetric(horizontal: ScreenSize().width(context)*0.25),
                decoration: BoxDecoration(
                  color: AppColors().appGrey.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors().appGrey.withAlpha(50))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer),
                    const SizedBox(width: 10,),
                    Text(
                      "${stopwatch.elapsed.inMinutes.remainder(60).toString().padLeft(2, '0')}:${stopwatch.elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}"
                    ),
                  ],
                ),
              ),
          
              if(!recording && !doneRecording)
              ButtonLong(
                prefix: Container(
                    margin: EdgeInsets.only(right: 10),
                    width: 25,
                    height: 25,
                    child: Image.asset("assets/icons/button.png", color: AppColors().appWhite,)
                  ), 
                text: "Start Recording", 
                backgroundColor: AppColors().appGreen,
                onPressed: (){
                  if(!ws.isReading) {
                    setState(() {
                      recording = true;
                    });
                  } else {
                    toastification.dismissAll();
                    toastification.show(
                      context: context,
                      title: Text('Device is in Reading Mode!'),
                      description: Text("Please press the button on the device to put it into IDLE mode."),
                      type: ToastificationType.error,
                      style: ToastificationStyle.fillColored,
                      alignment: Alignment.bottomCenter,
                      animationDuration: const Duration(milliseconds: 300),
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  }
                }
              ),
          
              if(!ws.isReading && recording && sensorValues.isNotEmpty && !doneRecording)
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ButtonLong(
                      text: "Restart", 
                      backgroundColor: AppColors().appRed,
                      onPressed: (){
                        setState(() {
                          doneRecording = true;
                          mfValues.clear();
                          sensorValues.clear();
                          muscleFatigue = 0;
                        });
                      }
                    ),
                  ),
                  if(userProvider.user != null && userProvider.user!.threshold != 0)
                  const SizedBox(width: 20,),
                  if(userProvider.user != null && userProvider.user!.threshold != 0)
                  Expanded(
                    flex: 1,
                    child: ButtonLong(
                      text: "Save", 
                      backgroundColor: AppColors().appGreen,
                      onPressed: (){
                        setState(() {
                          doneRecording = true;
                          userProvider.updateUserFields(userProvider.user!.userId, reading: sensorValues, mfSeries: mfValues);
                          userProvider.getUser(userProvider.user!.userId);
                        });
                      }
                    ),
                  ),
                ],
              ),
          
          
            ],
          ),
        ),
      ),
    );
  }
}