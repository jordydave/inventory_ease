import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    final controller = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Category'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    ref
                        .read(categoryListProvider.notifier)
                        .updateCategory(
                          category.copyWith(name: controller.text),
                        );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    // Check if category has any products
    final products = ref.read(productListProvider);
    final hasProducts = products.any(
      (product) => product.categoryId == category.id,
    );

    if (hasProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete category with associated products. Please remove or reassign products first.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If no products, proceed with deletion
    ref.read(categoryListProvider.notifier).deleteCategory(category.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Category deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            child: ListTile(
              title: Text(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, ref, category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCategory(context, ref, category),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final controller = TextEditingController();
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Add Category'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          ref
                              .read(categoryListProvider.notifier)
                              .addCategory(
                                CategoryModel(
                                  id:
                                      DateTime.now().millisecondsSinceEpoch %
                                      0xFFFFFFFF,
                                  name: controller.text,
                                ),
                              );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Category added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
