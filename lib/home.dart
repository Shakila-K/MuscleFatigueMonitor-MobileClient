import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/models/sensor_value.dart';
import 'package:muscle_fatigue_monitor/services/pdf_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  StreamSubscription? _subscription;
  bool isConnected = false;
  bool reading = false;
  WebSocketChannel? channel;
  TextEditingController ip = TextEditingController();

  String sensorData = "Waiting for data...";
  final List<SensorValue> sensorValues = [];
  int currentIndex = 0; // Used for X-axis tracking

  // Define the min and max Y-axis values
  double minY = -100;
  double maxY = 4196;

  @override
  void initState() {
    super.initState();
    ip.text = "172.20.10.2";
  }

  void connectToWebSocket() {
    try {
      final ipAddress = ip.text.trim();
      final fullUri = Uri.parse('ws://$ipAddress:81');
      final newChannel = WebSocketChannel.connect(fullUri);
      newChannel.stream.listen(
        (data) {
            var parsedData = jsonDecode(data);
            String valueString = parsedData['value'];
            if(valueString == "-"){
              setState(() {
                reading = false;
              });
              
            } else{
              int sensorValue = int.parse(valueString);
              setState(() {
                if(!reading) reading = true;
                sensorData = sensorValue.toString();
                sensorValues.add(SensorValue(
                  timestamp: DateTime.now(),
                  value: sensorValue.toDouble(),
                ));
              });

            }
            
        },
        onDone: () {
          setState(() {
            isConnected = false;
          });
        },
        onError: (error) {
          setState(() {
            isConnected = false;
          });
          debugPrint("WebSocket error: $error");
        },
      );

      setState(() {
        channel = newChannel;
        isConnected = true;
      });
    } catch (e) {
      debugPrint("Connection failed: $e");
      setState(() {
        isConnected = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    channel?.sink.close();
    ip.dispose();
    super.dispose();
  }


  List<FlSpot> _getLastSpots(int count) {
    if (sensorValues.isEmpty) return [];
    int start = sensorValues.length > count ? sensorValues.length - count : 0;
    final baseTime = sensorValues[start].timestamp.millisecondsSinceEpoch.toDouble();
    return sensorValues.sublist(start).map((e) {
      double x = (e.timestamp.millisecondsSinceEpoch - baseTime) / 1000.0; // X in seconds
      return FlSpot(x, e.value);
    }).toList();
  }

  double _getMinX(int count) {
    final spots = _getLastSpots(count);
    return spots.isNotEmpty ? spots.first.x : 0;
  }

  double _getMaxX() {
    final spots = _getLastSpots(100); // Keep consistent with chart range
    return spots.isNotEmpty ? spots.last.x : 100;
  }


  String getMemoryUsageMB() {
    const int bytesPerDouble = 8; // double = 8 bytes
    const int bytesPerFlSpot = bytesPerDouble * 2; // each FlSpot has x and y doubles

    int totalBytes = sensorValues.length * bytesPerFlSpot;
    double totalMB = totalBytes / (1024 * 1024);

    return totalMB.toStringAsFixed(4); // 4 decimal places
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Muscle Fatigue Monitor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ip,
                      decoration: InputDecoration(
                        hintText: "Enter WebSocket IP (e.g.: 192.168.x.x)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isConnected ? null : connectToWebSocket,
                    child: Text(isConnected ? "Connected" : "Connect"),
                  ),
                ],
              ),
            ),
            Text('Sensor Value:'),
            Text(sensorData),
            SizedBox(height: 20),
            SizedBox(
              height: 300,
              width: 400,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getLastSpots(100),
                      isCurved: true,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: false), // Hides dots
                    ),
                  ],
                  minY: minY,
                  maxY: maxY,
                  minX: _getMinX(100),
                  maxX: _getMaxX(),
                ),
              ),
            ),
            SizedBox(height: 10),
            Text('Memory Usage: ${getMemoryUsageMB()} MB'),
            Text('List Items: ${sensorValues.length}'),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  sensorValues.clear();
                },
                child: Text('Clear'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () async {
                  final pdfData = await PdfService().generateSensorGraphReport(sensorValues);

                  await PdfService().sharePdf(pdfData, 'EMG Data.pdf');
                  // await Printing.layoutPdf(
                  //   onLayout: (_) async => pdfData,
                  // );
                },
                child: Text('Save Chart to PDF'),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
