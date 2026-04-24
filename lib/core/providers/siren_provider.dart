import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SirenProvider with ChangeNotifier {
  String? _activeSirenTitle;
  IconData? _activeSirenIcon;
  Color? _activeSirenColor;

  String? get activeSirenTitle => _activeSirenTitle;
  IconData? get activeSirenIcon => _activeSirenIcon;
  Color? get activeSirenColor => _activeSirenColor;

  bool get isSirenActive => _activeSirenTitle != null;

  bool _isBottomNavVisible = false;
  bool get isBottomNavVisible => _isBottomNavVisible;

  /// Cached list of device MAC keys (populated by the dashboard)
  List<String> _deviceKeys = [];

  void setDeviceKeys(List<String> keys) {
    _deviceKeys = keys;
  }

  void setBottomNavVisibility(bool isVisible) {
    if (_isBottomNavVisible != isVisible) {
      _isBottomNavVisible = isVisible;
      notifyListeners();
    }
  }

  void activateSiren(String title, IconData icon, Color color) {
    _activeSirenTitle = title;
    _activeSirenIcon = icon;
    _activeSirenColor = color;
    notifyListeners();

    // Broadcast command to ALL devices under sensor_data/{MAC}/
    // siren_alert_active = Evacuation Siren (red alert + loud buzzer)
    // siren_clear_active = Safety Alert (blue alert, no buzzer)
    _updateAllDeviceSirens(
      sirenAlertActive: title == "EVACUATION SIREN",
      sirenClearActive: title == "SAFETY ALERT",
    );
  }

  void terminateSiren() {
    _activeSirenTitle = null;
    _activeSirenIcon = null;
    _activeSirenColor = null;
    notifyListeners();

    // Deactivate all sirens on ALL devices
    _updateAllDeviceSirens(
      sirenAlertActive: false,
      sirenClearActive: false,
    );
  }

  /// Writes siren flags to every known device under sensor_data/{MAC}/.
  /// Uses the cached _deviceKeys list so we don't need a .get() read.
  Future<void> _updateAllDeviceSirens({
    required bool sirenAlertActive,
    required bool sirenClearActive,
  }) async {
    if (_deviceKeys.isEmpty) return;

    final sensorsRef = FirebaseDatabase.instance.ref().child('sensor_data');

    for (final mac in _deviceKeys) {
      try {
        await sensorsRef.child(mac).update({
          'siren_alert_active': sirenAlertActive,
          'siren_clear_active': sirenClearActive,
        });
      } catch (_) {}
    }
  }
}
