
import 'package:muscle_fatigue_monitor/models/sensor_value.dart';
import 'package:scidart/numdart.dart';
import 'package:scidart/scidart.dart';

class Calculations {

  double calculateMeanFrequency(List<double> signal, double samplingRate) {
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

  double calculateAverageRectifiedValue(List<SensorValue> sensorValues) {
    // max value in the last 1 second
    double arv = 0;
    for (SensorValue v in sensorValues) {
      arv += v.value.abs();
    }
    arv = (arv / sensorValues.length);
    return arv;
  }

  List<SensorValue> calculateMuscleFatigueOfList(List<SensorValue> values){

    List<SensorValue> muscleFatigues = [];

    Duration d = Duration(seconds: 0);

    while(d <= values.last.timestamp){
      final secondValues = values.where((e) => e.timestamp>=d && e.timestamp<=(d + Duration(seconds: 1))).toList();
      print(secondValues.first.timestamp);
      print(secondValues.last.timestamp);

      double arv = calculateAverageRectifiedValue(secondValues);
      double mf = calculateMeanFrequency(secondValues.map((e) => e.value).toList(), secondValues.length.toDouble());

      double muscleFatigue = mf/arv;

      muscleFatigues.add(SensorValue(timestamp: (d + Duration(seconds: 1)), value: muscleFatigue));

      d = d + Duration(seconds: 1);
    }

    return muscleFatigues;

  }
  
}