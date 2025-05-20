import 'package:hive/hive.dart';
import 'package:inventory_ease/data/models/category_model.dart';

class CategoryRepository {
  final Box<CategoryModel> _box;

  CategoryRepository() : _box = Hive.box<CategoryModel>('categories');

  Future<List<CategoryModel>> getAllCategories() async {
    return _box.values.toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> deleteCategory(int id) async {
    await _box.delete(id);
  }

  CategoryModel? getCategory(int id) {
    return _box.get(id);
  }
}
