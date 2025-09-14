
import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';
import 'package:muscle_fatigue_monitor/consts/screen_size.dart';
import 'package:muscle_fatigue_monitor/models/sensor_value.dart';
import 'package:muscle_fatigue_monitor/services/websocket_service.dart';
import 'package:muscle_fatigue_monitor/widgets/button_long.dart';
import 'package:muscle_fatigue_monitor/widgets/emg_graph.dart';
import 'package:muscle_fatigue_monitor/widgets/graph_data_info.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class RecordData extends StatefulWidget {
  final String title;
  final bool recordThreshold;
  const RecordData({
    super.key,
    required this.title,
    required this.recordThreshold
  });

  @override
  State<RecordData> createState() => _RecordDataState();
}

class _RecordDataState extends State<RecordData> {

  List<SensorValue> sensorValues = [];
  List<double> thresholds = [];

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

  void getMax(){
    double max = 0;
    for(SensorValue e in sensorValues){
      debugPrint(e.value.toString());
      if(e.value > max){
        max = e.value;
      }
    }
    thresholds.add(max);
  }

  double getThreshold(){
    double t = 0;
    for (double i in thresholds){
      t+=i;
    }
    return t/thresholds.length;
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

    if((ws.isReading && recording && !doneRecording)){
      if(!stopwatch.isRunning){
        stopwatch.reset();
        stopwatch.start();
        sensorValues.clear();
      }
      sensorValues.add(SensorValue(timestamp: stopwatch.elapsed, value: ws.latestValue.toDouble()));
    }

    if(!ws.isReading && recording){
      if(stopwatch.isRunning){
        stopwatch.stop();
        showSaveDiscard = true;
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                  if(widget.recordThreshold && !recording)
                    Text("Your EMG data will be recorded 3 times in order to get an average threshold value."),

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
                            icon: Icons.percent,
                            iconColor: AppColors().appBlue,
                            title: "Current \nThreshold",
                            data: "${ thresholds.isEmpty ? "0" : (getThreshold()*100/4095).toStringAsFixed(2)}%",
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),

              if(widget.recordThreshold)
                Text("Threshold recorded $recordCount/3 time(s)"),
          
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
              if(showSaveDiscard && !doneRecording)
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
                          if(widget.recordThreshold) {
                            recordCount ++;
                            getMax();
                            if(recordCount>=3) doneRecording = true;
                            debugPrint(thresholds.toString());
                          }
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
                          thresholds.clear();
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
                          ws.threshold = getThreshold();

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
