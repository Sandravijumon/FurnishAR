import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String? userEmail;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _shippingAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _shippingAddressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('user_email');
    });
  }

  Future<void> _showFeedbackDialog(String orderId, String currentFeedback) async {
    _feedbackController.text = currentFeedback;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Feedback', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _feedbackController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Feedback',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_feedbackController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({'feedback': _feedbackController.text});
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditShippingAddressDialog(String orderId, String currentAddress) async {
    _shippingAddressController.text = currentAddress;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Shipping Address', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _shippingAddressController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Shipping Address',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_shippingAddressController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({'shipping_address': _shippingAddressController.text.trim()});
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Orders',
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
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.tealAccent, Colors.blue.shade700],
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('email', isEqualTo: userEmail)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.teal));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No orders found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.teal,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            final orders = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index].data() as Map<String, dynamic>? ?? {};
                final orderId = orders[index].id;
                final status = order['status'] ?? 'Unknown';
                final products = order['products'] as List<dynamic>? ?? [];
                final feedback = order['feedback'] ?? '';
                final delivery_date = order['delivery_date'] ?? '';
                final shippingAddress = order['shipping_address'] ?? 'Not specified';
                final createdAt = (order['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();

                final double totalAmount = products.fold(
                  0.0,
                      (sum, item) => sum + ((item['price'] as num? ?? 0) * (item['quantity'] as num? ?? 0).toInt()),
                );

                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${orderId.substring(0, 8)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Status: $status',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Date: ${createdAt.toLocal().toString().split(' ')[0]}',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Delivery Date: $delivery_date',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Shipping Address: $shippingAddress',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ),
                            if (status == 'Pending') ...[
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.teal),
                                onPressed: () => _showEditShippingAddressDialog(orderId, shippingAddress),
                                tooltip: 'Edit Shipping Address',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        const SizedBox(height: 10),
                        ...products.map((product) {
                          final name = product['name'] ?? 'Unnamed';
                          final price = product['price'] ?? 0;
                          final quantity = (product['quantity'] as num? ?? 0).toInt();
                          final imageUrl = product['imageUrl'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(color: Colors.teal)),
                                    errorWidget: (context, url, error) =>
                                    const Icon(Icons.error, color: Colors.teal, size: 30),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Price: ₹$price x $quantity = ₹${(price * quantity).toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        if (feedback.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Your Feedback: $feedback',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 'Delivered') ...[
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.teal),
                                onPressed: () => _showFeedbackDialog(orderId, feedback),
                                tooltip: 'Add Feedback',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}