import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Persistence', () {
    late LocalDbService dbService;
    late Box<ProductModel> productBox;
    final testProduct = ProductModel(
      id: 1,
      name: 'Persistent Product',
      price: 42.0,
      quantity: 7,
      categoryId: 1,
    );

    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(dir.path);
      
      // Register the ProductModel adapter
      Hive.registerAdapter(ProductModelAdapter());
      
      dbService = LocalDbService();
      await dbService.init();
      productBox = Hive.box<ProductModel>('products');
    });

    test('Product persists after box is closed and reopened', () async {
      // Add product
      await productBox.put(testProduct.id, testProduct);
      expect(productBox.get(testProduct.id)?.name, 'Persistent Product');

      // Close and reopen box (simulate app restart)
      await productBox.close();
      await Hive.openBox<ProductModel>('products');
      final reopenedBox = Hive.box<ProductModel>('products');
      expect(reopenedBox.get(testProduct.id)?.name, 'Persistent Product');
    });

    tearDownAll(() async {
      if (productBox.isOpen) {
        await productBox.clear();
        await productBox.close();
      }
    });
  });
} 