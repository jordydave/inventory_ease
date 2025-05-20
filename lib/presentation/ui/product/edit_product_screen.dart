import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  final VoidCallback? onProductUpdated;

  const EditProductScreen({
    super.key,
    required this.product,
    this.onProductUpdated,
  });

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late int _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _quantityController = TextEditingController(
      text: widget.product.quantity.toString(),
    );
    _selectedCategoryId = widget.product.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProduct = ProductModel(
        id: widget.product.id,
        name: _nameController.text,
        categoryId: _selectedCategoryId,
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
      );

      try {
        await ref
            .read(productListProvider.notifier)
            .updateProduct(updatedProduct);
        widget.onProductUpdated?.call();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update product: ${e.toString()}'),
            ),
          );
        }
      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value);
                if (price == null) {
                  return 'Please enter a valid number';
                }
                if (price <= 0) {
                  return 'Price must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity';
                }
                final quantity = int.tryParse(value);
                if (quantity == null) {
                  return 'Please enter a valid number';
                }
                if (quantity < 0) {
                  return 'Quantity cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items:
                  categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}
