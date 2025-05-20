import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dbServiceProvider = Provider<LocalDbService>((ref) {
  throw UnimplementedError('Database service must be initialized in main()');
});

class LocalDbService {
  static const String _productBoxName = 'products';
  static const String _categoryBoxName = 'categories';
  static const String _stockLogBoxName = 'stock_logs';

  Box<ProductModel>? _productBox;
  Box<CategoryModel>? _categoryBox;
  Box<StockLogModel>? _stockLogBox;

  Box<ProductModel> get productBox {
    if (_productBox == null) {
      throw StateError('Product box not initialized. Call init() first.');
    }
    return _productBox!;
  }

  Box<CategoryModel> get categoryBox {
    if (_categoryBox == null) {
      throw StateError('Category box not initialized. Call init() first.');
    }
    return _categoryBox!;
  }

  Box<StockLogModel> get stockLogBox {
    if (_stockLogBox == null) {
      throw StateError('Stock log box not initialized. Call init() first.');
    }
    return _stockLogBox!;
  }

  Future<void> init({String? hivePath}) async {
    if (hivePath != null) {
      Hive.init(hivePath);
    }

    // Open boxes
    _productBox = await Hive.openBox<ProductModel>(_productBoxName);
    _categoryBox = await Hive.openBox<CategoryModel>(_categoryBoxName);
    _stockLogBox = await Hive.openBox<StockLogModel>(_stockLogBoxName);
  }

  Future<void> addProduct(ProductModel product) async {
    await productBox.put(product.id, product);
  }

  Future<void> deleteProduct(int id) async {
    await productBox.delete(id);
  }

  List<ProductModel> getAllProducts() {
    return productBox.values.toList();
  }

  ProductModel? getProduct(int id) {
    return productBox.get(id);
  }

  Future<void> updateProduct(ProductModel product) async {
    await productBox.put(product.id, product);
  }

  Future<void> addStockLog(StockLogModel log) async {
    await stockLogBox.put(log.id, log);
  }

  List<StockLogModel> getAllStockLogs() {
    return stockLogBox.values.toList();
  }

  List<StockLogModel> getStockLogsForProduct(int productId) {
    return stockLogBox.values
        .where((log) => log.productId == productId)
        .toList();
  }

  Future<void> deleteStockLog(int id) async {
    await stockLogBox.delete(id);
  }
}
