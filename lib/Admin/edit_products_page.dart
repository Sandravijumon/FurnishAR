import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';

class EditProductsPage extends StatefulWidget {
  const EditProductsPage({super.key});

  @override
  State<EditProductsPage> createState() => _EditProductsPageState();
}

class _EditProductsPageState extends State<EditProductsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Products',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No products found',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var product = snapshot.data!.docs[index];
                return _buildProductCard(
                  product.id,
                  product['name'],
                  product['description'],
                  product['price'].toString(),
                  product['quantity'].toString(),
                  product['imageUrl'],
                  product['glbUrl'],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(
      String id,
      String name,
      String description,
      String price,
      String quantity,
      String imageUrl,
      String glbUrl,
      ) {
    return GestureDetector(
      onTap: () => _showEditDialog(id, name, description, price, quantity, imageUrl, glbUrl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(16.0),
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
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: ₹$price | Quantity: $quantity',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
      String id,
      String name,
      String description,
      String price,
      String quantity,
      String imageUrl,
      String glbUrl,
      ) async {
    final nameController = TextEditingController(text: name);
    final descriptionController = TextEditingController(text: description);
    final priceController = TextEditingController(text: price);
    final quantityController = TextEditingController(text: quantity);
    File? newImageFile;
    File? newGlbFile;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(
                'Edit Product',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Product Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: quantityController,
                      decoration: InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.upload),
                          onPressed: () async {
                            bool permissionGranted = await _requestStoragePermission();
                            if (!permissionGranted) return;
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );
                            if (result != null && result.files.single.path != null) {
                              setState(() {
                                newImageFile = File(result.files.single.path!);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (newImageFile != null)
                      Text(
                        'New Image: ${newImageFile!.path.split('/').last}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '3D Model: ${glbUrl.split('/').last}',
                            style: GoogleFonts.poppins(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.upload),
                          onPressed: () async {
                            bool permissionGranted = await _requestStoragePermission();
                            if (!permissionGranted) return;
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.any,
                              allowMultiple: false,
                            );
                            if (result != null && result.files.single.path != null) {
                              String filePath = result.files.single.path!;
                              if (filePath.toLowerCase().endsWith('.glb')) {
                                setState(() {
                                  newGlbFile = File(filePath);
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please select a .glb file'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    if (newGlbFile != null)
                      Text(
                        'New 3D Model: ${newGlbFile!.path.split('/').last}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.blue.shade900)),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    bool confirmed = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Confirm Delete', style: GoogleFonts.poppins()),
                        content: Text('Are you sure you want to delete this product?', style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('No', style: GoogleFonts.poppins(color: Colors.blue.shade900)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Yes', style: GoogleFonts.poppins(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      setState(() => isLoading = true);
                      try {
                        // Delete files from Storage
                        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                        await FirebaseStorage.instance.refFromURL(glbUrl).delete();
                        // Delete document from Firestore
                        await FirebaseFirestore.instance.collection('products').doc(id).delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Product deleted successfully!',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(context).pop(); // Close dialog
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting product: $e', style: GoogleFonts.poppins(color: Colors.white)),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    }
                  },
                  child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    // Check for empty fields
                    if (nameController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        quantityController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please fill all fields',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() => isLoading = true);
                    try {
                      String? updatedImageUrl = imageUrl;
                      String? updatedGlbUrl = glbUrl;

                      if (newImageFile != null) {
                        updatedImageUrl = await _uploadFile(
                          newImageFile!,
                          'products/images/${DateTime.now().millisecondsSinceEpoch}_${nameController.text}.jpg',
                        );
                      }
                      if (newGlbFile != null) {
                        updatedGlbUrl = await _uploadFile(
                          newGlbFile!,
                          'products/3d_models/${DateTime.now().millisecondsSinceEpoch}_${nameController.text}.glb',
                        );
                      }

                      await FirebaseFirestore.instance.collection('products').doc(id).update({
                        'name': nameController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'price': double.parse(priceController.text.trim()),
                        'quantity': int.parse(quantityController.text.trim()),
                        'imageUrl': updatedImageUrl,
                        'glbUrl': updatedGlbUrl,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Product updated successfully!',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e', style: GoogleFonts.poppins(color: Colors.white)),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() => isLoading = false);
                    }
                  },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _requestStoragePermission() async {
    // Skip permission request on Android 13+ (API 33+)
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      int sdkInt = androidInfo.version.sdkInt ?? 0;
      if (sdkInt >= 33) {
        // On Android 13+, file_picker doesn't need storage permission
        return true;
      }
    }

    // For Android 12 and below, request legacy storage permission
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (status.isDenied || status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Storage permission is required to select files',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          action: status.isPermanentlyDenied
              ? SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          )
              : null,
        ),
      );
      return false;
    }
    return true;
  }

  Future<String> _uploadFile(File file, String path) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(path);
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }
}