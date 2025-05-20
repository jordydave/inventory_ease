import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:inventory_ease/data/repositories/stock_log_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  late LocalDbService dbService;
  late StockLogRepository repository;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    
    // Register the StockLogModel adapter
    Hive.registerAdapter(StockLogModelAdapter());
    
    dbService = LocalDbService();
    await dbService.init();
    repository = StockLogRepository(dbService);
  });

  tearDown(() async {
    // Clean up Hive boxes
    await Hive.close();
    // Clean up temp directory
    await tempDir.delete(recursive: true);
  });

  test('Stock log operations work correctly', () async {
    final now = DateTime.now();
    
    // Create test logs with different timestamps
    final stockInLog = StockLogModel(
      id: 1,
      productId: 1,
      change: 10,  // Positive for stock-in
      timestamp: now.subtract(const Duration(hours: 1)), // Earlier timestamp
      note: 'Initial stock',
    );

    final stockOutLog = StockLogModel(
      id: 2,
      productId: 1,
      change: -5,  // Negative for stock-out
      timestamp: now, // Later timestamp
      note: 'Sold items',
    );

    // Test adding logs
    await repository.addLog(stockInLog);
    await repository.addLog(stockOutLog);
    expect(repository.getAllLogs().length, 2);

    // Test getting logs for specific product
    final productLogs = repository.getLogsForProduct(1);
    expect(productLogs.length, 2);
    // Verify logs are sorted by timestamp (most recent first)
    expect(productLogs[0].change, -5);  // Stock-out (more recent)
    expect(productLogs[1].change, 10);  // Stock-in (older)

    // Test delete
    await repository.deleteLog(1);
    expect(repository.getAllLogs().length, 1);
  });
} 