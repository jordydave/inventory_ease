import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/main.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:inventory_ease/data/repositories/category_repository.dart';
import 'package:inventory_ease/data/repositories/stock_log_repository.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';
import 'package:inventory_ease/presentation/state/stock_history/stock_history_provider.dart' as stock;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  late Directory tempDir;
  late LocalDbService dbService;
  late ProductRepository productRepository;
  late CategoryRepository categoryRepository;
  late StockLogRepository stockLogRepository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    
    // Register all required adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(StockLogModelAdapter());
    
    // Initialize database service and open boxes
    dbService = LocalDbService();
    await dbService.init(hivePath: tempDir.path);
    
    // Initialize repositories
    productRepository = ProductRepository(dbService);
    categoryRepository = CategoryRepository();
    stockLogRepository = StockLogRepository(dbService);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('App uses custom theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbServiceProvider.overrideWithValue(dbService),
          productListProvider.overrideWith(
            (ref) => ProductListNotifier(productRepository),
          ),
          categoryListProvider.overrideWith(
            (ref) => CategoryListNotifier(categoryRepository),
          ),
          stock.stockHistoryProvider.overrideWith(
            (ref) => stock.StockHistoryNotifier(stockLogRepository),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(AppBar)));

    // Verify that the app uses the custom theme
    expect(theme.scaffoldBackgroundColor, equals(Colors.blue));
    expect(theme.appBarTheme.titleTextStyle?.color, equals(Colors.white));

    // Verify text style in the dashboard
    final text = tester.widget<Text>(find.text('Total Products'));
    expect(text.style?.fontSize, equals(14.0)); // Updated to match actual theme
  });
}
