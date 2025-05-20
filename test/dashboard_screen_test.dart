import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/presentation/ui/dashboard/dashboard_screen.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/presentation/state/stock_history/stock_history_provider.dart' as stock;
import 'package:inventory_ease/data/repositories/stock_log_repository.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationCachePath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getDownloadsPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return [Directory.systemTemp.path];
  }

  @override
  Future<String?> getExternalStoragePath({StorageDirectory? type}) async {
    return Directory.systemTemp.path;
  }

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async {
    return [Directory.systemTemp.path];
  }

  @override
  Future<String?> getLibraryPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}

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
  late Directory tempDir;
  late MockLocalDbService mockDbService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();
    
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp();
    await Hive.initFlutter(tempDir.path);
    
    // Register adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(StockLogModelAdapter());
  });

  setUp(() {
    mockDbService = MockLocalDbService();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Dashboard shows correct product counts and low stock alerts',
      (WidgetTester tester) async {
    // Create test products
    final products = [
      ProductModel(id: 1, name: 'Product 1', categoryId: 1, quantity: 10, price: 100),
      ProductModel(id: 2, name: 'Product 2', categoryId: 1, quantity: 3, price: 200),
      ProductModel(id: 3, name: 'Product 3', categoryId: 2, quantity: 2, price: 300),
    ];

    final mockProductRepo = MockProductRepository(products);
    final mockStockRepo = MockStockHistoryRepository([]);

    // Create a ProviderContainer with overridden providers
    final container = ProviderContainer(
      overrides: [
        dbServiceProvider.overrideWithValue(mockDbService),
        productListProvider.overrideWith(
          (ref) => ProductListNotifier(mockProductRepo)..state = products,
        ),
        stock.stockHistoryProvider.overrideWith(
          (ref) => stock.StockHistoryNotifier(mockStockRepo)..state = [],
        ),
      ],
    );

    // Build the DashboardScreen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Wait for initial build
    await tester.pumpAndSettle();

    // Verify total products count
    expect(find.text('Total Products'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Verify total stock count
    expect(find.text('Total Stock'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    // Verify low stock alerts
    expect(find.text('Low Stock Alert'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
    expect(find.text('Product 3'), findsOneWidget);
    expect(find.text('Quantity: 3'), findsOneWidget);
    expect(find.text('Quantity: 2'), findsOneWidget);

    container.dispose();
  });
} 