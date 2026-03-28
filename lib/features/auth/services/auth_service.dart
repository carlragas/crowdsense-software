import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Firebase Realtime DB REST API Base URL
  final String _dbBaseUrl = 'https://crowdsense-db-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// Logs a user in using either their Email or their Username.
  /// Returns a Map payload containing the raw Firebase `User` object and the `userData` mapping.
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    String loginEmail = identifier.trim();
    
    if (!loginEmail.contains('@')) {
      // It's a username! We must securely look up the associated email in the database via REST
      try {
        final queryUrl = Uri.parse('$_dbBaseUrl/users.json?orderBy="username"&equalTo="${Uri.encodeQueryComponent(loginEmail)}"');
        final response = await http.get(queryUrl);

        if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
          throw Exception('User with this username not found. (Check Firebase Rules if this is incorrect)');
        }

        // Extract the exact email address tied to this username
        final usersMap = json.decode(response.body) as Map<String, dynamic>;
        
        if (usersMap.isEmpty) {
          throw Exception('Username search yielded zero profiles.');
        }

        final userRecord = usersMap.values.first as Map<String, dynamic>;
        
        if (userRecord['email'] == null) {
          throw Exception('Account configuration error: No email attached.');
        }
        
        loginEmail = userRecord['email'] as String;
      } catch (e) {
        throw Exception('REST Lookup Failed: $e');
      }
    }

    // 2. Perform the actual Firebase Authentication with Email and Password
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );
      
      // 3. Verify they actually exist in the DB and pull their FULL data profile securely using pure REST HTTP
      final uid = userCredential.user!.uid;
      
      // Because your Firebase Rules allow `.read: true` for the `users` node, 
      // we can fetch the user profile without asking for an active `idToken`.
      // This completely sidesteps the Windows background-thread crash bug!
      final profileUrl = Uri.parse('$_dbBaseUrl/users/$uid.json');
      
      final profileResponse = await http.get(profileUrl);
      
      if (profileResponse.statusCode != 200 || profileResponse.body == 'null' || profileResponse.body.isEmpty) {
        await _auth.signOut();
        throw Exception('Account exists in Auth but is missing from Database records.');
      }
      
      final rawUserData = json.decode(profileResponse.body) as Map<String, dynamic>;
      
      // Return a convenient bundle containing both the secure auth reference and UI data 
      return {
        'user': userCredential.user,
        'userData': rawUserData,
      };
      
    } on FirebaseAuthException catch (e) {
      // Provide clean error messages for the UI
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw Exception('Incorrect email or password.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many failed attempts. Please try again later.');
      }
      throw Exception(e.message ?? 'Authentication failed.');
    }
  }

  /// Logs the current user out
  Future<void> logout() async {
    await _auth.signOut();
  }
}
