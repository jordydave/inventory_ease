# InventoryEase Manual Regression Test Checklist

## 1. Category Management
- [✅] Add a new category
  - [✅] Verify category appears in list
  - [✅] Verify category appears in product form dropdown
- [✅] Edit an existing category
  - [✅] Verify changes reflect in product list
- [✅] Delete a category
  - [✅] Verify category is removed
  - [✅] Verify products in that category are handled correctly

## 2. Product Management
- [✅] Add a new product
  - [✅] Fill all required fields
  - [✅] Select category
  - [✅] Verify product appears in list
  - [✅] Verify dashboard totals update
- [✅] Edit an existing product
  - [✅] Change name, price, quantity
  - [✅] Verify changes reflect in list
  - [✅] Verify dashboard totals update
- [✅] Delete a product
  - [✅] Verify product is removed
  - [✅] Verify dashboard totals update

## 3. Stock Operations
- [✅] Stock In
  - [✅] Add quantity to existing product
  - [✅] Verify product quantity updates
  - [✅] Verify stock history log created
  - [✅] Verify dashboard totals update
- [✅] Stock Out
  - [✅] Remove quantity from existing product
  - [✅] Verify product quantity updates
  - [✅] Verify stock history log created
  - [✅] Verify dashboard totals update

## 4. Search and Filter
- [✅] Search by product name
  - [✅] Verify matching products shown
  - [✅] Verify non-matching products hidden
- [✅] Filter by category
  - [✅] Verify only products in selected category shown
  - [✅] Verify clear filter works

## 5. Dashboard Features
- [ ] Summary Cards
  - [✅] Verify total products count
  - [✅] Verify total stock count
  - [✅] Verify total value calculation
- [ ] Low Stock Alert
  - [✅] Verify alert appears for products < 5 quantity
  - [✅] Verify alert disappears when stock increased

## 6. Navigation
- [✅] Verify all navigation buttons work
  - [✅] Dashboard → Product List
  - [✅] Dashboard → Add Product
  - [✅] Dashboard → Stock History
- [✅] Verify back navigation works

## 7. Data Persistence
- [✅] Add test data
- [✅] Force close app
- [✅] Reopen app
- [✅] Verify all data persists:
  - [✅] Categories
  - [✅] Products
  - [✅] Stock history
  - [✅] Dashboard calculations

## 8. Error Handling
- [✅] Try to add product with invalid data
  - [✅] Verify appropriate error messages
- [✅] Try to stock out more than available
  - [✅] Verify appropriate error messages
- [✅] Try to delete category with products
  - [✅] Verify appropriate error messages

## 9. UI/UX
- [✅] Verify consistent theme throughout app
- [✅] Verify responsive layout on different screen sizes
- [✅] Verify loading states
- [✅] Verify error states
- [✅] Verify success feedback

## 10. Performance
- [✅] Test with large number of products
- [✅] Test with large number of stock operations
- [✅] Verify app remains responsive
- [✅] Verify dashboard updates quickly

## Notes
- Test each feature in isolation first
- Then test feature interactions
- Document any issues found
- Test both success and error paths
- Verify data consistency across all screens 