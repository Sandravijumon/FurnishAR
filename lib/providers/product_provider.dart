import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

final productProvider = Provider<List<Product>>((ref) {
  return [
   
    Product(name: "Luxury Sofa", imageUrl: "https://m.media-amazon.com/images/I/81YZE9BT3kL._AC_UF894,1000_QL80_.jpg", price: 90990,category: "Sofas"),   
    Product(name: "Leatherette Sofa", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS6eFujV018KRTtRtXtRZB9KO6UG1dAWS-CVCIYpM7YMKPs2YrO_ueS0Bihtm9OaQ65cYM&usqp=CAU", price: 59999,category: "Sofas"),
    Product(name: "Queen Bed", imageUrl: "https://mywakeup.in/cdn/shop/collections/1693918798.png?v=1710391396&width=1296", price: 30000,category: "Beds"),
    Product(name: "Dining Table", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRVAnBDsmf1h_dUmyeq4sUbhTl9VYz5jiMXfw&s", price: 60000,category: "Tables"),
    Product(name: "Modern Sofa", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTgsjVQMCBbmW83KBYrZ4p8jL99G-id7COR95Tm20Z_d1sCEvHbo3VEX2BeBzeKGV2qVaE&usqp=CAU", price: 45990,category: "Sofas"),
    Product(name: "Royal Palm Sofa", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ5iL_FRQnaXAuYlVYtXksbr_1x4Timsc6AHflewh7DuKK8mepssFplgb94UDdzQAOI7_U&usqp=CAU", price: 50000,category: "Sofas"),
    Product(name: "Wooden Furnished chair", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSWRm6tHn826h75AhQQ6qiVZGxWpxNm7cvkPQ&s", price: 4500,category: "Chairs"),
  ];
});
