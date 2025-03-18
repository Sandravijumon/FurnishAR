import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:placeit/auth_screen.dart';
import 'package:placeit/Admin/view_users_page.dart';
import 'package:placeit/Admin/add_product_page.dart';
import 'package:placeit/Admin/edit_products_page.dart';
import 'package:placeit/Admin/view_orders_page.dart';
import 'package:placeit/Admin/view_reviews_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('orders').get();
    final totalOrders = querySnapshot.docs.length;
    double totalEarnings = 0.0;
    for (var doc in querySnapshot.docs) {
      final order = doc.data();
      final products = order['products'] as List<dynamic>? ?? [];
      final orderTotal = products.fold<double>(
        0.0,
            (sum, item) => sum + ((item['price'] as num? ?? 0) * (item['quantity'] as num? ?? 0).toInt()),
      );
      totalEarnings += orderTotal;
    }
    return {
      'totalOrders': totalOrders.toString(),
      'totalEarnings': totalEarnings.toStringAsFixed(2),
    };
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _showValueDialog(BuildContext context, String title, String value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          content: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Ensure no default background
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background that fills the entire screen
          Container(
            height: MediaQuery.of(context).size.height, // Ensure full screen height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade900, Colors.purple.shade600],
              ),
            ),
          ),
          // Scrollable content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin!',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your platform efficiently',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Analytics Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _fetchAnalyticsData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Error loading analytics',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      final totalOrders = data['totalOrders'] ?? '0';
                      final totalEarnings = data['totalEarnings'] ?? '0.00';

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAnalyticsCard(
                            context,
                            'Total Orders',
                            totalOrders,
                            Icons.shopping_cart,
                          ),
                          _buildAnalyticsCard(
                            context,
                            'Total Earnings',
                            '₹$totalEarnings',
                            Icons.currency_rupee,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Management Options',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    context,
                    'View Users',
                    'View registered users',
                    Icons.people,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ViewUsersPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildOptionCard(
                    context,
                    'Add New Product',
                    'Add products to the catalog',
                    Icons.add_box,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddProductPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildOptionCard(
                    context,
                    'Edit Products',
                    'Modify existing product details',
                    Icons.edit,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProductsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildOptionCard(
                    context,
                    'View Orders',
                    'See all user orders',
                    Icons.list_alt,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ViewOrdersPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildOptionCard(
                    context,
                    'View Reviews',
                    'See all user reviews',
                    Icons.list_alt,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ViewReviewsPage()),
                          );

                    },
                  ),
                  const SizedBox(height: 24), // Add spacing at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showValueDialog(context, title, value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white70, size: 28),
                  Flexible(
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}