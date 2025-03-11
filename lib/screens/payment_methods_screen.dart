import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedPaymentProvider = StateProvider<String?>((ref) => null);

class PaymentMethodsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPayment = ref.watch(selectedPaymentProvider);

    List<Map<String, dynamic>> paymentMethods = [
      {"name": "Credit/Debit Card", "icon": Icons.credit_card},
      {"name": "PayPal", "icon": Icons.account_balance_wallet},
      {"name": "UPI", "icon": Icons.qr_code},
      {"name": "Cash on Delivery", "icon": Icons.money},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Select Payment Method")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = paymentMethods[index];

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(method["icon"], color: Colors.deepPurple),
                      title: Text(method["name"]),
                      trailing: selectedPayment == method["name"]
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        ref.read(selectedPaymentProvider.notifier).state = method["name"];
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${method["name"]} selected!")),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedPayment != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Payment method saved: $selectedPayment")),
                  );
                  Navigator.pop(context); // Go back to the profile screen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please select a payment method")),
                  );
                }
              },
              child: Text("Confirm Payment Method"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
