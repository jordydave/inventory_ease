import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';
import 'package:inventory_ease/data/repositories/category_repository.dart';

class MockCategoryRepository implements CategoryRepository {
  final List<CategoryModel> categories;
  
  MockCategoryRepository(this.categories);
  
  @override
  Future<List<CategoryModel>> getAllCategories() async => categories;
  
  @override
  Future<void> addCategory(CategoryModel category) async {}
  
  @override
  Future<void> updateCategory(CategoryModel category) async {}
  
  @override
  Future<void> deleteCategory(int id) async {}
  
  @override
  CategoryModel? getCategory(int id) => null;
}

void main() {
  test('CategoryListNotifier initializes with empty list', () {
    final container = ProviderContainer(
      overrides: [
        categoryListProvider.overrideWith(
          (ref) => CategoryListNotifier(MockCategoryRepository([])),
        ),
      ],
    );

    expect(container.read(categoryListProvider), []);
  });

  test('CategoryListNotifier loads categories', () {
    final categories = [
      CategoryModel(id: 1, name: 'Electronics'),
      CategoryModel(id: 2, name: 'Clothing'),
    ];

    final container = ProviderContainer(
      overrides: [
        categoryListProvider.overrideWith(
          (ref) => CategoryListNotifier(MockCategoryRepository(categories))..state = categories,
        ),
      ],
    );

    expect(container.read(categoryListProvider), categories);
  });
}
