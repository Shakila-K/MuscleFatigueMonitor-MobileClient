import 'dart:async';

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
import 'package:scidart/numdart.dart';
import 'package:scidart/scidart.dart';
import 'package:toastification/toastification.dart';

class RecordMuscleFatigue extends StatefulWidget {
  const RecordMuscleFatigue({super.key});

  @override
  State<RecordMuscleFatigue> createState() => _RecordMuscleFatigueState();
}

class _RecordMuscleFatigueState extends State<RecordMuscleFatigue> {

  List<SensorValue> sensorValues = [];
  late bool recording;
  late bool doneRecording;
  double mnf = 0;
  final stopwatch = Stopwatch();
  List<SensorValue> mfValues = [];

  late double arv;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    stopwatch.reset();
    recording = false;
    doneRecording = false;

    arv = Provider.of<UserProvider>(context, listen: false).user!.arv;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (stopwatch.isRunning) {
        getMF();
        // Call setState to update the UI with the new MNF value
        setState(() {}); 
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  double calculateMNF(List<double> signal, double samplingRate) {
    if (signal.isEmpty) return 0;

    // 1. Apply a Hann window to the signal
    final n = signal.length;
    final windowedSignal = <double>[];
    for (int i = 0; i < n; i++) {
      // Hann window formula: 0.5 * (1 - cos(2 * pi * i / (n - 1)))
      final hannValue = 0.5 * (1 - cos(2 * pi * i / (n - 1)));
      windowedSignal.add(signal[i] * hannValue);
    }

    // 2. Convert the windowed signal to ArrayComplex
    var sigArrayComplex = ArrayComplex(
      windowedSignal.map((e) => Complex(real: e, imaginary: 0)).toList()
    );

    // 3. Perform FFT
    var fftResult = fft(sigArrayComplex);

    // 4. Power spectrum
    var powerSpectrum = Array([
      for (var c in fftResult) (c.real * c.real + c.imaginary * c.imaginary)
    ]);

    // 5. Generate frequency axis
    var freqs = Array([
      for (int i = 0; i < n ~/ 2; i++) i * (samplingRate / n)
    ]);
    var truncatedPower = powerSpectrum.getRangeArray(0, n ~/ 2);

    // 6. Calculate Mean Frequency (MNF)
    double numerator = 0;
    double denominator = 0;
    for (int i = 0; i < freqs.length; i++) {
      numerator += freqs[i] * truncatedPower[i];
      denominator += truncatedPower[i];
    }
    return denominator == 0 ? 0 : numerator / denominator;
  }

  void getMF() {
    if (sensorValues.isEmpty) return;

    // A more robust way to get the last second's data
    final Duration timeStamp = stopwatch.elapsed;
    final oneSecondAgo = timeStamp - const Duration(seconds: 1);
    final lastSecondValues = sensorValues
        .where((e) => e.timestamp >= oneSecondAgo && e.timestamp <= timeStamp)
        .toList();

    if (lastSecondValues.isEmpty) return;

    final samplingRate = lastSecondValues.length * 1.0;

    mnf = calculateMNF(lastSecondValues.map((sv) => sv.value * 1.0).toList(),
        samplingRate);
    mfValues.add(SensorValue(timestamp: stopwatch.elapsed, value: mnf/(arv)));
    print(mfValues.last.value);
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
                  EmgGraph(sensorValues: sensorValues, timeStamp: stopwatch.elapsed,),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                  ),
                  Row(
                    children: [
                      GraphDataInfo(
                        icon: Icons.radio,
                        iconColor: AppColors().appGreen,
                        title: "Mean \nFrequency",
                        data: mnf.toStringAsFixed(3),
                      ),
                      const SizedBox(width: 20,),
                      GraphDataInfo(
                        icon: Icons.calculate,
                        iconColor: AppColors().appBlue,
                        title: "Muscle \nFatigue",
                        data: (mnf/(userProvider.user!.arv)).toStringAsExponential(3),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                  Row(
                    children: [
                      GraphDataInfo(
                        icon: Icons.speed,
                        iconColor: AppColors().appRed,
                        title: "Saved \nThreshold",
                        data: (userProvider.user != null && userProvider.user!.threshold != 0) ? userProvider.user!.threshold.toStringAsExponential(3) : "N/A",
                      ),
                      const SizedBox(width: 20,),
                      GraphDataInfo(
                        icon: Icons.calculate,
                        iconColor: AppColors().appBlue,
                        title: "Muscle \nFatigue Index",
                        data: (userProvider.user != null && userProvider.user!.threshold != 0) ? (userProvider.user!.threshold - (mnf/(userProvider.user!.arv))).toStringAsExponential(3) : "N/A",
                      ),
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
                      text: "Save Threshold", 
                      backgroundColor: AppColors().appBlue,
                      onPressed: (){
                        setState(() {
                          doneRecording = true;
                          userProvider.updateUserFields(userProvider.user!.userId, threshold: (mnf/(userProvider.user!.arv)));
                          userProvider.getUser(userProvider.user!.userId);
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
                      text: "Save MF", 
                      backgroundColor: AppColors().appGreen,
                      onPressed: (){
                        setState(() {
                          doneRecording = true;
                          userProvider.updateUserFields(userProvider.user!.userId, reading: sensorValues, mfSeries: mfValues, latestMfi: (userProvider.user!.threshold - (mnf/(userProvider.user!.arv))));
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