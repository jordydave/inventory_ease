import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';

// Simple in-memory mock repository
class MockProductRepository implements ProductRepository {
  final List<ProductModel> _products = [];

  @override
  Future<void> addProduct(ProductModel product) async {
    _products.add(product);
  }

  @override
  Future<void> deleteProduct(int id) async {
    _products.removeWhere((p) => p.id == id);
  }

  @override
  List<ProductModel> getAllProducts() {
    return List<ProductModel>.from(_products);
  }

  @override
  ProductModel? getProduct(int id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
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
  test('ProductListNotifier adds product', () async {
    final mockRepo = MockProductRepository();
    final notifier = ProductListNotifier(mockRepo);
    final product = ProductModel(
      id: 1,
      name: 'Test Product',
      categoryId: 1,
      quantity: 10,
      price: 99.99,
    );
    await notifier.addProduct(product);
    // Simulate loading products from repo
    await notifier.loadProducts();
    expect(notifier.state.length, 1);
    expect(notifier.state[0].name, 'Test Product');
    expect(notifier.state[0].price, 99.99);
    expect(notifier.state[0].quantity, 10);
    expect(notifier.state[0].categoryId, 1);
  });
} 