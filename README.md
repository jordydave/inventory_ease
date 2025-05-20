# InventoryEase

A modern inventory management application built with Flutter, designed for small businesses, kiosks, and individuals to manage their inventory efficiently.

## Features

- 📦 **Product Management**
  - Add, edit, and delete products
  - Track product quantities and prices
  - Organize products by categories
  - Search and filter products

- 📊 **Stock Operations**
  - Stock in/out functionality
  - Real-time quantity updates
  - Stock history tracking
  - Detailed stock logs

- 📱 **Dashboard**
  - Overview of total products
  - Total stock value calculation
  - Low stock alerts
  - Category-wise breakdown

- 🗂️ **Category Management**
  - Create and manage product categories
  - Edit category names
  - Delete unused categories

## Technical Details

- **Architecture**: Clean architecture with separation of concerns
- **State Management**: Riverpod for efficient state management
- **Local Storage**: Hive for fast and reliable local database
- **UI Framework**: Flutter Material Design
- **Offline-First**: Works without internet connection

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jordydave/inventory_ease.git
   ```

2. Navigate to the project directory:
   ```bash
   cd inventory_ease
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/           # Core functionality and utilities
├── data/           # Data models and repositories
├── presentation/   # UI and state management
└── main.dart       # Application entry point
```

## Testing

The project includes comprehensive test coverage:
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for critical flows

Run tests using:
```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Riverpod for state management
- Hive for local storage
- All contributors who have helped shape this project 
