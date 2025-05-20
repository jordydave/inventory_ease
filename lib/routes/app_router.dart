import 'package:flutter/material.dart';
import 'package:inventory_ease/presentation/ui/dashboard/dashboard_screen.dart';
import 'package:inventory_ease/presentation/ui/product/product_list_screen.dart';
import 'package:inventory_ease/presentation/ui/product/add_product_screen.dart';
import 'package:inventory_ease/presentation/ui/product/edit_product_screen.dart';
import 'package:inventory_ease/presentation/ui/stock_history/stock_history_screen.dart';
import 'package:inventory_ease/presentation/ui/category/category_screen.dart';
import 'package:inventory_ease/data/models/product_model.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/products':
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
      case '/add-product':
        return MaterialPageRoute(builder: (_) => const AddProductScreen());
      case '/edit-product':
        final product = settings.arguments as ProductModel;
        return MaterialPageRoute(
          builder: (_) => EditProductScreen(product: product),
        );
      case '/stock-history':
        return MaterialPageRoute(builder: (_) => const StockHistoryScreen());
      case '/categories':
        return MaterialPageRoute(builder: (_) => const CategoryScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 