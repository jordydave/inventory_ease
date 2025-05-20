import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/ui/product/add_product_screen.dart';
import 'package:inventory_ease/data/repositories/category_repository.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'dart:io';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class MockCategoryRepository extends CategoryRepository {
  final List<CategoryModel> _categories = [];
  
  @override
  Future<List<CategoryModel>> getAllCategories() async => _categories;
  
  @override
  Future<void> addCategory(CategoryModel category) async {
    _categories.add(category);
  }
}

class MockProductRepository extends ProductRepository {
  final List<ProductModel> _products = [];
  
  MockProductRepository() : super(LocalDbService());
  
  @override
  List<ProductModel> getAllProducts() => _products;
  
  @override
  Future<void> addProduct(ProductModel product) async {
    _products.add(product);
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = MockPathProviderPlatform();
    tempDir = await Directory.systemTemp.createTemp();
    await Hive.initFlutter(tempDir.path);
    await Hive.openBox<CategoryModel>('categories');
    await Hive.openBox<ProductModel>('products');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('AddProductScreen calls onProductAdded and pops on submit', (WidgetTester tester) async {
    bool productAdded = false;
    final categories = [CategoryModel(id: 1, name: 'Electronics')];
    final mockCategoryRepo = MockCategoryRepository();
    await mockCategoryRepo.addCategory(categories[0]); // Ensure category is added to repo

    final container = ProviderContainer(
      overrides: [
        categoryListProvider.overrideWith(
          (ref) => CategoryListNotifier(mockCategoryRepo)..state = categories,
        ),
        productListProvider.overrideWith(
          (ref) => ProductListNotifier(MockProductRepository())..state = [],
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: AddProductScreen(
              onProductAdded: () {
                productAdded = true;
              },
            ),
          ),
        ),
      ),
    );

    // Wait for initial build and state to be set
    await tester.pumpAndSettle();

    // Verify category state is set
    final categoryState = container.read(categoryListProvider);
    expect(categoryState.length, 1, reason: 'Should have one category');
    expect(categoryState[0].name, 'Electronics', reason: 'Category name should be Electronics');

    // Find form fields by their labels
    await tester.enterText(find.widgetWithText(TextFormField, 'Product Name'), 'Test Product');
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '99.99');
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '10');
    
    // Open dropdown and select category
    final dropdown = find.byType(DropdownButtonFormField<int>);
    expect(dropdown, findsOneWidget, reason: 'Dropdown should be found');
    
    // Tap the dropdown to open it
    await tester.tap(dropdown, warnIfMissed: false);
    await tester.pump(); // First pump to show dropdown
    await tester.pump(const Duration(milliseconds: 500)); // Wait for animation
    
    // Find and tap the dropdown item
    final dropdownItem = find.text('Electronics').last;
    expect(dropdownItem, findsOneWidget, reason: 'Dropdown item should be found');
    await tester.tap(dropdownItem, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Submit form
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(productAdded, isTrue);
    expect(find.byType(AddProductScreen), findsNothing);
  });
} 