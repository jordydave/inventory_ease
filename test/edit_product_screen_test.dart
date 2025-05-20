import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/ui/product/edit_product_screen.dart';
import 'package:inventory_ease/data/repositories/category_repository.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'dart:io';
import 'dart:async';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class MockProductRepository extends ProductRepository {
  final List<ProductModel> _products = [];

  MockProductRepository() : super(LocalDbService());

  @override
  List<ProductModel> getAllProducts() {
    if (_products.isNotEmpty) {}
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
    } else {
      _products.add(product);
    }

    if (_products.isNotEmpty) {}
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
  Completer<void>? _updateCompleter;

  TestProductListNotifier(this._testRepository) : super(_testRepository) {
    // Load products immediately after initialization
    loadProducts();
  }

  @override
  Future<void> loadProducts() async {
    state = _testRepository.getAllProducts();
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await _testRepository.updateProduct(product);

    // Force a state update by creating a new list
    state = _testRepository.getAllProducts();
    if (state.isNotEmpty) {}

    _updateCompleter?.complete();
  }

  Future<void> waitForUpdate() {
    _updateCompleter = Completer<void>();
    return _updateCompleter!.future;
  }
}

void main() {
  late MockProductRepository mockProductRepository;
  late MockCategoryRepository mockCategoryRepository;
  late ProviderContainer container;
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp();
    await Hive.initFlutter(tempDir.path);
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(ProductModelAdapter());
    await Hive.openBox<CategoryModel>('categories');
    await Hive.openBox<ProductModel>('products');
  });

  setUp(() async {
    mockProductRepository = MockProductRepository();
    mockCategoryRepository = MockCategoryRepository();

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
        productListProvider.overrideWith(
          (ref) => TestProductListNotifier(mockProductRepository),
        ),
        categoryListProvider.overrideWith(
          (ref) => CategoryListNotifier(mockCategoryRepository),
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

  testWidgets(
    'EditProductScreen form validation and submission works correctly',
    (WidgetTester tester) async {
      // Build our widget and trigger a frame
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: EditProductScreen(
              product: ProductModel(
                id: 1,
                name: 'Test Product',
                categoryId: 1,
                quantity: 10,
                price: 99.99,
              ),
            ),
          ),
        ),
      );

      // Wait for the widget to be fully rendered
      await tester.pumpAndSettle();

      // Verify the screen title
      expect(find.text('Edit Product'), findsOneWidget);

      // Verify initial values are displayed
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('99.99'), findsOneWidget);

      // Test form validation
      // Clear the name field
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pump();

      // Try to submit the form
      await tester.tap(find.text('Update Product'));
      await tester.pump();

      // Verify validation error is shown
      expect(find.text('Please enter a product name'), findsOneWidget);

      // Enter valid data
      await tester.enterText(
        find.byType(TextFormField).first,
        'Updated Product',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '149.99');
      await tester.enterText(find.byType(TextFormField).at(2), '20');
      await tester.pumpAndSettle(); // Wait for text input animations

      // Verify form values before submission
      expect(
        find.text('Updated Product'),
        findsOneWidget,
        reason: 'Product name should be entered',
      );
      expect(
        find.text('149.99'),
        findsOneWidget,
        reason: 'Price should be entered',
      );
      expect(
        find.text('20'),
        findsOneWidget,
        reason: 'Quantity should be entered',
      );

      // Submit the form
      final notifier =
          container.read(productListProvider.notifier)
              as TestProductListNotifier;
      final updateFuture = notifier.waitForUpdate();

      // Find and tap the update button
      final updateButton = find.text('Update Product');
      expect(
        updateButton,
        findsOneWidget,
        reason: 'Update button should be visible',
      );

      await tester.tap(updateButton);
      await tester.pump(); // First pump to trigger the form submission

      try {
        await updateFuture.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Update operation timed out');
          },
        );
      } catch (e) {
        rethrow;
      }

      await tester.pumpAndSettle(); // Wait for all animations and state updates

      // Debug: Print the current state
      final products = container.read(productListProvider);
      if (products.isNotEmpty) {}

      // Verify the product was updated in the list
      expect(products, isNotEmpty, reason: 'Product list should not be empty');
      final updatedProduct = products.first;
      expect(
        updatedProduct.name,
        'Updated Product',
        reason: 'Product name should be updated',
      );
      expect(
        updatedProduct.price,
        149.99,
        reason: 'Product price should be updated',
      );
      expect(
        updatedProduct.quantity,
        20,
        reason: 'Product quantity should be updated',
      );
      expect(
        updatedProduct.categoryId,
        1,
        reason: 'Product category should remain the same',
      );
    },
  );
}
