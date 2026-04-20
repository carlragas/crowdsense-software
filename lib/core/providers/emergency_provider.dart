import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

/// Manages the tactical emergency state and evacuation metrics globally via Firebase.
class EmergencyProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('system_state/emergency');
  StreamSubscription? _emergencySubscription;

  bool _isEmergencyActive = false;
  int _initialOccupancy = 0;
  int _currentOccupancy = 0;
  int _trippedSensorsCount = 0;
  int _onlineCount = 0;
  int _offlineCount = 0;
  int _totalDevices = 0;

  EmergencyProvider() {
    _listenToEmergencyState();
  }

  bool get isEmergencyActive => _isEmergencyActive;
  int get initialOccupancy => _initialOccupancy;
  int get currentOccupancy => _currentOccupancy;
  int get trippedSensorsCount => _trippedSensorsCount;
  int get onlineCount => _onlineCount;
  int get offlineCount => _offlineCount;
  int get totalDevices => _totalDevices;

  /// Ratio of people who have exited vs initial occupancy.
  double get evacuationProgress => _initialOccupancy > 0 
      ? ((_initialOccupancy - _currentOccupancy) / _initialOccupancy).clamp(0.0, 1.0) 
      : 0.0;

  int get evacuatedCount => (_initialOccupancy - _currentOccupancy).clamp(0, _initialOccupancy);

  void _listenToEmergencyState() {
    _emergencySubscription = _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        _isEmergencyActive = data['active'] == true;
        _initialOccupancy = (data['initial_occupancy'] ?? 0).toInt();
        // currentOccupancy and other metrics are still pushed from local sensors but shared in memory
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _emergencySubscription?.cancel();
    super.dispose();
  }

  /// Puts the dashboard into tactical mode and captures starting occupancy (Syncs to Firebase).
  Future<void> toggleEmergency(bool active, int startingOccupancy) async {
    await _dbRef.update({
      'active': active,
      'initial_occupancy': active ? startingOccupancy : 0,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Updates current occupancy locally.
  void updateCurrentOccupancy(int count) {
    if (_currentOccupancy == count) return;
    _currentOccupancy = count;
    if (_isEmergencyActive) notifyListeners();
  }

  /// Updates the count of sensors currently above threat thresholds.
  void updateThreatCount(int count) {
    if (_trippedSensorsCount == count) return;
    _trippedSensorsCount = count;
    notifyListeners();
  }

  /// Synchronizes online/offline device counts across the app.
  void updateDeviceMetrics(int online, int offline) {
    if (_onlineCount == online && _offlineCount == offline) return;
    _onlineCount = online;
    _offlineCount = offline;
    _totalDevices = online + offline;
    notifyListeners();
  }
}
