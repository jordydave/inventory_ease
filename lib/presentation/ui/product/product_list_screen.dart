import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:inventory_ease/presentation/state/stock_history/stock_history_provider.dart';
import 'dart:math';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Load products when screen opens
    Future.microtask(
      () => ref.read(productListProvider.notifier).loadProducts(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    final filtered =
        products.where((product) {
          final searchText = _searchController.text.toLowerCase();
          final matchesSearch =
              searchText.isEmpty ||
              product.name.toLowerCase().contains(searchText);
          final matchesCategory =
              _selectedCategoryId == null ||
              product.categoryId == _selectedCategoryId;
          return matchesSearch && matchesCategory;
        }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);
    final categories = ref.watch(categoryListProvider);
    final filteredProducts = _filterProducts(products);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/add-product');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int?>(
                  value: _selectedCategoryId,
                  hint: const Text('All Categories'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (categoryId) {
                    setState(() {
                      _selectedCategoryId = categoryId;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child:
                filteredProducts.isEmpty
                    ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _ProductCard(
                          key: ValueKey(product.id),
                          product: product,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductModel product;

  const _ProductCard({super.key, required this.product});

  void _showStockDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
    bool isStockIn,
  ) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final now = DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isStockIn ? 'Stock In' : 'Stock Out'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null) {
                        return 'Please enter a valid number';
                      }
                      if (quantity <= 0) {
                        return 'Quantity must be greater than 0';
                      }
                      if (!isStockIn && quantity > product.quantity) {
                        return 'Cannot stock out more than available (${product.quantity})';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final quantity = int.parse(controller.text);
                    final newQuantity =
                        isStockIn
                            ? product.quantity + quantity
                            : product.quantity - quantity;

                    await ref
                        .read(productListProvider.notifier)
                        .updateProduct(product.copyWith(quantity: newQuantity));

                    final id =
                        (now.millisecondsSinceEpoch % 0xFFFFFFFF) +
                        Random().nextInt(1000);
                    final log = StockLogModel(
                      id: id,
                      productId: product.id,
                      change: isStockIn ? quantity : -quantity,
                      timestamp: now,
                      note: isStockIn ? 'Stock in' : 'Stock out',
                    );
                    await ref
                        .read(stockHistoryProvider.notifier)
                        .addStockLog(log);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isStockIn
                                ? 'Stock in successful'
                                : 'Stock out successful',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(product.name),
        subtitle: Text(
          'Price: ${product.price.toStringAsFixed(2)} | Qty: ${product.quantity}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => _showStockDialog(context, ref, product, true),
              tooltip: 'Stock In',
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle),
              onPressed: () => _showStockDialog(context, ref, product, false),
              tooltip: 'Stock Out',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit-product',
                  arguments: product,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref
                    .read(productListProvider.notifier)
                    .deleteProduct(product.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
