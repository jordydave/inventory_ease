import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/data/repositories/category_repository.dart';

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, List<CategoryModel>>((ref) {
      return CategoryListNotifier(CategoryRepository());
    });

class CategoryListNotifier extends StateNotifier<List<CategoryModel>> {
  final CategoryRepository _repository;

  CategoryListNotifier(this._repository) : super([]) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = await _repository.getAllCategories();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _repository.addCategory(category);
    state = [...state, category];
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _repository.updateCategory(category);
    state = state.map((c) => c.id == category.id ? category : c).toList();
  }

  Future<void> deleteCategory(int id) async {
    await _repository.deleteCategory(id);
    state = state.where((category) => category.id != id).toList();
  }
}
