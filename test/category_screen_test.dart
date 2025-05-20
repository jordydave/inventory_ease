import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_ease/presentation/state/category/category_list_provider.dart';
import 'package:inventory_ease/presentation/ui/category/category_screen.dart';
import 'package:inventory_ease/presentation/ui/product/add_product_screen.dart';
import 'package:inventory_ease/data/repositories/category_repository.dart';
import 'package:inventory_ease/data/models/category_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'dart:io';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class MockCategoryRepository extends CategoryRepository {
  final List<CategoryModel> _categories = [];
  
  @override
  Future<List<CategoryModel>> getAllCategories() async => List.unmodifiable(_categories);
  
  @override
  Future<void> addCategory(CategoryModel category) async {
    if (!_categories.any((c) => c.id == category.id)) {
      _categories.add(category);
    }
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = MockPathProviderPlatform();
    tempDir = await Directory.systemTemp.createTemp();
    await Hive.initFlutter(tempDir.path);
    
    // Register adapters
    Hive.registerAdapter(CategoryModelAdapter());
    
    // Open boxes
    await Hive.openBox<CategoryModel>('categories');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Adding a category makes it appear in the AddProduct dropdown',
      (WidgetTester tester) async {
    // Create a ProviderContainer with overridden providers
    final container = ProviderContainer(
      overrides: [
        categoryListProvider.overrideWith(
          (ref) => CategoryListNotifier(MockCategoryRepository())..state = [],
        ),
      ],
    );

    // Build the CategoryScreen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CategoryScreen(),
        ),
      ),
    );

    // Verify the screen title
    expect(find.text('Categories'), findsOneWidget);

    // Add a new category
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify dialog is shown
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'Dialog should be shown');
    
    // Find the TextField in the dialog
    final textField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(textField, findsOneWidget, reason: 'TextField should be found in dialog');
    
    await tester.enterText(textField, 'New Category');
    await tester.pumpAndSettle();

    // Find and tap the Add button in the dialog
    final addButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Add'),
    );
    expect(addButton, findsOneWidget, reason: 'Add button should be found in dialog');
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify the category was added to the list
    final categoryCard = find.byType(Card).first;
    final categoryText = find.descendant(
      of: categoryCard,
      matching: find.text('New Category'),
    );
    expect(categoryText, findsOneWidget, reason: 'Category should appear in the list');

    // Get the category ID from the repository
    final categories = container.read(categoryListProvider);
    expect(categories.length, 1, reason: 'Should have one category in state');
    final categoryId = categories[0].id;

    // Navigate to AddProductScreen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AddProductScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the new category appears in the dropdown
    final dropdown = find.byType(DropdownButtonFormField<int>);
    expect(dropdown, findsOneWidget, reason: 'Dropdown should be found');
    
    // Verify the dropdown has the correct value
    final dropdownState = tester.state<FormFieldState<int>>(dropdown);
    expect(dropdownState.value, categoryId, reason: 'Dropdown should have the correct category ID');
    
    // Open the dropdown and wait for animation
    await tester.tap(dropdown);
    await tester.pump(); // Start the animation
    await tester.pump(const Duration(milliseconds: 300)); // Wait for animation to complete
    
    // Look for the category in the dropdown menu overlay
    final dropdownItem = find.descendant(
      of: find.byType(DropdownButtonFormField<int>),
      matching: find.byWidgetPredicate(
        (widget) => widget is DropdownMenuItem<int> && 
                    widget.child is Text && 
                    (widget.child as Text).data == 'New Category',
      ),
    );
    expect(dropdownItem, findsOneWidget, reason: 'Category should appear in dropdown menu');
  });
} 