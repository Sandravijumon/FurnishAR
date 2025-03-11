import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'my_orders_screen.dart';
import 'edit_profile_screen.dart';
import 'payment_methods_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authStateProvider);
    final userProfileAsync = ref.watch(userProfileProvider); // ✅ Fetch Firestore user data

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
      ),
      body: userState.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text("No user logged in"));
          }

          return userProfileAsync.when(
            data: (userData) {
              if (userData == null) {
                return Center(child: Text("User data not found"));
              }

              return _buildProfileScreen(context, userData, ref); // ✅ Pass Firestore data
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text("Error: $error")),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text("Error: $error")),
      ),
    );
  }

  // ✅ Build Profile UI using Firestore Data
  Widget _buildProfileScreen(BuildContext context, Map<String, dynamic> userData, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Updated: Fetch name and email from Firestore
          Container(
            width: double.infinity,
            child: Card(
              color: Color(0xFFD8BFD8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim(), // ✅ Firestore name
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(height: 4),
                    Text(
                      userData['email'] ?? "example@gmail.com", // ✅ Firestore email
                      style: TextStyle(color: Colors.black54),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditProfileScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text("Edit Account", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),

          // ✅ Navigation to Profile Options
          _profileOption(context, Icons.shopping_cart, "My Orders", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrdersScreen()));
          }),
          _profileOption(context, Icons.payment_outlined, "Payment Method", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentMethodsScreen()));
          }),
          _profileOption(context, Icons.settings_outlined, "Settings", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
          }),

          // ✅ Logout Option
          _profileOption(context, Icons.logout, "Logout", () {
            ref.read(authServiceProvider).logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            );
          }, color: Colors.red),
        ],
      ),
    );
  }

  Widget _profileOption(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontSize: 16, color: color)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
