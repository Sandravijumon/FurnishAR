import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  File? _imageFile;
  File? _glbFile;
  bool _isLoading = false;

  Future<bool> _requestImagePermission() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    if (status.isDenied && Platform.isAndroid) {
      status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image access permission is required to select images',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enable image access permission in settings',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return false;
    }
    return status.isGranted;
  }

  Future<void> _pickImage() async {
    try {
      bool permissionGranted = await _requestImagePermission();
      if (!permissionGranted) return;

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _imageFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error picking image: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> _pickGlbFile() async {
    try {
      bool permissionGranted = await _requestStoragePermission();
      if (!permissionGranted) return;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow any file type and validate manually
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        if (filePath.toLowerCase().endsWith('.glb')) {
          setState(() {
            _glbFile = File(filePath);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select a .glb file',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No file selected',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Full error: ${e.toString()}'); // Detailed error logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error picking 3D file: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<String> _uploadFile(File file, String path) async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final storageRef = FirebaseStorage.instance.ref().child(path);
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty &&
        _descriptionController.text.isEmpty &&
        _priceController.text.isEmpty &&
        _quantityController.text.isEmpty &&
        _imageFile == null &&
        _glbFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All fields are empty!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _imageFile != null && _glbFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        String imageUrl = await _uploadFile(
          _imageFile!,
          'products/images/${DateTime.now().millisecondsSinceEpoch}_${_nameController.text}.jpg',
        );
        String glbUrl = await _uploadFile(
          _glbFile!,
          'products/3d_models/${DateTime.now().millisecondsSinceEpoch}_${_nameController.text}.glb',
        );

        await FirebaseFirestore.instance.collection('products').add({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'quantity': int.parse(_quantityController.text.trim()),
          'imageUrl': imageUrl,
          'glbUrl': glbUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product added successfully!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _quantityController.clear();
        setState(() {
          _imageFile = null;
          _glbFile = null;
        });
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all fields and select both files',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Product',
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
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(_nameController, 'Product Name', Icons.label, validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a product name';
                    return null;
                  }),
                  const SizedBox(height: 16),
                  _buildTextField(_descriptionController, 'Description', Icons.description, maxLines: 3, validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a description';
                    return null;
                  }),
                  const SizedBox(height: 16),
                  _buildTextField(_priceController, 'Price', Icons.currency_rupee, keyboardType: TextInputType.number, validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a price';
                    if (double.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  }),
                  const SizedBox(height: 16),
                  _buildTextField(_quantityController, 'Quantity', Icons.inventory, keyboardType: TextInputType.number, validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a quantity';
                    if (int.tryParse(value) == null) return 'Please enter a valid integer';
                    return null;
                  }),
                  const SizedBox(height: 16),
                  _buildFilePicker('Select Image', _imageFile, _pickImage),
                  const SizedBox(height: 16),
                  _buildFilePicker('Select 3D Image (.glb)', _glbFile, _pickGlbFile),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    )
                        : Text(
                      'Add Product',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFilePicker(String label, File? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(file == null ? Icons.upload : Icons.check, color: Colors.white70),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                file == null ? label : file.path.split('/').last,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}