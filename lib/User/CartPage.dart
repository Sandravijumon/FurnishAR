import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String? userEmail;
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _cvvController = TextEditingController();
  final _shippingAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _cvvController.dispose();
    _shippingAddressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('user_email');
    });
  }

  Future<void> _updateQuantity(String cartId, Map<String, dynamic> product, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(cartId, product);
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection('cart').doc(cartId);
    final cartDoc = await cartRef.get();
    final cartData = cartDoc.data() as Map<String, dynamic>?;
    List<dynamic> products = cartData?['products'] ?? [];

    int index = products.indexWhere((item) => item['productId'] == product['productId']);
    if (index != -1) {
      products[index]['quantity'] = newQuantity;
      await cartRef.update({'products': products});
    }
  }

  Future<void> _removeItem(String cartId, Map<String, dynamic> product) async {
    final cartRef = FirebaseFirestore.instance.collection('cart').doc(cartId);
    final cartDoc = await cartRef.get();
    final cartData = cartDoc.data() as Map<String, dynamic>?;
    List<dynamic> products = cartData?['products'] ?? [];

    products.removeWhere((item) => item['productId'] == product['productId']);
    if (products.isEmpty) {
      await cartRef.delete();
    } else {
      await cartRef.update({'products': products});
    }
  }

  Future<bool> _checkStockAvailability(List<dynamic> cartProducts) async {
    for (var product in cartProducts) {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(product['productId'])
          .get();
      if (!productDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product['name']} is no longer available')),
        );
        return false;
      }
      final productData = productDoc.data() as Map<String, dynamic>?;
      final availableQuantity = productData?['quantity'] as num? ?? 0;
      if (product['quantity'] > availableQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock for ${product['name']}. Available: $availableQuantity')),
        );
        return false;
      }
    }
    return true;
  }
  Future<void> _processOrder(String cartId, List<dynamic> cartProducts) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitCircle(color: Colors.blue),
            SizedBox(height: 20),
            Text('Processing your order...'),
          ],
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // ... existing transaction code remains the same ...

        final productDocs = <DocumentSnapshot>[];
        for (var product in cartProducts) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(product['productId']);
          final productDoc = await transaction.get(productRef);
          productDocs.add(productDoc);
        }

        for (int i = 0; i < cartProducts.length; i++) {
          final product = cartProducts[i];
          final productDoc = productDocs[i];
          if (!productDoc.exists) {
            throw Exception('${product['name']} no longer exists');
          }
          final productData = productDoc.data() as Map<String, dynamic>?;
          final currentQuantity = productData?['quantity'] as num? ?? 0;
          final newQuantity = currentQuantity - (product['quantity'] as num? ?? 0);
          if (newQuantity < 0) {
            throw Exception('Not enough stock for ${product['name']}');
          }
          final productRef = FirebaseFirestore.instance.collection('products').doc(product['productId']);
          transaction.update(productRef, {'quantity': newQuantity});
        }

        final orderRef = FirebaseFirestore.instance.collection('orders').doc();
        transaction.set(orderRef, {
          'products': cartProducts,
          'email': userEmail,
          'shipping_address': _shippingAddressController.text.trim(),
          'status': 'Pending',
          'delivery_date': 'Not specified',
          'feedback': '',
          'created_at': Timestamp.now(),
        });

        final cartRef = FirebaseFirestore.instance.collection('cart').doc(cartId);
        transaction.delete(cartRef);
      });

      // Close loading dialog
      Navigator.pop(context);

      // Show success GIF dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/success.gif',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 20),
              Text(
                'Order placed successfully!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      // Close loading dialog if open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $error')),
      );
    }
  }

  void _showPaymentModal(double totalPrice, String cartId, List<dynamic> cartProducts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Payment Details',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    readOnly: true,
                    initialValue: '₹${totalPrice.toStringAsFixed(2)}',
                    decoration: InputDecoration(
                      labelText: 'Total Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: InputDecoration(
                      labelText: 'Card Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    validator: (value) {
                      if (value == null || value.length != 16 || !RegExp(r'^\d{16}$').hasMatch(value)) {
                        return 'Enter a valid 16-digit card number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _monthController,
                          decoration: InputDecoration(
                            labelText: 'MM',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter month';
                            }
                            final month = int.tryParse(value);
                            if (month == null || month < 1 || month > 12) {
                              return 'Enter a valid month (01-12)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _yearController,
                          decoration: InputDecoration(
                            labelText: 'YY',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter year';
                            }
                            final year = int.tryParse(value);
                            if (year == null || year < 0 || year > 99) {
                              return 'Enter a valid year (00-99)';
                            }

                            final monthValue = _monthController.text;
                            if (monthValue.isEmpty) {
                              return 'Enter month first';
                            }
                            final month = int.tryParse(monthValue);
                            if (month == null || month < 1 || month > 12) {
                              return 'Fix month first';
                            }

                            final now = DateTime.now();
                            final currentYear = now.year % 100;
                            final currentMonth = now.month;
                            final expiryYear = year;
                            final expiryMonth = month;

                            if (expiryYear < currentYear ||
                                (expiryYear == currentYear && expiryMonth < currentMonth)) {
                              return 'Card has expired';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    validator: (value) {
                      if (value == null || value.length != 3 || !RegExp(r'^\d{3}$').hasMatch(value)) {
                        return 'Enter a valid 3-digit CVV';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _shippingAddressController,
                    decoration: InputDecoration(
                      labelText: 'Shipping Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a shipping address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context); // Close the modal
                        await _processOrder(cartId, cartProducts);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Pay Now',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cart',
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
              colors: [Colors.blue.shade900, Colors.purple.shade700],
            ),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cart')
              .where('email', isEqualTo: userEmail)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.blue));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'Your cart is empty',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.blue.shade900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            final cartDoc = snapshot.data!.docs.first;
            final cartData = cartDoc.data() as Map<String, dynamic>?;
            final List<dynamic> products = cartData?['products'] ?? [];
            final double totalPrice = products.fold(
              0.0,
                  (sum, item) => sum + ((item['quantity'] as num? ?? 0).toInt() * (item['price'] as num? ?? 0)),
            );

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index] as Map<String, dynamic>? ?? {};
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: product['imageUrl'] ?? '',
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(color: Colors.blue)),
                                  errorWidget: (context, url, error) =>
                                  const Icon(Icons.error, color: Colors.blue, size: 40),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? 'Unnamed',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Price: ₹${product['price'] ?? 0}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () {
                                            _updateQuantity(
                                              cartDoc.id,
                                              product,
                                              (product['quantity'] as num? ?? 0).toInt() - 1,
                                            );
                                          },
                                        ),
                                        Text(
                                          '${(product['quantity'] as num? ?? 0).toInt()}',
                                          style: GoogleFonts.poppins(fontSize: 16),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle, color: Colors.green),
                                          onPressed: () {
                                            _updateQuantity(
                                              cartDoc.id,
                                              product,
                                              (product['quantity'] as num? ?? 0).toInt() + 1,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _removeItem(cartDoc.id, product);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ₹${totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final stockAvailable = await _checkStockAvailability(products);
                          if (stockAvailable) {
                            _showPaymentModal(totalPrice, cartDoc.id, products);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Checkout',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}