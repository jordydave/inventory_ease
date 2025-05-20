import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:inventory_ease/data/repositories/stock_log_repository.dart';
import 'package:inventory_ease/presentation/state/stock_history/stock_history_provider.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late StockLogRepository repository;
  late LocalDbService localDbService;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync();
    
    // Initialize Hive
    Hive.init(dir.path);
    
    // Register the StockLogModel adapter
    Hive.registerAdapter(StockLogModelAdapter());
    
    localDbService = LocalDbService();
    await localDbService.init(hivePath: dir.path);
    repository = StockLogRepository(localDbService);
    container = ProviderContainer(
      overrides: [
        stockHistoryProvider.overrideWith((ref) => StockHistoryNotifier(repository)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
  });

  test('Stock history state management works correctly', () async {
    final notifier = container.read(stockHistoryProvider.notifier);

    // Test initial state
    expect(container.read(stockHistoryProvider), []);

    // Test adding a stock-in log
    final stockInLog = StockLogModel(
      id: 1,
      productId: 1,
      change: 10,
      timestamp: DateTime.now(),
      note: 'Stock in',
    );
    await notifier.addStockLog(stockInLog);
    expect(container.read(stockHistoryProvider).length, 1);
    expect(container.read(stockHistoryProvider).first.change, 10);

    // Test loading stock history
    await notifier.loadStockHistory();
    expect(container.read(stockHistoryProvider).length, 1);

    // Test getting logs for a specific product
    final productLogs = await notifier.getLogsForProduct(1);
    expect(productLogs.length, 1);
    expect(productLogs.first.productId, 1);

    // Test deleting a log
    await notifier.deleteStockLog(stockInLog.id);
    expect(container.read(stockHistoryProvider), []);
  });
} 