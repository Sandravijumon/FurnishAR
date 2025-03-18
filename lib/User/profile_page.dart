import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Required for inputFormatters

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? email;
  String name = '';
  String phone = '';
  bool _isLoading = true;
  bool _isSaving = false;
  DocumentReference? _userDocRef; // To store the reference of the matching document

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('user_email');

    if (email != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first; // Get the first matching document
          setState(() {
            _userDocRef = doc.reference;
            name = doc['name'] ?? '';
            phone = doc['phone'] ?? '';
            _nameController.text = name;
            _phoneController.text = phone;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No profile found for this email')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email found in preferences')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_userDocRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No profile found to update')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      await _userDocRef!.update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      setState(() {
        name = _nameController.text.trim();
        phone = _phoneController.text.trim();
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade900, Colors.purple.shade700],
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity, // Ensure full height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.purple.shade600.withOpacity(0.8)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 120), // Space for AppBar
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Update your details below',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Email (Read-only)
                      Text(
                        'Email',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          email ?? 'Not available',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Name (Editable, Optional)
                      Text(
                        'Name',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                        validator: (value) => null, // No validation
                      ),
                      const SizedBox(height: 20),
                      // Phone (Editable, Optional, Limited to 10 Digits)
                      Text(
                        'Phone',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // Allow only digits
                          LengthLimitingTextInputFormatter(10), // Limit to 10 digits
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null; // Empty is allowed
                        },
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isSaving || _userDocRef == null ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}