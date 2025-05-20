import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
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
  });

  tearDown(() async {
    // Clean up Hive boxes
    await Hive.close();
    // Clean up temp directory
    await tempDir.delete(recursive: true);
  });

  test('CRUD operations work correctly', () async {
    // Create a test product
    final product = ProductModel(
      id: 1,
      name: 'Test Product',
      categoryId: 1,
      quantity: 10,
      price: 99.99,
    );

    // Test add
    await repository.addProduct(product);
    expect(repository.getAllProducts().length, 1);

    // Test get
    final retrievedProduct = repository.getProduct(1);
    expect(retrievedProduct?.name, 'Test Product');

    // Test delete
    await repository.deleteProduct(1);
    expect(repository.getAllProducts().length, 0);
  });
} 