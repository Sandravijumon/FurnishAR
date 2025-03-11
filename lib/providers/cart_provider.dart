import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<Product>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<Product>> {
  CartNotifier() : super([]);

  void addToCart(Product product) {
    state = [...state, product]; // Add product to cart
  }

  void removeFromCart(Product product) {
    state = state.where((item) => item != product).toList(); // Remove product
  }

  double get totalPrice {
    return state.fold(0, (sum, item) => sum + item.price);
  }

  void clearCart() {
    state = []; // Clear cart
  }
}
