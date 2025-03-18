import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ar_view_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;
  final String name;
  final String description;
  final num price;
  final String imageUrl;
  final String glbUrl;
  final num quantity;

  const ProductDetailsPage({
    super.key,
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.glbUrl,
    required this.quantity,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> with SingleTickerProviderStateMixin {
  bool _isAddingToCart = false;
  String? userEmail;
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('user_email');
    });
  }

  Future<void> _addToCart() async {
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email not found')),
      );
      return;
    }

    if (widget.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product is out of stock')),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartRef = FirebaseFirestore.instance.collection('cart');
      final querySnapshot = await cartRef.where('email', isEqualTo: userEmail).get();

      if (querySnapshot.docs.isEmpty) {
        await cartRef.add({
          'email': userEmail,
          'products': [
            {
              'productId': widget.productId,
              'name': widget.name,
              'quantity': 1,
              'price': widget.price,
              'imageUrl': widget.imageUrl,
            }
          ],
        });
      } else {
        final cartDoc = querySnapshot.docs.first;
        final cartData = cartDoc.data();
        List<dynamic> products = cartData['products'] ?? [];

        int index = products.indexWhere((item) => item['productId'] == widget.productId);
        if (index != -1) {
          if (products[index]['quantity'] >= widget.quantity) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not enough stock available')),
            );
            setState(() {
              _isAddingToCart = false;
            });
            return;
          }
          products[index]['quantity'] = products[index]['quantity'] + 1;
        } else {
          products.add({
            'productId': widget.productId,
            'name': widget.name,
            'quantity': 1,
            'price': widget.price,
            'imageUrl': widget.imageUrl,
          });
        }

        await cartDoc.reference.update({'products': products});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  Future<void> _showReviewDialog({String? existingReview}) async {
    _reviewController.text = existingReview ?? '';
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existingReview == null ? 'Add Review' : 'Edit Review',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Review',
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
                if (_reviewController.text.trim().isNotEmpty && userEmail != null) {
                  await _addOrUpdateReview();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a review')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addOrUpdateReview() async {
    final productRef = FirebaseFirestore.instance.collection('products').doc(widget.productId);
    final docSnapshot = await productRef.get();
    final data = docSnapshot.data() ?? {};

    List<dynamic> reviews = data['reviews'] != null ? List.from(data['reviews']) : [];
    final reviewEntry = {userEmail!: _reviewController.text.trim()};

    int existingIndex = reviews.indexWhere((review) => review.containsKey(userEmail));
    if (existingIndex != -1) {
      reviews[existingIndex] = reviewEntry;
    } else {
      reviews.add(reviewEntry);
    }

    await productRef.set(
      {'reviews': reviews},
      SetOptions(merge: true),
    );
  }

  bool _hasUserReviewed(List<dynamic> reviews) {
    return userEmail != null && reviews.any((review) => review.containsKey(userEmail));
  }

  String? _getUserReview(List<dynamic> reviews) {
    if (userEmail == null) return null;
    final review = reviews.firstWhere((r) => r.containsKey(userEmail), orElse: () => {});
    return review[userEmail] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name,
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade900, Colors.purple.shade600.withOpacity(0.8)],
              ),
            ),
          ),
          Column(
            children: [
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    height: 350,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.blue)),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.blue, size: 50),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Text(
                      widget.name,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Price',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              Text(
                                '₹${widget.price}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Description',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.description,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.quantity <= 0 ? 'Out of Stock' : 'In Stock: ${widget.quantity}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.quantity <= 0 ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            alignment: WrapAlignment.center,
                            children: [
                              ScaleTransition(
                                scale: _buttonScaleAnimation,
                                child: GestureDetector(
                                  onTapDown: (_) => _animationController.forward(),
                                  onTapUp: (_) => _animationController.reverse(),
                                  onTapCancel: () => _animationController.reverse(),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ARViewPage(glbUrl: widget.glbUrl),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.purple.shade700, Colors.blue.shade900],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                        const SizedBox(width: 5),
                                        Text(
                                          'View in AR',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ScaleTransition(
                                scale: _buttonScaleAnimation,
                                child: GestureDetector(
                                  onTapDown: widget.quantity <= 0 || _isAddingToCart
                                      ? null
                                      : (_) => _animationController.forward(),
                                  onTapUp: widget.quantity <= 0 || _isAddingToCart
                                      ? null
                                      : (_) => _animationController.reverse(),
                                  onTapCancel: widget.quantity <= 0 || _isAddingToCart
                                      ? null
                                      : () => _animationController.reverse(),
                                  onTap: widget.quantity <= 0 || _isAddingToCart ? null : _addToCart,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: widget.quantity <= 0 || _isAddingToCart
                                          ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                                          : LinearGradient(
                                        colors: [Colors.blue.shade900, Colors.purple.shade700],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart,
                                          color: widget.quantity <= 0 || _isAddingToCart ? Colors.black54 : Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 5),
                                        _isAddingToCart
                                            ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                            : Text(
                                          'Add to Cart',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: widget.quantity <= 0 || _isAddingToCart
                                                ? Colors.black54
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance.collection('products').doc(widget.productId).snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || !snapshot.data!.exists) {
                                    return ScaleTransition(
                                      scale: _buttonScaleAnimation,
                                      child: GestureDetector(
                                        onTapDown: (_) => _animationController.forward(),
                                        onTapUp: (_) => _animationController.reverse(),
                                        onTapCancel: () => _animationController.reverse(),
                                        onTap: () => _showReviewDialog(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.blue.shade900, Colors.purple.shade700],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.rate_review, color: Colors.white, size: 18),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Add Review',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                                  final reviews = data['reviews'] != null ? List<dynamic>.from(data['reviews']) : <dynamic>[];
                                  final hasReviewed = _hasUserReviewed(reviews);
                                  final userReview = _getUserReview(reviews);

                                  return ScaleTransition(
                                    scale: _buttonScaleAnimation,
                                    child: GestureDetector(
                                      onTapDown: (_) => _animationController.forward(),
                                      onTapUp: (_) => _animationController.reverse(),
                                      onTapCancel: () => _animationController.reverse(),
                                      onTap: () => _showReviewDialog(existingReview: userReview),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.blue.shade900, Colors.purple.shade700],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.rate_review, color: Colors.white, size: 18),
                                            const SizedBox(width: 5),
                                            Text(
                                              hasReviewed ? 'Edit Review' : 'Add Review',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('products').doc(widget.productId).snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Colors.blue));
                              }
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }

                              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                              final reviews = data['reviews'] != null ? List<dynamic>.from(data['reviews']) : <dynamic>[];

                              return reviews.isNotEmpty
                                  ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reviews',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...reviews.map((review) {
                                    final email = review.keys.first;
                                    final reviewText = review.values.first;
                                    final isUserReview = email == userEmail;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 5.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isUserReview ? 'Your Review' : email,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            reviewText,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const Divider(),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              )
                                  : const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 20), // Extra padding at the bottom
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}