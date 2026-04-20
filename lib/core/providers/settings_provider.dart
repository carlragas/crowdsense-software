import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class SettingsProvider extends ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('system_settings');
  StreamSubscription? _settingsSubscription;

  double _temperatureThreshold = 38.0;
  double _smokeThreshold = 300.0;
  double _flameThreshold = 200.0;
  bool _emailAlerts = false;
  bool _maintenanceMode = false;

  SettingsProvider() {
    _listenToSettings();
  }

  double get temperatureThreshold => _temperatureThreshold;
  double get smokeThreshold => _smokeThreshold;
  double get flameThreshold => _flameThreshold;
  bool get emailAlerts => _emailAlerts;
  bool get maintenanceMode => _maintenanceMode;

  void _listenToSettings() {
    _settingsSubscription = _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        _temperatureThreshold = (data['temperature_threshold'] ?? 38.0).toDouble();
        _smokeThreshold = (data['smoke_threshold'] ?? 300.0).toDouble();
        _flameThreshold = (data['flame_threshold'] ?? 200.0).toDouble();
        _emailAlerts = data['email_alerts'] == true;
        _maintenanceMode = data['maintenance_mode'] == true;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }

  // --- External Setters (Write to Firebase) ---

  Future<void> setTemperatureThreshold(double value) async {
    await _dbRef.update({'temperature_threshold': value});
  }

  Future<void> setSmokeThreshold(double value) async {
    await _dbRef.update({'smoke_threshold': value});
  }

  Future<void> setFlameThreshold(double value) async {
    await _dbRef.update({'flame_threshold': value});
  }

  Future<void> setEmailAlerts(bool value) async {
    await _dbRef.update({'email_alerts': value});
  }

  Future<void> setMaintenanceMode(bool value) async {
    await _dbRef.update({'maintenance_mode': value});
  }
}
