class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String mobile;
  final String address;
  final String email;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.address,
    required this.email,
  });

  // Convert UserModel to Map (For Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'address': address,
      'email': email,
      'createdAt': DateTime.now(),
    };
  }

  // Convert Firestore Document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      mobile: map['mobile'],
      address: map['address'],
      email: map['email'],
    );
  }
}
