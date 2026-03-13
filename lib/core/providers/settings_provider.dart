import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  double _temperatureThreshold = 38.0;
  double _smokeThreshold = 300.0;

  double get temperatureThreshold => _temperatureThreshold;
  double get smokeThreshold => _smokeThreshold;

  void setTemperatureThreshold(double value) {
    if (_temperatureThreshold != value) {
      _temperatureThreshold = value;
      notifyListeners();
    }
  }

  void setSmokeThreshold(double value) {
    if (_smokeThreshold != value) {
      _smokeThreshold = value;
      notifyListeners();
    }
  }
}
