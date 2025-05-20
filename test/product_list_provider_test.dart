import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  late ProviderContainer container;
  late LocalDbService dbService;
  late ProductRepository repository;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    
    // Register the ProductModel adapter
    Hive.registerAdapter(ProductModelAdapter());
    
    dbService = LocalDbService();
    await dbService.init();
    repository = ProductRepository(dbService);

    // Override the provider with our test repository
    container = ProviderContainer(
      overrides: [
        productListProvider.overrideWith(
          (ref) => ProductListNotifier(repository),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('Product list state management works correctly', () async {
    final notifier = container.read(productListProvider.notifier);
    final product = ProductModel(
      id: 1,
      name: 'Test Product',
      categoryId: 1,
      quantity: 10,
      price: 99.99,
    );

    // Test initial state
    expect(container.read(productListProvider), []);

    // Test adding product
    await notifier.addProduct(product);
    expect(container.read(productListProvider).length, 1);
    expect(container.read(productListProvider)[0].name, 'Test Product');

    // Test loading products
    await notifier.loadProducts();
    expect(container.read(productListProvider).length, 1);

    // Test deleting product
    await notifier.deleteProduct(1);
    expect(container.read(productListProvider), []);
  });
} 