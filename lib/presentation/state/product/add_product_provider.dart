import 'package:flutter_riverpod/flutter_riverpod.dart';

final addProductFormProvider =
    StateNotifierProvider<AddProductFormNotifier, AddProductFormState>((ref) {
      return AddProductFormNotifier();
    });

class AddProductFormState {
  final String name;
  final int categoryId;
  final int quantity;
  final double price;
  final bool isLoading;
  final String? error;

  AddProductFormState({
    this.name = '',
    this.categoryId = 0,
    this.quantity = 0,
    this.price = 0.0,
    this.isLoading = false,
    this.error,
  });

  AddProductFormState copyWith({
    String? name,
    int? categoryId,
    int? quantity,
    double? price,
    bool? isLoading,
    String? error,
  }) {
    return AddProductFormState(
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isValid =>
      name.isNotEmpty && categoryId > 0 && quantity >= 0 && price > 0;
}

class AddProductFormNotifier extends StateNotifier<AddProductFormState> {
  AddProductFormNotifier() : super(AddProductFormState());

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateCategory(int categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void updateQuantity(int quantity) {
    state = state.copyWith(quantity: quantity);
  }

  void updatePrice(double price) {
    state = state.copyWith(price: price);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = AddProductFormState();
  }
}
