import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

class CartScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final double totalPrice = cartNotifier.totalPrice;
    final user = FirebaseAuth.instance.currentUser; // ✅ Get the current user

    return Scaffold(
      appBar: AppBar(title: Text("Shopping Cart")),
      body: cartItems.isEmpty
          ? Center(child: Text("Your cart is empty!"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final product = cartItems[index];
                      return ListTile(
                        leading: Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                        title: Text(product.name),
                        subtitle: Text("₹${product.price.toStringAsFixed(2)}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => cartNotifier.removeFromCart(product),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text("Total: ₹${totalPrice.toStringAsFixed(2)}", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      SizedBox(height: 10),

                      // ✅ Proceed to Checkout Button (Now Saves Order in Firestore)
                      ElevatedButton(
                        onPressed: () async {
                          if (user == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Please log in to checkout!"))
  );
  return;
}


                          await saveOrder(cartItems, totalPrice, user.uid); // ✅ Save Order
                          cartNotifier.clearCart(); // ✅ Clear cart after checkout

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Order placed successfully!"))
                          );
                        },
                        child: Text("Proceed to Checkout"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ✅ Function to Save Order in Firestore
  Future<void> saveOrder(List<Product> cartItems, double totalPrice, String userId) async {
    final orderId = FirebaseFirestore.instance.collection('orders').doc().id;
    
    final orderData = {
      'orderId': orderId,
      'totalAmount': totalPrice,
      'timestamp': Timestamp.now(),
      'items': cartItems.map((product) => {
        'name': product.name,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'quantity': 1, // Modify based on actual quantity logic
      }).toList(),
    };

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(userId)
        .collection('userOrders')
        .doc(orderId)
        .set(orderData);
  }
}
