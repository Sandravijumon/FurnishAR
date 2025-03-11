import 'package:flutter/material.dart';
import '../models/product.dart';
import 'ar_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Hero(
            tag: product.imageUrl,
            child: Image.network(product.imageUrl, width: double.infinity, height: 300, fit: BoxFit.cover),
          ),

          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "Rs. ${product.price}",
                  style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 10),

                // View in 3D Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ARScreen(product: product)),
                    );
                  },
                  icon: Icon(Icons.view_in_ar),
                  label: Text("View in 3D"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                SizedBox(height: 20),

                // Description
                Text(
                  "High-quality ${product.name} with premium design.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
