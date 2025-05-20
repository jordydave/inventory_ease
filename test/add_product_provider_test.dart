import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/presentation/state/product/add_product_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('Form state updates work correctly', () {
    final notifier = container.read(addProductFormProvider.notifier);

    // Test initial state
    expect(container.read(addProductFormProvider).name, '');
    expect(container.read(addProductFormProvider).isValid, false);

    // Test updating fields
    notifier.updateName('Test Product');
    notifier.updateCategory(1);
    notifier.updateQuantity(10);
    notifier.updatePrice(99.99);

    final updatedState = container.read(addProductFormProvider);
    expect(updatedState.name, 'Test Product');
    expect(updatedState.categoryId, 1);
    expect(updatedState.quantity, 10);
    expect(updatedState.price, 99.99);
    expect(updatedState.isValid, true);

    // Test loading state
    notifier.setLoading(true);
    expect(container.read(addProductFormProvider).isLoading, true);

    // Test error state
    notifier.setError('Test error');
    expect(container.read(addProductFormProvider).error, 'Test error');

    // Test reset
    notifier.reset();
    expect(container.read(addProductFormProvider).name, '');
    expect(container.read(addProductFormProvider).isValid, false);
  });
} 