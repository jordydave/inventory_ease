import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/ui/product/product_list_screen.dart';
import 'package:inventory_ease/data/repositories/category_repository.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/presentation/state/stock_history/stock_history_provider.dart' as stock;
import 'package:inventory_ease/data/repositories/stock_log_repository.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'dart:io';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class MockLocalDbService extends LocalDbService {
  @override
  Future<void> init({String? hivePath}) async {}
}

class MockProductRepository extends ProductRepository {
  final List<ProductModel> _products = [];

  MockProductRepository() : super(MockLocalDbService());

  @override
  List<ProductModel> getAllProducts() {
    return List.unmodifiable(_products);
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    _products.add(product);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    _products.removeWhere((p) => p.id == id);
  }

  @override
  ProductModel? getProduct(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

class MockStockHistoryRepository extends StockLogRepository {
  final List<StockLogModel> _logs = [];

  MockStockHistoryRepository() : super(MockLocalDbService());

  @override
  List<StockLogModel> getAllLogs() => List.unmodifiable(_logs);

  @override
  Future<void> addLog(StockLogModel log) async {
    _logs.add(log);
  }

  @override
  List<StockLogModel> getLogsForProduct(int productId) {
    return _logs.where((log) => log.productId == productId).toList();
  }
}

class MockCategoryRepository extends CategoryRepository {
  final List<CategoryModel> _categories = [];

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    return [
      CategoryModel(id: 1, name: 'Electronics'),
      CategoryModel(id: 2, name: 'Clothing'),
    ];
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    _categories.add(category);
  }
}

class TestProductListNotifier extends ProductListNotifier {
  final ProductRepository _testRepository;

  TestProductListNotifier(this._testRepository) : super(_testRepository) {
    // Load products immediately after initialization
    loadProducts();
  }

  @override
  Future<void> loadProducts() async {
    state = _testRepository.getAllProducts();
  }
}

void main() {
  late MockProductRepository mockProductRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockStockHistoryRepository mockStockRepository;
  late ProviderContainer container;
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
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(StockLogModelAdapter());

    // Open boxes
    await Hive.openBox<CategoryModel>('categories');
    await Hive.openBox<ProductModel>('products');
    await Hive.openBox<StockLogModel>('stock_logs');
  });

  setUp(() async {
    mockDbService = MockLocalDbService();
    mockProductRepository = MockProductRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockStockRepository = MockStockHistoryRepository();

    // Add initial product to the repository
    await mockProductRepository.addProduct(
      ProductModel(
        id: 1,
        name: 'Test Product',
        categoryId: 1,
        quantity: 10,
        price: 99.99,
      ),
    );

    container = ProviderContainer(
      overrides: [
        dbServiceProvider.overrideWithValue(mockDbService),
        productListProvider.overrideWith(
          (ref) => TestProductListNotifier(mockProductRepository),
        ),
        categoryListProvider.overrideWith(
          (ref) => CategoryListNotifier(mockCategoryRepository),
        ),
        stock.stockHistoryProvider.overrideWith(
          (ref) => stock.StockHistoryNotifier(mockStockRepository)..state = [],
        ),
      ],
    );

    // Wait for initial state to be loaded
    await Future.delayed(Duration.zero);
  });

  tearDown(() {
    container.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Stock-in/out buttons update quantity and create log', (
    WidgetTester tester,
  ) async {
    // Build our widget and trigger a frame
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ProductListScreen()),
      ),
    );

    // Wait for the widget to be fully rendered
    await tester.pumpAndSettle();

    // Verify initial product is displayed
    expect(
      find.text('Test Product'),
      findsOneWidget,
      reason: 'Product name should be visible',
    );
    expect(
      find.text('Price: 99.99 | Qty: 10'),
      findsOneWidget,
      reason: 'Initial price and quantity should be visible',
    );

    // Find and tap the stock-in button
    final stockInButton = find.byIcon(Icons.add_circle);
    expect(
      stockInButton,
      findsOneWidget,
      reason: 'Stock-in button should be visible',
    );
    await tester.tap(stockInButton);
    await tester.pumpAndSettle();

    // Enter quantity in dialog
    final quantityField = find.widgetWithText(TextField, 'Quantity');
    expect(
      quantityField,
      findsOneWidget,
      reason: 'Quantity TextField should be visible',
    );
    await tester.enterText(quantityField, '1');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Verify quantity is updated
    expect(
      find.text('Price: 99.99 | Qty: 11'),
      findsOneWidget,
      reason: 'Quantity should be updated after stock-in',
    );

    // Find and tap the stock-out button
    final stockOutButton = find.byIcon(Icons.remove_circle);
    expect(
      stockOutButton,
      findsOneWidget,
      reason: 'Stock-out button should be visible',
    );
    await tester.tap(stockOutButton);
    await tester.pumpAndSettle();

    // Enter quantity in dialog
    expect(
      quantityField,
      findsOneWidget,
      reason: 'Quantity TextField should be visible',
    );
    await tester.enterText(quantityField, '1');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Verify quantity is updated
    expect(
      find.text('Price: 99.99 | Qty: 10'),
      findsOneWidget,
      reason: 'Quantity should be updated after stock-out',
    );
  });
}
