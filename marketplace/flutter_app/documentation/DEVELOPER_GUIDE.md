# Marketplace App - Developer Guide

## Quick Start

### Prerequisites
- Flutter 3.16.0+, Dart 3.2.0+
- Android Studio/VS Code with Flutter plugins
- Xcode 14+ (iOS), Android SDK API 21+

### Setup
```bash
git clone https://github.com/marketplace/flutter-app.git
cd marketplace-flutter-app
flutter pub get
cp .env.example .env.development
flutter run --debug --flavor development
```

## Architecture

### State Management
Uses Provider pattern with ChangeNotifier:
- `AuthProvider`: User authentication and JWT management
- `CartProvider`: Shopping cart with persistence
- `SearchProvider`: AI search and filters
- `ThemeProvider`: Dynamic glassmorphic theming

### Project Structure
```
lib/
├── main.dart              # App entry point
├── providers/             # State management
├── screens/              # UI screens
├── widgets/              # Reusable components
├── services/             # Business logic & APIs
├── models/               # Data models
└── utils/                # Utilities
```

## Development Guidelines

### Code Style
- Follow Dart style guide
- Use `const` constructors
- Document public APIs with `///`
- Implement proper error handling

### Performance
- Use `ListView.builder` for lists
- Implement `AutomaticKeepAliveClientMixin`
- Add `RepaintBoundary` for animations
- Dispose resources in `dispose()`

## Testing

### Test Types
```bash
# Unit tests (90% coverage target)
flutter test

# Widget tests
flutter test test/widgets/

# Integration tests
flutter test integration_test/

# Golden tests
flutter test --update-goldens test/golden/
```

### Test Structure
```dart
void main() {
  group('ServiceName', () {
    setUp(() {
      // Setup mocks
    });
    
    test('should do something', () async {
      // Arrange, Act, Assert
    });
  });
}
```

## API Integration

### Authentication
```dart
// POST /auth/login
{
  "email": "user@example.com",
  "password": "password"
}
```

### Products
```dart
// GET /products?page=1&limit=20&search=iPhone
{
  "products": [...],
  "pagination": {...}
}
```

### WebSocket Events
```dart
// Real-time updates
ws.send({
  "type": "send_message",
  "payload": {...}
});
```

## Build & Deployment

### Development
```bash
flutter run --debug --flavor development
```

### Production
```bash
# Android
flutter build appbundle --release --obfuscate

# iOS
flutter build ios --release --obfuscate
```

### CI/CD
Automated pipeline handles:
- Code quality checks
- Automated testing
- Security scanning
- Multi-platform builds
- App store deployment

## Key Features Implementation

### Glassmorphic Design
```dart
GlassmorphicContainer(
  blur: 20,
  opacity: 0.2,
  child: YourWidget(),
)
```

### AI Search
```dart
SearchProvider.instance.search(
  query: "iPhone 15",
  filters: SearchFilters(category: "electronics"),
)
```

### Performance Monitoring
```dart
PerformanceService.instance.trackScreenNavigation("ProductDetail");
```

## Maintenance

### Regular Tasks
- Monthly dependency updates
- Weekly security patches
- Performance monitoring
- User feedback analysis

### Support Contacts
- Technical: tech-lead@marketplace.com
- DevOps: devops@marketplace.com
- QA: qa@marketplace.com

---

**For detailed documentation, visit:** [docs.marketplace.com/developers](https://docs.marketplace.com/developers)