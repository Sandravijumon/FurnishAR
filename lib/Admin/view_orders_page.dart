import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewOrdersPage extends StatefulWidget {
  const ViewOrdersPage({super.key});

  @override
  State<ViewOrdersPage> createState() => _ViewOrdersPageState();
}

class _ViewOrdersPageState extends State<ViewOrdersPage> {
  Future<void> _selectDate(BuildContext context, String orderId, String? currentDeliveryDate) async {
    DateTime initialDate;
    try {
      if (currentDeliveryDate != null && currentDeliveryDate.isNotEmpty && currentDeliveryDate != 'Not specified') {
        initialDate = DateFormat('yyyy-MM-dd').parse(currentDeliveryDate);
      } else {
        initialDate = DateTime.now();
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      );

      if (picked != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'delivery_date': formattedDate,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting date: $e')),
      );
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Orders',
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
              colors: [Colors.blue.shade900, Colors.purple.shade600],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.purple.shade600],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No orders found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
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
                final email = order['email'] ?? 'Unknown';
                final status = order['status'] ?? 'Pending';
                final products = order['products'] as List<dynamic>? ?? [];
                final feedback = order['feedback'] ?? '';
                final createdAt = (order['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
                final deliveryDate = order['delivery_date'] ?? 'Not specified';
                final shippingAddress = order['shipping_address'] ?? 'Not specified';

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
                  color: Colors.white.withOpacity(0.1),
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'User Email: $email',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Date: ${createdAt.toLocal().toString().split(' ')[0]}',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery Date: ${deliveryDate == 'Not specified' ? 'Not set' : deliveryDate}',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                            ),
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.calendar_today, color: Colors.white),
                                onPressed: () => _selectDate(context, orderId, deliveryDate),
                                tooltip: 'Set Delivery Date',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Shipping Address: $shippingAddress',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status: ',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                            ),
                            DropdownButton<String>(
                              value: status,
                              dropdownColor: Colors.teal.withOpacity(0.9),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              items: <String>['Pending', 'Delivered'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  _updateStatus(orderId, newValue);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                                        child: CircularProgressIndicator(color: Colors.white)),
                                    errorWidget: (context, url, error) =>
                                    const Icon(Icons.error, color: Colors.white, size: 30),
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
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Price: ₹$price x $quantity = ₹${(price * quantity).toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        if (status == 'Delivered' && feedback.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Feedback: $feedback',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                          ),
                        ],
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