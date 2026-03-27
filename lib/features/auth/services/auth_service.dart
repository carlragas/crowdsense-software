import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Logs a user in using either their Email or their Username.
  /// Returns a Map payload containing the raw Firebase `User` object and the `userData` mapping.
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    String loginEmail = identifier.trim();
    
    // 1. Determine if the identifier is an email or a username
    if (!loginEmail.contains('@')) {
      // It's a username! We must look up the associated email in the database.
      final snapshot = await _dbRef
          .child('users')
          .orderByChild('username')
          .equalTo(loginEmail)
          .get();

      if (!snapshot.exists) {
        throw Exception('User with this username not found.');
      }

      // Extract the exact email address tied to this username
      final usersMap = snapshot.value as Map<dynamic, dynamic>;
      final userRecord = usersMap.values.first as Map<dynamic, dynamic>;
      
      if (userRecord['email'] == null) {
        throw Exception('Account configuration error: No email attached.');
      }
      
      loginEmail = userRecord['email'] as String;
    }

    // 2. Perform the actual Firebase Authentication with Email and Password
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );
      
      // 3. Verify they actually exist in the DB and pull their FULL data profile
      final uid = userCredential.user!.uid;
      final profileSnapshot = await _dbRef.child('users').child(uid).get();
      
      if (!profileSnapshot.exists) {
        await _auth.signOut();
        throw Exception('Account exists in Auth but is missing from Database records.');
      }
      
      final rawUserData = profileSnapshot.value as Map<dynamic, dynamic>;
      
      // Return a convenient bundle containing both the secure auth reference and UI data 
      return {
        'user': userCredential.user,
        'userData': Map<String, dynamic>.from(rawUserData),
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
