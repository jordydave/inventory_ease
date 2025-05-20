import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';
import 'package:inventory_ease/presentation/ui/product/product_list_screen.dart';
import 'package:inventory_ease/data/repositories/category_repository.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class MockCategoryRepository implements CategoryRepository {
  final List<CategoryModel> _categories = [];
  
  @override
  Future<List<CategoryModel>> getAllCategories() async => _categories;
  
  @override
  Future<void> addCategory(CategoryModel category) async {
    _categories.add(category);
  }

  @override
  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((category) => category.id == id);
  }

  @override
  CategoryModel? getCategory(int id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
  }
}

class MockProductRepository implements ProductRepository {
  final List<ProductModel> _products = [];
  
  @override
  List<ProductModel> getAllProducts() => _products;
  
  @override
  Future<void> addProduct(ProductModel product) async {
    _products.add(product);
  }

  @override
  Future<void> deleteProduct(int id) async {
    _products.removeWhere((product) => product.id == id);
  }

  @override
  ProductModel? getProduct(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
  }
}

void main() {
  late Directory tempDir;
  late MockCategoryRepository mockCategoryRepo;
  late MockProductRepository mockProductRepo;

  setUpAll(() async {
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('products');
    await Hive.openBox('categories');
  });

  setUp(() async {
    // Initialize mock repositories
    mockCategoryRepo = MockCategoryRepository();
    mockProductRepo = MockProductRepository();
  });

  tearDown(() async {
    // Close Hive boxes after each test
    await Hive.close();
  });

  tearDownAll(() async {
    // Clean up temporary directory
    try {
      await tempDir.delete(recursive: true);
    } catch (e) {
      // Ignore deletion errors
    }
  });

  testWidgets('ProductListScreen displays products correctly', (WidgetTester tester) async {
    // Add test data
    final testProduct = ProductModel(
      id: 1,
      name: 'Test Product',
      price: 99.99,
      quantity: 10,
      categoryId: 1,
    );
    await mockProductRepo.addProduct(testProduct);

    // Create a ProviderContainer with overridden providers
    final container = ProviderContainer(
      overrides: [
        productListProvider.overrideWith(
          (ref) => ProductListNotifier(mockProductRepo)..state = [testProduct],
        ),
        categoryListProvider.overrideWith(
          (ref) => CategoryListNotifier(mockCategoryRepo)..state = [],
        ),
      ],
    );

    // Build the ProductListScreen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ProductListScreen()),
      ),
    );

    // Wait for initial build
    await tester.pumpAndSettle();

    // Verify product is displayed
    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('Price: 99.99 | Qty: 10'), findsOneWidget);
  });

  testWidgets('ProductListScreen shows empty state message when no products', (WidgetTester tester) async {
    // Create a ProviderContainer with empty state
    final container = ProviderContainer(
      overrides: [
        productListProvider.overrideWith(
          (ref) => ProductListNotifier(mockProductRepo)..state = [],
        ),
        categoryListProvider.overrideWith(
          (ref) => CategoryListNotifier(mockCategoryRepo)..state = [],
        ),
      ],
    );

    // Build the ProductListScreen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ProductListScreen()),
      ),
    );

    // Wait for initial build and any animations
    await tester.pumpAndSettle();

    // Verify empty state message
    expect(find.text('No products found'), findsOneWidget, reason: 'Empty state message should be visible');
  });
} 