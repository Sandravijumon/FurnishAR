import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'package:furnishh_ar_app/providers/cart_provider.dart';
import 'package:furnishh_ar_app/screens/product_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HomeScreen extends ConsumerStatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String selectedCategory = "Popular"; // 🔹 Store the selected category

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);
    final user = FirebaseAuth.instance.currentUser; // ✅ Force-check login state
 // Get current user state

    // 🔹 Filter products based on search and category selection
    final filteredProducts = products.where((product) {
      bool matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesCategory = selectedCategory == "Popular" || product.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Color(0xFFD3D3D3), // Pastel Grey Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Text(
            "FurnishAR",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: const Color.fromARGB(255, 206, 177, 177),
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
         IconButton(
  icon: Icon(Icons.shopping_cart, color: Colors.black),
  onPressed: () {
    if (user != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  },
),

        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search for furniture",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            SizedBox(height: 15),

            // 🔹 Categories Selection
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryItem("Popular"),
                  _categoryItem("Chairs"),
                  _categoryItem("Tables"),
                  _categoryItem("Sofas"),
                  _categoryItem("Beds"),
                ],
              ),
            ),

            SizedBox(height: 15),

            // Product Grid
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(child: Text("No items found!", style: TextStyle(fontSize: 16)))
                  : GridView.builder(
                      itemCount: filteredProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _productItem(product);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Widget for Category Item (Handles Selection)
  Widget _categoryItem(String title) {
    bool isSelected = title == selectedCategory;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Chip(
          label: Text(title),
          backgroundColor: isSelected ? Colors.black : Colors.grey[300],
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  // Widget for Product Item
 Widget _productItem(Product product) {
  final cartNotifier = ref.read(cartProvider.notifier);

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
      );
    },
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Hero(
                tag: product.imageUrl,
                child: Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("₹${product.price}", style: TextStyle(color: Colors.green, fontSize: 14)),
                SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () => cartNotifier.addToCart(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Add to Cart", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

}