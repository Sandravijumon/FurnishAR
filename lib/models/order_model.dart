import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String status;
  final double totalAmount;
  final DateTime orderDate;
  final List<OrderItem> items;

  OrderModel({
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.orderDate,
    required this.items,
  });

  // Convert Firestore document to OrderModel
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OrderModel(
      orderId: data['orderId'] ?? '',
      status: data['status'] ?? 'Pending',
      totalAmount: (data['totalAmount'] as num).toDouble(),
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      items: (data['items'] as List<dynamic>).map((item) => OrderItem.fromMap(item)).toList(),
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
    );
  }
}
