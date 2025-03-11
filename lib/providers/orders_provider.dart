import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';  // Use your existing model

final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: user.uid)
      .orderBy('orderDate', descending: true)
      .get();

  return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
});
