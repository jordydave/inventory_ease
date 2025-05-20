import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/state/stock_history/stock_history_provider.dart';
import 'package:inventory_ease/presentation/ui/stock_history/stock_history_screen.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:inventory_ease/data/repositories/stock_log_repository.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:intl/intl.dart';

class MockProductRepository extends ProductRepository {
  final List<ProductModel> products;
  MockProductRepository(this.products) : super(MockLocalDbService());
  @override
  List<ProductModel> getAllProducts() => products;
}

class MockStockHistoryRepository extends StockLogRepository {
  final List<StockLogModel> logs;
  MockStockHistoryRepository(this.logs) : super(MockLocalDbService());
  @override
  List<StockLogModel> getAllLogs() => logs;
}

class MockLocalDbService extends LocalDbService {
  @override
  Future<void> init({String? hivePath}) async {}
}

void main() {
  testWidgets('StockHistoryScreen displays logs with product names and timestamps',
      (WidgetTester tester) async {
    // Create test products
    final products = [
      ProductModel(
        id: 1,
        name: 'Test Product 1',
        price: 10.0,
        quantity: 5,
        categoryId: 1,
      ),
      ProductModel(
        id: 2,
        name: 'Test Product 2',
        price: 20.0,
        quantity: 10,
        categoryId: 1,
      ),
    ];

    // Create test stock logs
    final now = DateTime.now();
    final logs = [
      StockLogModel(
        id: 1,
        productId: 1,
        change: 5,
        timestamp: now,
        note: 'Stock in',
      ),
      StockLogModel(
        id: 2,
        productId: 2,
        change: -3,
        timestamp: now.subtract(const Duration(hours: 1)),
        note: 'Stock out',
      ),
    ];

    // Create a ProviderContainer with overridden providers
    final container = ProviderContainer(
      overrides: [
        productListProvider.overrideWith(
          (ref) => ProductListNotifier(MockProductRepository(products))..state = products,
        ),
        stockHistoryProvider.overrideWith(
          (ref) => StockHistoryNotifier(MockStockHistoryRepository(logs))..state = logs,
        ),
      ],
    );

    // Build the StockHistoryScreen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: StockHistoryScreen(),
        ),
      ),
    );

    // Verify the screen title
    expect(find.text('Stock History'), findsOneWidget);

    // Verify product names are displayed
    expect(find.text('Test Product 1'), findsOneWidget);
    expect(find.text('Test Product 2'), findsOneWidget);

    // Verify stock changes are displayed
    expect(find.text('+5'), findsOneWidget);
    expect(find.text('-3'), findsOneWidget);

    // Verify notes are displayed
    expect(find.text('Stock in'), findsOneWidget);
    expect(find.text('Stock out'), findsOneWidget);

    // Verify timestamps are displayed
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    expect(find.text(dateFormat.format(now)), findsOneWidget);
    expect(find.text(dateFormat.format(now.subtract(const Duration(hours: 1)))), findsOneWidget);
  });
} 