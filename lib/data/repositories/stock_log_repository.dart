import 'package:inventory_ease/core/services/local_db_service.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';

class StockLogRepository {
  final LocalDbService _dbService;

  StockLogRepository(this._dbService);

  Future<void> addLog(StockLogModel log) async {
    await _dbService.addStockLog(log);
  }

  List<StockLogModel> getAllLogs() {
    return _dbService.getAllStockLogs()..sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    ); // Sort by most recent first
  }

  List<StockLogModel> getLogsForProduct(int productId) {
    return _dbService.getStockLogsForProduct(productId)..sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    ); // Sort by most recent first
  }

  Future<void> deleteLog(int id) async {
    await _dbService.deleteStockLog(id);
  }
}
