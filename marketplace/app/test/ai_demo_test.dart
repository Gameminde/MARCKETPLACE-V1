import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_app/screens/ai_demo/ai_demo_screen.dart';

/// 🧪 Tests pour l'écran de démonstration IA
void main() {
  group('AIDemoScreen Tests', () {
    testWidgets('Affiche correctement l\'en-tête IA', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AIDemoScreen(),
        ),
      );

      // Vérifier que l'en-tête est affiché
      expect(find.text('🚀 Démo IA - Phase 4'), findsOneWidget);
      expect(find.text('Intelligence Artificielle Révolutionnaire'), findsOneWidget);
      
      // Vérifier les fonctionnalités IA
      expect(find.text('⚡ Validation <20 secondes'), findsOneWidget);
      expect(find.text('🎯 SEO automatique'), findsOneWidget);
      expect(find.text('📊 Analyse marché temps réel'), findsOneWidget);
      expect(find.text('🔮 Prévisions prédictives'), findsOneWidget);
    });

    testWidgets('Affiche toutes les sections IA', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AIDemoScreen(),
        ),
      );

      // Vérifier que toutes les sections sont présentes
      expect(find.text('🔍 Validation IA Automatique'), findsOneWidget);
      expect(find.text('✨ Génération de Contenu IA'), findsOneWidget);
      expect(find.text('📊 Analyse de Marché IA'), findsOneWidget);
      expect(find.text('💡 Analytics Prédictifs IA'), findsOneWidget);
      expect(find.text('📈 Prévisions de Ventes IA'), findsOneWidget);
    });

    testWidgets('Bouton de démonstration complète est présent', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AIDemoScreen(),
        ),
      );

      // Vérifier le bouton de démonstration complète
      expect(find.text('🚀 DÉMONSTRATION COMPLÈTE IA'), findsOneWidget);
    });

    testWidgets('Boutons de test individuels sont présents', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AIDemoScreen(),
        ),
      );

      // Vérifier les boutons de test individuels
      expect(find.text('Valider avec IA'), findsOneWidget);
      expect(find.text('Générer du contenu IA'), findsOneWidget);
      expect(find.text('Analyser le marché'), findsOneWidget);
      expect(find.text('Obtenir des insights'), findsOneWidget);
      expect(find.text('Prévoir les ventes'), findsOneWidget);
    });
  });
}
