import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';
import 'package:muscle_fatigue_monitor/models/sensor_value.dart';

class EmgGraph extends StatelessWidget {
  final List<SensorValue> sensorValues;
  final Duration timeStamp;
  final bool? lastvalues;
  final double? maximumY;
  const EmgGraph({super.key, required this.sensorValues, required this.timeStamp, this.lastvalues, this.maximumY});

  @override
  Widget build(BuildContext context) {

    double minY = 0;
    double maxY = maximumY ?? 4095;

    List<FlSpot> getLastSpots(int count, List<SensorValue> sensorValues) {
      if (sensorValues.isEmpty) return [];
      int start = sensorValues.length > count ? sensorValues.length - count : 0;
      return sensorValues.sublist(start).map((e) {
        double x = (e.timestamp.inMilliseconds /1000);
        return FlSpot(x, (e.value));
      }).toList();
    }

    List<FlSpot> getAllSpots(List<SensorValue> sensorValues) {
      if (sensorValues.isEmpty) return [];
      return sensorValues.map((e) {
        double x = (e.timestamp.inMilliseconds /1000);
        return FlSpot(x, (e.value));
      }).toList();
    }

    double getMinX(int count, List<SensorValue> sensorValues) {
      final spots = (lastvalues != null && lastvalues == false)? getAllSpots(sensorValues) : getLastSpots(count, sensorValues);
      return spots.isNotEmpty ? spots.first.x : 0;
    }

    double getMaxX(List<SensorValue> sensorValues) {
      final spots = (lastvalues != null && lastvalues == false)? getAllSpots(sensorValues) : getLastSpots(100, sensorValues);
      return spots.isNotEmpty ? spots.last.x : 100;
    }

    return Column(
      children: [
        SizedBox(
              height: 350,
              // width: (lastvalues != null && lastvalues == false)? MediaQuery.of(context).size.width : 400,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true, 
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    verticalInterval: 1,
                    horizontalInterval: 1024,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors().appGrey.withAlpha(30)
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {

                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${value.toInt()}s',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // hide left titles
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // hide right titles
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // hide top titles
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: (lastvalues != null && lastvalues == false)? getAllSpots(sensorValues) : getLastSpots(100, sensorValues),
                      isCurved: false,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: false), // Hides dots
                    ),
                  ],
                  minY: minY,
                  maxY: maxY,
                  minX: getMinX(100, sensorValues),
                  maxX: getMaxX(sensorValues),
                ),
              ),
            ),
      ],
    );
  }
}
