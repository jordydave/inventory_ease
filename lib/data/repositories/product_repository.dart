import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/data/models/product_model.dart';

class ProductRepository {
  final LocalDbService _dbService;

  ProductRepository(this._dbService);

  Future<void> addProduct(ProductModel product) async {
    await _dbService.productBox.put(product.id, product);
  }

  Future<void> deleteProduct(int id) async {
    await _dbService.productBox.delete(id);
  }

  List<ProductModel> getAllProducts() {
    return _dbService.productBox.values.toList();
  }

  ProductModel? getProduct(int id) {
    return _dbService.productBox.get(id);
  }

  Future<void> updateProduct(ProductModel product) async {
    await _dbService.productBox.put(product.id, product);
  }
}
