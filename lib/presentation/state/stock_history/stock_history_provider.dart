import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/data/models/stock_log_model.dart';
import 'package:inventory_ease/data/repositories/stock_log_repository.dart';
import 'package:inventory_ease/core/services/local_db_service.dart';

final stockLogRepositoryProvider = Provider<StockLogRepository>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  return StockLogRepository(dbService);
});

final stockHistoryProvider =
    StateNotifierProvider<StockHistoryNotifier, List<StockLogModel>>((ref) {
      final repository = ref.watch(stockLogRepositoryProvider);
      return StockHistoryNotifier(repository);
    });

class StockHistoryNotifier extends StateNotifier<List<StockLogModel>> {
  final StockLogRepository _repository;

  StockHistoryNotifier(this._repository) : super([]);

  Future<void> loadStockHistory() async {
    state = _repository.getAllLogs();
  }

  Future<void> addStockLog(StockLogModel log) async {
    await _repository.addLog(log);
    await loadStockHistory(); // Reload all logs to ensure consistency
  }

  Future<void> deleteStockLog(int id) async {
    await _repository.deleteLog(id);
    await loadStockHistory(); // Reload all logs to ensure consistency
  }

  Future<List<StockLogModel>> getLogsForProduct(int productId) async {
    return _repository.getLogsForProduct(productId);
  }

  void addLog(StockLogModel log) {
    state = [...state, log];
  }
}
