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

class RecordThreshold extends StatefulWidget {
  
  const RecordThreshold({
    super.key,
  });

  @override
  State<RecordThreshold> createState() => _RecordThresholdState();
}

class _RecordThresholdState extends State<RecordThreshold> {

  List<SensorValue> sensorValues = [];
  List<double> muscleFatigues = [];

  late bool recording;
  late bool doneRecording;
  late bool showSaveDiscard;

  double averageRectifiedValue = 0;
  double meanFrequency = 0;
  double muscleFatigue = 0;

  final stopwatch = Stopwatch();

  @override
  void initState() {
    stopwatch.reset();
    recording = false;
    doneRecording = false;
    showSaveDiscard = false;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    final ws = context.watch<WebSocketProvider>();
    final userProvider = context.watch<UserProvider>();

    if((ws.isReading && recording && !doneRecording)){
      if(!stopwatch.isRunning){
        stopwatch.reset();
        stopwatch.start();
        showSaveDiscard = false;
        sensorValues.clear();
        averageRectifiedValue = 0;
        meanFrequency = 0;
        muscleFatigue = 0;
      }
      sensorValues.add(SensorValue(timestamp: stopwatch.elapsed, value: ws.latestValue.toDouble()));
    }

    if(!ws.isReading && recording){
      if(stopwatch.isRunning){
        stopwatch.stop();

         // latest elapsed time
        Duration latestTime = sensorValues.last.timestamp;
        // filter values within the last 1 second
        List<SensorValue> lastSecondValues = sensorValues.where(
          (e) => (latestTime - e.timestamp).inMilliseconds <= 2000,
        ).toList();

        averageRectifiedValue = Calculations().calculateAverageRectifiedValue(lastSecondValues);
        meanFrequency = Calculations().calculateMeanFrequency(lastSecondValues.map((sv) => sv.value).toList(), lastSecondValues.length.toDouble());
        muscleFatigue = meanFrequency / averageRectifiedValue;
        showSaveDiscard = true;
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Record Threshold"),
        backgroundColor: AppColors().backgroundBlack,
        automaticallyImplyLeading: true,
        foregroundColor: AppColors().appWhite,
      ),

      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: ScreenSize().width(context)*0.05),
        decoration: BoxDecoration(
          color: AppColors().backgroundBlack
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
      
              Column(
                children: [
                  
                  if(!recording)
                    Text("Your EMG data will be recorded 3 times in order to get an average threshold."),
      
                  (!recording) ?
                    Text("Put the device in IDLE mode (Red LED is off) then press the Start Recording button to begin.") :
              
                  (recording && !ws.isReading && (sensorValues.isEmpty && muscleFatigues.isEmpty)) ?
                    Text("Press the Record button on the device to begin.") :
                  
                  Column(
                    children: [
                      EmgGraph(sensorValues: sensorValues, timeStamp: stopwatch.elapsed, height: ScreenSize().height(context)*0.25, ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                      ),
                      Row(
                        children: [
                          GraphDataInfo(
                            icon: Icons.calculate,
                            iconColor: AppColors().appGreen,
                            title: ("Muscle \nFatigue"),
                            data: muscleFatigue == 0 ? "Calculating..." : muscleFatigue.toStringAsFixed(8),
                          ),
                          const SizedBox(width: 20,),
                          GraphDataInfo(
                            icon: muscleFatigues.length==3 ? Icons.speed : Icons.timer,
                            iconColor: AppColors().appBlue,
                            title: muscleFatigues.length==3 ? "Threshold" :"Record \nCount",
                            data: muscleFatigues.length==3 ? (muscleFatigues.fold(0.0, (a, b) => (a + b))/3).toStringAsFixed(8): muscleFatigues.length.toString(),
                          ),
                        ],
                      )
                    ],
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
      
              if(!recording)
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
      
              if(showSaveDiscard)
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ButtonLong(
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Icon(Icons.cancel)
                        ), 
                        text: "Discard", 
                        backgroundColor: AppColors().appRed,
                        onPressed: (){
                          showSaveDiscard = false;
                          stopwatch.reset();
                        }
                      ),
                    ),
                    const SizedBox(width: 20,),
                    Expanded(
                      flex: 1,
                      child: ButtonLong(
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Icon(Icons.save),
                        ), 
                        text: "Save", 
                        backgroundColor: AppColors().appGreen,
                        onPressed: (){
                          showSaveDiscard = false;
                          muscleFatigues.add(muscleFatigue);
                          
                          if(muscleFatigues.length>=3) doneRecording = true;
                          debugPrint(muscleFatigues.toString());
                        }
                      ),
                    )
                  ],
                ),
      
              if(doneRecording)
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ButtonLong(
                        prefix: Padding(
                          padding: EdgeInsetsGeometry.only(right: 10),
                          child: Icon(Icons.restart_alt),
                        ), 
                        text: "Restart", 
                        backgroundColor: AppColors().appRed,
                        onPressed: (){
                          sensorValues.clear();
                          muscleFatigues.clear();
                          recording = false;
                          doneRecording = false;
                          muscleFatigues.clear();
                          stopwatch.reset();
                        }
                      ),
                    ),
                    const SizedBox(width: 20,),
                    Expanded(
                      flex: 1,
                      child: ButtonLong(
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Icon(Icons.arrow_forward_outlined)
                        ), 
                        text: "Continue", 
                        backgroundColor: AppColors().appBlue,
                        onPressed: (){
                          double mfThreshold = (muscleFatigues.fold(0.0, (a, b) => (a + b))/3);

                          List<SensorValue> mfValues = Calculations().calculateMuscleFatigueOfList(sensorValues);

                          userProvider.updateUserFields(userProvider.user!.userId, threshold: mfThreshold, reading: sensorValues, mfSeries: mfValues);
                          userProvider.getUser(userProvider.user!.userId);
                          Navigator.of(context).pop();
                        }
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),

    );
  }
}
