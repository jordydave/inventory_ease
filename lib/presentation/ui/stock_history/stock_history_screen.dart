import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/presentation/state/product/product_list_provider.dart';
import 'package:inventory_ease/presentation/state/stock_history/stock_history_provider.dart';
import 'package:inventory_ease/data/models/product_model.dart';
import 'package:intl/intl.dart';

class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load stock history when screen is mounted
    Future.microtask(
      () => ref.read(stockHistoryProvider.notifier).loadStockHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(stockHistoryProvider);
    final products = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock History')),
      body:
          logs.isEmpty
              ? const Center(child: Text('No stock history available'))
              : ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final product = products.firstWhere(
                    (p) => p.id == log.productId,
                    orElse:
                        () => ProductModel(
                          id: log.productId,
                          name: 'Unknown Product',
                          price: 0,
                          quantity: 0,
                          categoryId: 0,
                        ),
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.note),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy HH:mm',
                            ).format(log.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: Text(
                        log.change > 0 ? '+${log.change}' : '${log.change}',
                        style: TextStyle(
                          color: log.change > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
