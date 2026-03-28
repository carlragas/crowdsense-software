import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  User? _authUser;
  Map<String, dynamic>? _userData;

  User? get authUser => _authUser;
  Map<String, dynamic>? get userData => _userData;
  
  bool get isAuthenticated => _authUser != null && _userData != null;

  String get id => _userData?['customId'] ?? 'Unknown ID';
  String get role => _userData?['role'] ?? 'Unknown';
  String get name => _userData?['name'] ?? 'Admin';
  String get firstName => name.isNotEmpty ? name.split(' ').first : 'Admin';
  String get username => _userData?['username'] ?? '';
  String get email => _userData?['email'] ?? '';
  String get phone => _userData?['phone'] ?? '';
  String get designation => _userData?['designation'] ?? 'Official Administrator';

  void setUser(User? user, Map<String, dynamic>? data) {
    _authUser = user;
    if (data != null) {
      // Create a clean modifiable string map from the dynamic Firebase snapshot
      _userData = Map<String, dynamic>.from(data);
    }
    notifyListeners();
  }

  void updateProfile(Map<String, dynamic> updatedData) {
    if (_userData != null) {
      _userData!.addAll(updatedData);
      notifyListeners();
    }
  }

  void clearUser() {
    _authUser = null;
    _userData = null;
    notifyListeners();
  }
}
