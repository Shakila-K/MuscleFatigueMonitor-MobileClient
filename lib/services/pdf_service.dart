import 'dart:io';
import 'dart:typed_data';

import 'package:muscle_fatigue_monitor/models/sensor_value.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  
  Future<Uint8List> generateSensorGraphReport(List<SensorValue> sensorValues) async {
    final document = pw.Document();

    const baseColor = PdfColors.deepPurple;
    const pointWidth = 2.0; // Width per data point
    const pageHeight = 500.0;

    final pageWidth = sensorValues.length * pointWidth;

    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.openSansRegular(),
      bold: await PdfGoogleFonts.openSansBold(),
    );

    final chart = pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis(
          List.generate(sensorValues.length, (i) => i.toDouble()),
          divisions: true,
        ),
        yAxis: pw.FixedAxis(
          [0, 512, 1024, 1536, 2048, 2560, 3072, 3584, 4096],
          divisions: true,
        ),
      ),
      datasets: [
        pw.LineDataSet(
          legend: 'EMG Signal',
          drawSurface: false,
          isCurved: true,
          drawPoints: false,
          color: baseColor,
          data: List<pw.PointChartValue>.generate(
            sensorValues.length,
            (i) => pw.PointChartValue(
              i.toDouble(),
              sensorValues[i].value,
            ),
          ),
        ),
      ],
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
        theme: theme,
        build: (context) => pw.Container(
          width: pageWidth,
          height: pageHeight,
          child: chart,
        ),
      ),
    );

    return document.save();
  }

  Future<void> sharePdf(Uint8List pdfData, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
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
