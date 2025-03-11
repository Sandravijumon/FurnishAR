import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/orders_provider.dart';
import '../models/order_model.dart'; // Use your existing model

class MyOrdersScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("My Orders"),
        centerTitle: true,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(child: Text("No orders found!"));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
                child: ExpansionTile(
                  title: Text("Order ID: ${order.orderId}", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${order.status}", style: TextStyle(color: Colors.green)),
                      Text("Total: ₹${order.totalAmount.toStringAsFixed(2)}"),
                      Text("Date: ${order.orderDate.toLocal().toString().split(' ')[0]}"),
                    ],
                  ),
                  children: order.items.map((item) => _buildOrderItem(item)).toList(),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text("Error: $error")),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return ListTile(
      leading: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
      title: Text(item.name),
      subtitle: Text("₹${item.price.toStringAsFixed(2)} x ${item.quantity}"),
    );
  }
}
