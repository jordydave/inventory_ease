import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final VoidCallback? onProductAdded;
  const AddProductScreen({super.key, this.onProductAdded});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Set default category if available after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoryListProvider);
      if (categories.isNotEmpty && _selectedCategoryId == null) {
        setState(() {
          _selectedCategoryId = categories.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final product = ProductModel(
        id:
            DateTime.now().millisecondsSinceEpoch %
            0xFFFFFFFF, // Ensure ID is within valid range
        name: _nameController.text,
        categoryId:
            _selectedCategoryId ??
            1, // Default to first category if none selected
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
      );

      ref.read(productListProvider.notifier).addProduct(product);
      widget.onProductAdded?.call();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
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
                setState(() {
                  _selectedCategoryId = value;
                });
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
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
