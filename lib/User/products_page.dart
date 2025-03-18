import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_details_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _searchQuery = '';
  String _sortOrder = 'None'; // Options: 'None', 'High to Low', 'Low to High'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Products',
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
        iconTheme: const IconThemeData(color: Colors.white),
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
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.purple.shade600.withOpacity(0.8)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100), // Space for AppBar
              Container(
                height: MediaQuery.of(context).size.height - 100, // Adjust height to fill remaining space
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildFilterOptions(),
                      const SizedBox(height: 20),
                      _buildProductsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search products by name...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          prefixIcon: Icon(Icons.search, color: Colors.blue.shade900),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.blue.shade900),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
          )
              : null,
        ),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.blue.shade900,
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sort by Price',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          DropdownButton<String>(
            value: _sortOrder,
            items: <String>['None', 'High to Low', 'Low to High'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blue.shade900,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _sortOrder = newValue!;
              });
            },
            underline: Container(),
            icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blue));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'No products available yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.blue.shade900,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        List<DocumentSnapshot> products = snapshot.data!.docs;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          products = products.where((doc) {
            final name = doc['name']?.toString().toLowerCase() ?? '';
            return name.contains(_searchQuery);
          }).toList();
        }

        // Apply sort filter
        if (_sortOrder != 'None') {
          products.sort((a, b) {
            final priceA = a['price'] as num? ?? 0;
            final priceB = b['price'] as num? ?? 0;
            return _sortOrder == 'High to Low' ? priceB.compareTo(priceA) : priceA.compareTo(priceB);
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Products',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  var product = products[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsPage(
                            productId: product.id,
                            name: product['name'],
                            description: product['description'],
                            price: product['price'] as num,
                            imageUrl: product['imageUrl'],
                            glbUrl: product['glbUrl'],
                            quantity: product['quantity'] as num,
                          ),
                        ),
                      );
                    },
                    child: _buildProductCard(
                      product['name'],
                      product['price'].toString(),
                      product['imageUrl'],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(String name, String price, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.blue)),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.blue, size: 50),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹$price',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}