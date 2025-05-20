import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/data/repositories/product_repository.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';

final productListProvider =
    StateNotifierProvider<ProductListNotifier, List<ProductModel>>((ref) {
      final dbService = ref.watch(dbServiceProvider);
      final repository = ProductRepository(dbService);
      return ProductListNotifier(repository);
    });

class ProductListNotifier extends StateNotifier<List<ProductModel>> {
  final ProductRepository _repository;

  ProductListNotifier(this._repository) : super([]);

  Future<void> loadProducts() async {
    state = _repository.getAllProducts();
  }

  Future<void> addProduct(ProductModel product) async {
    await _repository.addProduct(product);
    state = [...state, product];
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repository.updateProduct(product);
    state = _repository.getAllProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _repository.deleteProduct(id);
    state = state.where((product) => product.id != id).toList();
  }
}
