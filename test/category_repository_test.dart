import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/data/repositories/category_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  late LocalDbService dbService;
  late CategoryRepository repository;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    
    // Register the CategoryModel adapter
    Hive.registerAdapter(CategoryModelAdapter());
    
    dbService = LocalDbService();
    await dbService.init();
    repository = CategoryRepository();
  });

  tearDown(() async {
    // Clean up Hive boxes
    await Hive.close();
    // Clean up temp directory
    await tempDir.delete(recursive: true);
  });

  test('CRUD operations work correctly', () async {
    // Create a test category
    final category = CategoryModel(
      id: 1,
      name: 'Test Category',
    );

    // Test add
    await repository.addCategory(category);
    final categories = await repository.getAllCategories();
    expect(categories.length, 1);

    // Test get
    final retrievedCategory = repository.getCategory(1);
    expect(retrievedCategory?.name, 'Test Category');

    // Test delete
    await repository.deleteCategory(1);
    final remainingCategories = await repository.getAllCategories();
    expect(remainingCategories.length, 0);
  });
} 