import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:furnishh_ar_app/models/user_models.dart';

// 🔹 Provide AuthService globally
final authServiceProvider = Provider((ref) => AuthService(ref));

// 🔹 Listen to Firebase Auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final Ref ref;
  AuthService(this.ref);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Sign Up Method
 Future<User?> signUp(
    String email, String password, String firstName, String lastName, String mobile, String address) async {
  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      // ✅ Set Firebase Auth Display Name
      await user.updateDisplayName("$firstName $lastName");
      await user.reload(); // Force update user details

      // ✅ Create a UserModel instance
      UserModel newUser = UserModel(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        mobile: mobile,
        address: address,
        email: email,
      );

      // ✅ Store user details in Firestore
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // ✅ Update Riverpod auth state
      ref.read(authStateProvider);

      return _auth.currentUser; // Return updated user
    }
    return null;
  } catch (e) {
    print("Sign Up Error: $e");
    return Future.error("Failed to sign up: ${e.toString()}");
  }
}



  // 🔹 Login Method
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Update Riverpod auth state
      ref.read(authStateProvider);
      return userCredential.user;
    } catch (e) {
      print("Login Error: $e");
      return Future.error("Failed to log in: ${e.toString()}");
    }
  }

  // 🔹 Logout Method
  Future<void> logout() async {
    await _auth.signOut();
    ref.read(authStateProvider);
  }

  // 🔹 Fetch User Data from Firestore
  Future<UserModel?> fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      print("Fetch User Error: $e");
      return null;
    }
  }

  // 🔹 Get Current User
  User? get currentUser => _auth.currentUser;
}
