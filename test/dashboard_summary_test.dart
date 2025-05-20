import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/ui/dashboard/dashboard_screen.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:inventory_ease/presentation/state/stock_history/stock_history_provider.dart'
    as stock;
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/data/repositories/stock_log_repository.dart';
import 'package:inventory_ease/data/models/category_model.dart';
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
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
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

class MockBox<T> extends Box<T> {
  final Map<dynamic, T> _data = {};

  @override
  Future<void> put(dynamic key, T value) async {
    _data[key] = value;
  }

  @override
  T? get(dynamic key, {T? defaultValue}) => _data[key] ?? defaultValue;

  @override
  Future<void> delete(dynamic key) async {
    _data.remove(key);
  }

  @override
  Future<int> clear() async {
    final count = _data.length;
    _data.clear();
    return count;
  }

  @override
  Iterable<dynamic> get keys => _data.keys;

  @override
  Iterable<T> get values => _data.values;

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  int get length => _data.length;

  @override
  Future<void> close() async {}

  @override
  Future<void> deleteFromDisk() async {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> compact() async {}

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (var key in keys) {
      _data.remove(key);
    }
  }

  @override
  Future<void> putAll(Map<dynamic, T> entries) async {
    _data.addAll(entries);
  }

  @override
  Future<void> putAt(int index, T value) async {
    final key = _data.keys.elementAt(index);
    _data[key] = value;
  }

  @override
  Future<void> deleteAt(int index) async {
    final key = _data.keys.elementAt(index);
    _data.remove(key);
  }

  @override
  T? getAt(int index) {
    if (index < 0 || index >= _data.length) return null;
    return _data.values.elementAt(index);
  }

  @override
  Future<int> add(T value) async {
    final key = _data.length;
    _data[key] = value;
    return key;
  }

  @override
  Future<Iterable<int>> addAll(Iterable<T> values) async {
    final keys = <int>[];
    for (var value in values) {
      final key = _data.length;
      _data[key] = value;
      keys.add(key);
    }
    return keys;
  }

  @override
  Map<dynamic, T> toMap() => Map.from(_data);

  @override
  Iterable<T> valuesBetween({dynamic startKey, dynamic endKey}) {
    final keys = _data.keys.toList()..sort();
    final startIndex = startKey == null ? 0 : keys.indexOf(startKey);
    final endIndex = endKey == null ? keys.length : keys.indexOf(endKey) + 1;
    return keys.sublist(startIndex, endIndex).map((key) => _data[key]!);
  }

  @override
  bool containsKey(dynamic key) => _data.containsKey(key);

  @override
  dynamic keyAt(int index) => _data.keys.elementAt(index);

  @override
  Stream<BoxEvent> watch({dynamic key}) => Stream.empty();

  @override
  bool get isOpen => true;

  @override
  bool get lazy => false;

  @override
  String get name => 'mock_box';

  @override
  String get path => 'mock_path';
}

class MockLocalDbService extends LocalDbService {
  late final Box<ProductModel> _productBox;
  late final Box<CategoryModel> _categoryBox;
  late final Box<StockLogModel> _stockLogBox;

  MockLocalDbService() {
    _productBox = MockBox<ProductModel>();
    _categoryBox = MockBox<CategoryModel>();
    _stockLogBox = MockBox<StockLogModel>();
  }

  @override
  Future<void> init({String? hivePath}) async {}

  @override
  Box<ProductModel> get productBox => _productBox;

  @override
  Box<CategoryModel> get categoryBox => _categoryBox;

  @override
  Box<StockLogModel> get stockLogBox => _stockLogBox;
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

  @override
  List<StockLogModel> getLogsForProduct(int productId) =>
      logs.where((log) => log.productId == productId).toList();
}

void main() {
  late Directory tempDir;
  late MockLocalDbService mockDbService;
  late MockProductRepository mockProductRepo;
  late MockStockHistoryRepository mockStockRepo;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp();
    await Hive.initFlutter(tempDir.path);

    // Register all required adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(StockLogModelAdapter());
  });

  setUp(() {
    mockDbService = MockLocalDbService();
    mockProductRepo = MockProductRepository([]);
    mockStockRepo = MockStockHistoryRepository([]);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Dashboard shows correct product and stock summary', (
    WidgetTester tester,
  ) async {
    // Create test products
    final products = [
      ProductModel(
        id: 1,
        name: 'iPhone',
        price: 999.99,
        quantity: 5,
        categoryId: 1,
      ),
      ProductModel(
        id: 2,
        name: 'T-shirt',
        price: 19.99,
        quantity: 10,
        categoryId: 2,
      ),
      ProductModel(
        id: 3,
        name: 'iPad',
        price: 799.99,
        quantity: 3,
        categoryId: 1,
      ),
    ];

    mockProductRepo = MockProductRepository(products);

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
        child: MaterialApp(home: DashboardScreen()),
      ),
    );

    // Wait for initial build
    await tester.pumpAndSettle();

    // Verify total products count
    expect(find.text('Total Products'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Verify total stock count (5 + 10 + 3 = 18)
    expect(find.text('Total Stock'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);

    // Verify total value (999.99 * 5 + 19.99 * 10 + 799.99 * 3 = 7,999.87)
    expect(find.text('Total Value'), findsOneWidget);
    expect(find.text('\$7,599.82'), findsOneWidget);
  });

  testWidgets(
    'Dashboard shows low-stock alert when a product has quantity < 5',
    (WidgetTester tester) async {
      // Create test products with one low-stock product
      final products = [
        ProductModel(
          id: 1,
          name: 'iPhone',
          price: 999.99,
          quantity: 5,
          categoryId: 1,
        ),
        ProductModel(
          id: 2,
          name: 'T-shirt',
          price: 19.99,
          quantity: 10,
          categoryId: 2,
        ),
        ProductModel(
          id: 3,
          name: 'iPad',
          price: 799.99,
          quantity: 3,
          categoryId: 1,
        ),
      ];

      mockProductRepo = MockProductRepository(products);

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
          child: MaterialApp(home: DashboardScreen()),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Verify that the low-stock alert is shown
      expect(find.text('Low Stock Alert'), findsOneWidget);
      expect(find.text('iPad'), findsOneWidget);
      expect(find.text('Quantity: 3'), findsOneWidget);
    },
  );
}
