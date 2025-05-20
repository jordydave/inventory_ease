import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/config/themes.dart';
import 'package:inventory_ease/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register Hive adapters first
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(StockLogModelAdapter());
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Open boxes before initializing database service
  await Hive.openBox<ProductModel>('products');
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox<StockLogModel>('stock_logs');
  
  // Initialize database service
  final dbService = LocalDbService();
  await dbService.init();
  
  runApp(
    ProviderScope(
      overrides: [
        dbServiceProvider.overrideWithValue(dbService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InventoryEase',
      theme: inventoryEaseTheme,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
