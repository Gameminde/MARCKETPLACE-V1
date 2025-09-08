import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:marketplace/widgets/glassmorphic_container.dart';

void main() {
  group('GlassmorphicContainer Widget Tests', () {
    Widget createTestableWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(body: child),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render card variant', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            GlassmorphicContainer.card(
              child: const Text('Test Content'),
            ),
          ),
        );

        expect(find.text('Test Content'), findsOneWidget);
        expect(find.byType(Container), findsAtLeastNWidgets(1));
      });

      testWidgets('should render panel variant', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            GlassmorphicContainer.panel(
              child: const Text('Panel Content'),
            ),
          ),
        );

        expect(find.text('Panel Content'), findsOneWidget);
      });

      testWidgets('should render button variant', (tester) async {
        bool wasTapped = false;
        
        await tester.pumpWidget(
          createTestableWidget(
            GlassmorphicContainer.button(
              onTap: () => wasTapped = true,
              child: const Text('Button Content'),
            ),
          ),
        );

        await tester.tap(find.text('Button Content'));
        expect(wasTapped, isTrue);
      });
    });

    group('Visual Properties', () {
      testWidgets('should apply custom blur effect', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            GlassmorphicContainer(
              blur: 15.0,
              child: const Text('Blurred Content'),
            ),
          ),
        );

        // Check for BackdropFilter widget
        expect(find.byType(BackdropFilter), findsOneWidget);
      });

      testWidgets('should apply custom border radius', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            GlassmorphicContainer(
              borderRadius: 20.0,
              child: const Text('Rounded Content'),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(20.0)));
      });

      testWidgets('should apply custom opacity', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            GlassmorphicContainer(
              opacity: 0.3,
              child: const Text('Transparent Content'),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color?.opacity, equals(0.3));
      });
    });

    group('Interactive Features', () {
      testWidgets('should handle tap events', (tester) async {
        bool wasTapped = false;
        
        await tester.pumpWidget(
          createTestableWidget(
            GlassmorphicContainer(
              onTap: () => wasTapped = true,
              child: const Text('Tappable Content'),
            ),
          ),
        );

        await tester.tap(find.text('Tappable Content'));
        expect(wasTapped, isTrue);
      });

      testWidgets('should show elevation on tap', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            GlassmorphicContainer(
              onTap: () {},
              child: const Text('Elevated Content'),
            ),
          ),
        );

        // Tap and hold to see elevation effect
        await tester.press(find.text('Elevated Content'));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should have visual feedback
        expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(1));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null child gracefully', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const GlassmorphicContainer(
              child: SizedBox.shrink(),
            ),
          ),
        );

        expect(find.byType(GlassmorphicContainer), findsOneWidget);
      });

      testWidgets('should handle extreme blur values', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            GlassmorphicContainer(
              blur: 100.0,
              child: const Text('Extreme Blur'),
            ),
          ),
        );

        expect(find.byType(BackdropFilter), findsOneWidget);
      });
    });
  });
}