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

    // Send command to hardware via Firebase RTDB
    // siren_alert_active = Evacuation Siren (red alert + loud buzzer)
    // siren_clear_active = Safety Alert (blue alert, no buzzer)
    if (title == "EVACUATION SIREN") {
      FirebaseDatabase.instance.ref().child('sensors_data').update({
        'siren_alert_active': true,
        'siren_clear_active': false,
      });
    } else if (title == "SAFETY ALERT") {
      FirebaseDatabase.instance.ref().child('sensors_data').update({
        'siren_alert_active': false,
        'siren_clear_active': true,
      });
    }
  }

  void terminateSiren() {
    _activeSirenTitle = null;
    _activeSirenIcon = null;
    _activeSirenColor = null;
    notifyListeners();

    // Deactivate all sirens — set both flags to false
    FirebaseDatabase.instance.ref().child('sensors_data').update({
      'siren_alert_active': false,
      'siren_clear_active': false,
    });
  }
}
