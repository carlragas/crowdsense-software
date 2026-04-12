import 'package:flutter/material.dart';

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
  }

  void terminateSiren() {
    _activeSirenTitle = null;
    _activeSirenIcon = null;
    _activeSirenColor = null;
    notifyListeners();
  }
}
