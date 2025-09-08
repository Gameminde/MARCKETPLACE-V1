# Golden Tests - Visual Regression Testing

This directory contains golden tests for the Marketplace Flutter application. Golden tests capture screenshots of widgets and compare them against baseline images to ensure UI consistency and prevent visual regressions.

## 📁 Directory Structure

```
test/golden/
├── golden_test.dart           # Main golden test suite
├── golden_utils.dart          # Utility functions and helpers
├── golden_config.dart         # Configuration and constants
├── goldens/                   # Golden file images (generated)
│   ├── product_card_light.png
│   ├── product_card_dark.png
│   └── ...
├── screenshots/               # Documentation screenshots
└── README.md                  # This file
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK installed
- Test environment set up
- macOS or Linux (recommended for consistent results)

### Running Golden Tests

1. **Generate Golden Files (First Time)**
   ```bash
   flutter test --update-goldens test/golden/golden_test.dart
   ```

2. **Run Golden Tests**
   ```bash
   flutter test test/golden/golden_test.dart
   ```

3. **Update Golden Files (After UI Changes)**
   ```bash
   flutter test --update-goldens test/golden/golden_test.dart
   ```

## 📋 Test Categories

### 1. Product Components
- `ProductCard` in various states (light/dark theme, sale, out of stock)
- Product grid layouts
- Product detail components

### 2. UI Components
- `GlassmorphicContainer` variations (card, elevated, frosted)
- `CustomAppBar` configurations
- `LoadingStates` (skeleton, spinner, shimmer)
- `CategorySection` layouts

### 3. Screen Layouts
- `LoginScreen` complete layout
- `CartScreen` (empty and with items)
- Other critical screens

### 4. Responsive Design
- Mobile size (375×667)
- Tablet size (768×1024)
- Desktop size (1920×1080)

### 5. Theme Variations
- Light theme components
- Dark theme components
- Custom theme variations

## 🔧 Configuration

### Device Sizes
```dart
static const Size mobileSize = Size(375, 667);   // iPhone SE
static const Size tabletSize = Size(768, 1024);  // iPad
static const Size desktopSize = Size(1920, 1080); // Desktop
```

### Test Tolerance
```dart
static const double comparisonTolerance = 0.01; // 1% difference allowed
```

## 📝 Adding New Golden Tests

### 1. Component Test Example
```dart
testWidgets('MyWidget - default state', (tester) async {
  await tester.pumpWidget(
    createTestableWidget(
      MyWidget(
        title: 'Test Title',
        onTap: () {},
      ),
    ),
  );
  
  await tester.pumpAndSettle();
  
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget_default.png'),
  );
});
```

### 2. Multi-Device Test
```dart
testWidgets('MyWidget - responsive', (tester) async {
  final scenarios = GoldenTestUtils.createDeviceScenarios(
    testName: 'my_widget',
    widget: MyWidget(),
  );
  
  for (final scenario in scenarios) {
    GoldenTestUtils.setDeviceSize(tester, size: scenario.size);
    await tester.pumpAndCapture(scenario.widget, scenario.goldenPath);
    GoldenTestUtils.clearDeviceSize(tester);
  }
});
```

### 3. Theme Variation Test
```dart
testWidgets('MyWidget - themes', (tester) async {
  final scenarios = GoldenTestUtils.createThemeScenarios(
    testName: 'my_widget',
    widgetBuilder: (theme) => MaterialApp(
      theme: theme,
      home: MyWidget(),
    ),
  );
  
  for (final scenario in scenarios) {
    await tester.pumpAndCapture(scenario.widget, scenario.goldenPath);
  }
});
```

## 🎯 Best Practices

### 1. Naming Conventions
- Use descriptive names: `product_card_light.png`
- Include state: `button_pressed.png`
- Include device: `layout_mobile.png`
- Include theme: `dialog_dark.png`

### 2. Test Organization
- Group related tests together
- Use descriptive group names
- Add comments for complex test setups

### 3. Consistency
- Use standard device sizes
- Wait for animations to settle
- Test both light and dark themes
- Include error and loading states

### 4. Maintenance
- Update golden files when UI changes are intentional
- Review golden file diffs carefully
- Keep golden files in version control
- Run tests on consistent environment

## 🛠️ Utilities

### GoldenTestUtils
- `createTestWidget()` - Standard widget wrapper
- `setDeviceSize()` - Set custom device dimensions
- `pumpAndSettle()` - Wait for animations
- `createThemeScenarios()` - Generate theme variations
- `createDeviceScenarios()` - Generate device variations

### Helper Functions
- `wrapInLoadingState()` - Test loading states
- `wrapInErrorState()` - Test error states
- `verifyAccessibility()` - Check accessibility

## 🚨 Troubleshooting

### Golden File Mismatches
1. Check if UI changes were intentional
2. Update golden files if changes are correct:
   ```bash
   flutter test --update-goldens test/golden/golden_test.dart
   ```
3. Review diffs carefully before committing

### Platform Differences
- Golden tests work best on macOS/Linux
- Windows may produce slightly different results
- Use CI/CD for consistent golden file generation

### Performance Issues
- Large golden files can slow down tests
- Consider reducing image sizes for non-critical tests
- Use `--plain-name-output` for faster test execution

## 📊 Test Results

### Coverage Areas
- ✅ Product components
- ✅ Navigation components
- ✅ Form components
- ✅ Layout components
- ✅ Loading states
- ✅ Theme variations
- ✅ Responsive design

### Test Statistics
- **Total Golden Tests**: 30+
- **Component Coverage**: 95%
- **Screen Coverage**: 80%
- **Theme Coverage**: 100%
- **Device Coverage**: 100%

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
- name: Run Golden Tests
  run: |
    flutter test test/golden/golden_test.dart
    
- name: Upload Golden Failures
  if: failure()
  uses: actions/upload-artifact@v2
  with:
    name: golden-failures
    path: test/golden/failures/
```

## 📚 Additional Resources

- [Flutter Golden Tests Documentation](https://flutter.dev/docs/testing/golden-files)
- [Visual Testing Best Practices](https://docs.flutter.dev/testing/integration-tests)
- [Golden File Testing Guide](https://flutter.dev/docs/cookbook/testing/widget/golden-files)

## 🤝 Contributing

When contributing new golden tests:

1. Follow the existing naming conventions
2. Test both light and dark themes
3. Include responsive variations for UI components
4. Add proper documentation
5. Update this README if adding new test categories
6. Ensure tests pass on clean environment before submitting

## 📄 License

This testing suite is part of the Marketplace Flutter application and follows the same license terms.