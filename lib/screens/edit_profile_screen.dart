import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: userProfileAsync.when(
        data: (userData) {
          if (userData != null) {
            firstNameController.text = userData['firstName'] ?? '';
            lastNameController.text = userData['lastName'] ?? '';
            mobileController.text = userData['mobile'] ?? '';
            addressController.text = userData['address'] ?? '';
          }

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: "First Name"),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: "Last Name"),
                ),
                TextField(
                  controller: mobileController,
                  decoration: InputDecoration(labelText: "Mobile"),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: "Address"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await authService.updateProfile(
                      firstNameController.text,
                      lastNameController.text,
                      mobileController.text,
                      addressController.text,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Profile updated successfully!")),
                    );
                    Navigator.pop(context);
                  },
                  child: Text("Save Changes"),
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text("Error: $error")),
      ),
    );
  }
}
