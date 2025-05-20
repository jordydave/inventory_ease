import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load products when dashboard is first displayed
    Future.microtask(() {
      ref.read(productListProvider.notifier).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);

    // Calculate summary metrics
    final totalProducts = products.length;
    final totalStock = products.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );
    final totalValue = products.fold<double>(
      0,
      (sum, product) => sum + (product.price * product.quantity),
    );
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final lowStockProducts = products.where((p) => p.quantity < 5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _SummaryCard(
                  title: 'Total Products',
                  value: totalProducts.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
                _SummaryCard(
                  title: 'Total Stock',
                  value: totalStock.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.green,
                ),
                _SummaryCard(
                  title: 'Total Value',
                  value: currencyFormatter.format(totalValue),
                  icon: Icons.attach_money,
                  color: Colors.orange,
                ),
              ],
            ),
            if (lowStockProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Low Stock Alert',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lowStockProducts.length,
                itemBuilder: (context, index) {
                  final product = lowStockProducts[index];
                  return Card(
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: Text('Quantity: ${product.quantity}'),
                      leading: const Icon(Icons.warning, color: Colors.orange),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('Product List'),
                    onPressed: () => Navigator.pushNamed(context, '/products'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    onPressed:
                        () => Navigator.pushNamed(context, '/add-product'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.category),
                    label: const Text('Categories'),
                    onPressed:
                        () => Navigator.pushNamed(context, '/categories'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Stock History'),
                    onPressed:
                        () => Navigator.pushNamed(context, '/stock-history'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
