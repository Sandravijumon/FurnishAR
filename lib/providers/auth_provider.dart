import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔹 Provider for AuthService (Handles Authentication)
final authServiceProvider = Provider((ref) => AuthService(ref));

// 🔹 Provider to watch authentication state (Detects login/logout changes)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});



// 🔹 Provider to fetch user profile details from Firestore
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  return snapshot.data();
});

class AuthService {
  final Ref ref;
  AuthService(this.ref);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Sign Up Method (Registers User & Saves Data in Firestore)
  Future<User?> signUp(
    String email, 
    String password, 
    String firstName, 
    String lastName, 
    String mobile, 
    String address
  ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'firstName': firstName,
          'lastName': lastName,
          'mobile': mobile,
          'address': address,
          'email': email,
          'createdAt': Timestamp.now(),
        });
      }
      return user;
    } catch (e) {
      print("Sign Up Error: $e");
      return null;
    }
  }

  // 🔹 Login Method (Authenticates User)
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // 🔹 Logout Method (Signs Out User)
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 🔹 Update User Profile (Modifies Profile Details in Firestore)
  Future<void> updateProfile(String firstName, String lastName, String mobile, String address) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'mobile': mobile,
        'address': address,
      });

      // Refresh user data
      ref.refresh(userProfileProvider);
    }
  }
}
