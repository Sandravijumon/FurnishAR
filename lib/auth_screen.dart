import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:placeit/Admin/admin_page.dart';
import 'package:placeit/User/user_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool isLoading = false;
  bool _isPasswordVisible = false; // Track password visibility
  bool _isConfirmPasswordVisible = false; // Track confirm password visibility
  late AnimationController _controller;
  late Animation<double> _animation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_email', _emailController.text.trim());
        } catch (e) {
          print('Failed to save email to Shared Preferences: $e');
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.email == 'admin@gmail.com') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserPage()),
          );
        }
      } else {
        if (_passwordController.text == _confirmPasswordController.text) {
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          if (_emailController.text.trim().toLowerCase() != "admin@gmail.com") {
            await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
              'email': _emailController.text.trim(),
              'name': '',
              'phone': '',
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration Successful',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() {
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            isLogin = true;
            _controller.reverse();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Passwords do not match',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          break;
        case 'wrong-password':
          errorMessage = 'Invalid password.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password.';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _clearFieldsAndToggleMode() {
    setState(() {
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      isLogin = !isLogin;
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
      isLogin ? _controller.reverse() : _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.purple.shade600],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 60,
                        height: 60,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      isLogin ? 'Welcome Back' : 'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isLogin ? 'Sign in to continue' : 'Join us today',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildTextField(_emailController, 'Email', Icons.email),
                    const SizedBox(height: 20),
                    _buildTextField(
                      _passwordController,
                      'Password',
                      Icons.lock,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      toggleVisibility: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    if (!isLogin)
                      FadeTransition(
                        opacity: _animation,
                        child: _buildTextField(
                          _confirmPasswordController,
                          'Confirm Password',
                          Icons.lock,
                          isPassword: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          toggleVisibility: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: isLoading ? null : _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade900),
                        ),
                      )
                          : Text(
                        isLogin ? 'Login' : 'Register',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _clearFieldsAndToggleMode,
                      child: Text(
                        isLogin
                            ? "Don't have an account? Register"
                            : 'Already have an account? Login',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isPassword = false,
        bool isPasswordVisible = false,
        VoidCallback? toggleVisibility,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: toggleVisibility,
        )
            : null,
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}