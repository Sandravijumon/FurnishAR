// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/category_provider.dart';
// import 'furniture_list_screen.dart';

// class CategoriesScreen extends ConsumerWidget {
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final categoriesAsync = ref.watch(categoriesProvider);

//     return Scaffold(
//       appBar: AppBar(title: Text("Furniture Categories")),
//       body: Column(
//         children: [
//           // 🔍 Search Bar
//           Padding(
//             padding: EdgeInsets.all(10),
//             child: TextField(
//               decoration: InputDecoration(
//                 prefixIcon: Icon(Icons.search),
//                 hintText: "Search categories...",
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//             ),
//           ),
          
//           // 🛋️ Categories Grid
//           Expanded(
//             child: categoriesAsync.when(
//               data: (categories) {
//                 if (categories.isEmpty) {
//                   return Center(child: Text("No categories found."));
//                 }
//                 return GridView.builder(
//                   padding: EdgeInsets.all(10),
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     childAspectRatio: 0.8,
//                   ),
//                   itemCount: categories.length,
//                   itemBuilder: (context, index) {
//                     final category = categories[index];
//                     return GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => FurnitureListScreen(categoryName: category.name),
//                           ),
//                         );
//                       },
//                       child: Card(
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         elevation: 4,
//                         child: Column(
//                           children: [
//                             ClipRRect(
//                               borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
//                               child: Image.network(category.imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
//                             ),
//                             SizedBox(height: 8),
//                             Text(
//                               category.name,
//                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//               loading: () => Center(child: CircularProgressIndicator()),
//               error: (error, stackTrace) => Center(child: Text("Error: $error")),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
