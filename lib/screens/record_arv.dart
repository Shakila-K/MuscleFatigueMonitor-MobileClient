
import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';
import 'package:muscle_fatigue_monitor/consts/screen_size.dart';
import 'package:muscle_fatigue_monitor/models/sensor_value.dart';
import 'package:muscle_fatigue_monitor/services/user_provider.dart';
import 'package:muscle_fatigue_monitor/services/websocket_provider.dart';
import 'package:muscle_fatigue_monitor/widgets/button_long.dart';
import 'package:muscle_fatigue_monitor/widgets/emg_graph.dart';
import 'package:muscle_fatigue_monitor/widgets/graph_data_info.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class RecordArv extends StatefulWidget {
  const RecordArv({
    super.key,
  });

  @override
  State<RecordArv> createState() => _RecordArvState();
}

class _RecordArvState extends State<RecordArv> {

  List<SensorValue> sensorValues = [];
  List<double> arvs = [];

  late int recordCount;

  late bool recording;
  late bool doneRecording;
  late bool showSaveDiscard;
  final stopwatch = Stopwatch();

  @override
  void initState() {
    stopwatch.reset();
    recording = false;
    recordCount = 0;
    doneRecording = false;
    showSaveDiscard = false;
    super.initState();
  }

  void getArv() {
    if (sensorValues.isEmpty) return;

    // latest elapsed time
    final latestTime = sensorValues.last.timestamp;

    // filter values within the last 1 second
    final lastSecondValues = sensorValues.where(
      (e) => (latestTime - e.timestamp).inMilliseconds <= 1000,
    );

    if (lastSecondValues.isEmpty) return;

    // max value in the last 1 second
    double arv = 0;
    for (SensorValue v in lastSecondValues) {
      arv += v.value;
    }
    arv = (arv / lastSecondValues.length);

    arvs.add(arv);
    debugPrint("New ARV added: $arv");
  }

  double getFinalArv(){
    double t = 0;
    for (double i in arvs){
      t+=i;
    }
    return t/arvs.length;
  }

  String getMemoryUsageMB(List<SensorValue> sensorValues) {
    const int bytesPerDouble = 8; // double = 8 bytes
    const int bytesPerFlSpot = bytesPerDouble * 2; // each FlSpot has x and y doubles

    int totalBytes = sensorValues.length * bytesPerFlSpot;
    double totalMB = totalBytes / (1024 * 1024);

    return totalMB.toStringAsFixed(3); // 4 decimal places
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
      }
      sensorValues.add(SensorValue(timestamp: stopwatch.elapsed, value: ws.latestValue.toInt()));
    }

    if(!ws.isReading && recording){
      if(stopwatch.isRunning){
        stopwatch.stop();
        showSaveDiscard = true;
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Record ARV"),
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
                    Text("Your EMG data will be recorded 3 times in order to get an average rectified value."),

                  (!recording) ?
                    Text("Put the device in IDLE mode (Red LED is off) then press the Start Recording button to begin.") :
              
                  (recording && !ws.isReading && (sensorValues.isEmpty && recordCount ==0)) ?
                    Text("Press the Record button on the device to begin.") :
                  
                  Column(
                    children: [
                      EmgGraph(sensorValues: sensorValues, timeStamp: stopwatch.elapsed,),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                      ),
                      Row(
                        children: [
                          GraphDataInfo(
                            icon: Icons.sd_card,
                            iconColor: AppColors().appGreen,
                            title: "Memory \nUsage",
                            data: "${getMemoryUsageMB(sensorValues)} MB",
                          ),
                          const SizedBox(width: 20,),
                          GraphDataInfo(
                            icon: Icons.calculate,
                            iconColor: AppColors().appBlue,
                            title: "Current \nARV",
                            data: arvs.isEmpty ? "0" : (getFinalArv()).toStringAsFixed(2),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),

              Text("ARV recorded $recordCount/3 time(s)"),
          
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
              // if(recording && !ws.isReading && sensorValues.isNotEmpty && !doneRecording)
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
                          recordCount ++;
                          getArv();
                          if(recordCount>=3) doneRecording = true;
                          debugPrint(arvs.toString());
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
                          recordCount = 0;
                          recording = false;
                          doneRecording = false;
                          arvs.clear();
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
                          userProvider.updateUserFields(userProvider.user!.userId, arv: getFinalArv());
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
