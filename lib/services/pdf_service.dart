import 'dart:io';
import 'dart:typed_data';

import 'package:muscle_fatigue_monitor/models/sensor_value.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  /// Generate PDF report with sensor graph
  Future<Uint8List> generateUserReport({
    required String userId,
    required String gender,
    required int age,
    required double height,
    required double weight,
    required double arv,
    required double latestMfi,
    required List<SensorValue> emgValues,
    required List<SensorValue> mfValues,
  }) async {
    final document = pw.Document();

    const baseColor = PdfColors.deepPurple;
    const double pointWidth = 2.0; // Width per data point
    const double chartHeight = 200.0; // Height for each chart

    // Helper: sort by timestamp and convert to a list of (x,y) for chart
    List<pw.PointChartValue> generatePoints(List<SensorValue> values) {
      if (values.isEmpty) return [];

      final sorted = [...values]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return List<pw.PointChartValue>.generate(
        sorted.length,
        (i) => pw.PointChartValue(i.toDouble(), sorted[i].value), // Use index as the X value
      );
    }
    
    // Helper: generate x-axis values for 1-second intervals
    List<double> generateSecondIntervals(List<SensorValue> values) {
      if (values.isEmpty) return [];
      final sorted = [...values]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final List<double> intervalIndices = [];
      int lastSecond = -1;

      for (int i = 0; i < sorted.length; i++) {
        final currentSecond = sorted[i].timestamp.inSeconds;
        if (currentSecond > lastSecond) {
          intervalIndices.add(i.toDouble());
          lastSecond = currentSecond;
        }
      }
      return intervalIndices;
    }


    // Determine page width based on the largest dataset
    final maxPoints = emgValues.length > mfValues.length ? emgValues.length : mfValues.length;
    final double pageWidth = maxPoints * pointWidth + 50;

    // Theme
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.openSansRegular(),
      bold: await PdfGoogleFonts.openSansBold(),
    );

    // Create EMG Chart
    final emgPoints = generatePoints(emgValues);
    final emgXAxisValues = generateSecondIntervals(emgValues);
    final firstEmgTime = emgValues.isNotEmpty ? emgValues.first.timestamp.inSeconds : 0;
    final lastEmgTime = emgValues.isNotEmpty ? emgValues.last.timestamp.inSeconds : 0;

    final emgChart = pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis(emgXAxisValues, divisions: true),
        yAxis: pw.FixedAxis([0, 1024, 2048, 3072, 4096], divisions: true),
      ),
      datasets: [
        pw.LineDataSet(
          legend: 'EMG Signal',
          drawSurface: false,
          isCurved: true,
          drawPoints: false,
          color: baseColor,
          data: emgPoints,
        ),
      ],
    );

    // Create MFI Chart
    final mfiPoints = generatePoints(mfValues);
    final mfiXAxisValues = generateSecondIntervals(mfValues);
    final firstMfiTime = mfValues.isNotEmpty ? mfValues.first.timestamp.inSeconds : 0;
    final lastMfiTime = mfValues.isNotEmpty ? mfValues.last.timestamp.inSeconds : 0;

    // Safely generate the Y-axis values for the MFI chart
    List<double> mfiYAxisValues;
    if (latestMfi > 0.0) {
      mfiYAxisValues = [0, 0.25 * latestMfi, 0.5 * latestMfi, 0.75 * latestMfi, latestMfi];
    } else {
      // Use a default, small ascending scale if latestMfi is 0 or negative
      mfiYAxisValues = [0.0, 0.001, 0.002, 0.003, 0.004];
    }

    final mfiChart = pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis(mfiXAxisValues, divisions: true),
        yAxis: pw.FixedAxis(mfiYAxisValues, divisions: true),
      ),
      datasets: [
        pw.LineDataSet(
          legend: 'Muscle Fatigue Index',
          drawSurface: false,
          isCurved: true,
          drawPoints: false,
          color: baseColor,
          data: mfiPoints,
        ),
      ],
    );

    // Add a single page with text + charts
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, chartHeight * 2 + 150),
        theme: theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('User Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('User ID: $userId', style: pw.TextStyle(fontSize: 12)),
              pw.Text('Gender: $gender', style: pw.TextStyle(fontSize: 12)),
              pw.Text('Age: $age years', style: pw.TextStyle(fontSize: 12)),
              pw.Text('Height: $height cm', style: pw.TextStyle(fontSize: 12)),
              pw.Text('Weight: $weight kg', style: pw.TextStyle(fontSize: 12)),
              pw.Text('Average Rectified Value: ${arv.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12)),
              pw.Text('Last Muscle Fatigue Index: ${latestMfi.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),

              // EMG graph
              pw.Text('EMG Signal (First Point: $firstEmgTime s, Last Point: $lastEmgTime s)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: chartHeight, child: emgChart),
              pw.SizedBox(height: 20),

              // MFI graph
              pw.Text('Muscle Fatigue Variation (First Point: $firstMfiTime s, Last Point: $lastMfiTime s)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: chartHeight, child: mfiChart),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  /// Share PDF
  Future<void> sharePdf(Uint8List pdfData, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.pdf');
    await file.writeAsBytes(pdfData);

    final params = ShareParams(
      files: [XFile(file.path)],
    );

    final result = await SharePlus.instance.share(params);

    if (result.status == ShareResultStatus.success) {
      print('Sharing Done');
    }
  }
}