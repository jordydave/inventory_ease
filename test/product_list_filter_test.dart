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
  });

  setUp(() async {
    // Initialize mock repositories
    mockCategoryRepo = MockCategoryRepository();
    mockProductRepo = MockProductRepository();
  });

  tearDownAll(() async {
    // Clean up temporary directory
    await tempDir.delete(recursive: true);
  });

  testWidgets('Product list can be filtered by name and category', (
    WidgetTester tester,
  ) async {
    // Create test categories
    final categories = [
      CategoryModel(id: 1, name: 'Electronics'),
      CategoryModel(id: 2, name: 'Clothing'),
    ];

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

    // Add test data to mock repositories
    for (var category in categories) {
      await mockCategoryRepo.addCategory(category);
    }
    for (var product in products) {
      await mockProductRepo.addProduct(product);
    }

    // Create a ProviderContainer with overridden providers
    final container = ProviderContainer(
      overrides: [
        productListProvider.overrideWith(
          (ref) => ProductListNotifier(mockProductRepo)..state = products,
        ),
        categoryListProvider.overrideWith(
          (ref) => CategoryListNotifier(mockCategoryRepo)..state = categories,
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

    // Verify all products are shown initially
    expect(find.text('iPhone'), findsOneWidget);
    expect(find.text('T-shirt'), findsOneWidget);
    expect(find.text('iPad'), findsOneWidget);

    // Test name search
    final searchField = find.widgetWithText(TextField, 'Search products...');
    expect(searchField, findsOneWidget, reason: 'Search field should be visible');
    await tester.enterText(searchField, 'iP');
    await tester.pumpAndSettle();

    // Verify only iPhone and iPad are shown
    expect(find.text('iPhone'), findsOneWidget);
    expect(find.text('T-shirt'), findsNothing);
    expect(find.text('iPad'), findsOneWidget);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();

    // Test category filter
    final categoryDropdown = find.byType(DropdownButton<int?>);
    expect(categoryDropdown, findsOneWidget, reason: 'Category dropdown should be visible');
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    
    final electronicsOption = find.text('Electronics').last;
    expect(electronicsOption, findsOneWidget, reason: 'Electronics category should be visible');
    await tester.tap(electronicsOption);
    await tester.pumpAndSettle();

    // Verify only Electronics products are shown
    expect(find.text('iPhone'), findsOneWidget);
    expect(find.text('T-shirt'), findsNothing);
    expect(find.text('iPad'), findsOneWidget);

    // Clear category filter
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    
    final allCategoriesOption = find.text('All Categories').last;
    expect(allCategoriesOption, findsOneWidget, reason: 'All Categories option should be visible');
    await tester.tap(allCategoriesOption);
    await tester.pumpAndSettle();

    // Verify all products are shown again
    expect(find.text('iPhone'), findsOneWidget);
    expect(find.text('T-shirt'), findsOneWidget);
    expect(find.text('iPad'), findsOneWidget);
  });
}
