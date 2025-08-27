import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_integration_service.dart';
import '../../widgets/ai_validation_widget.dart';
import '../../widgets/ai_suggestions_widget.dart';
import '../../widgets/ai_analytics_widget.dart';

/// 🚀 ÉCRAN DE DÉMONSTRATION IA COMPLÈTE - PHASE 4 MARKETPLACE
/// 
/// Cet écran démontre toutes les fonctionnalités IA révolutionnaires :
/// - Validation automatique des produits <20 secondes
/// - Génération de contenu SEO optimisé
/// - Analyse de marché et positionnement prix
/// - Insights analytics prédictifs
/// - Prévisions de ventes avec IA
class AIDemoScreen extends StatefulWidget {
  const AIDemoScreen({super.key});

  @override
  State<AIDemoScreen> createState() => _AIDemoScreenState();
}

class _AIDemoScreenState extends State<AIDemoScreen> {
  final AIIntegrationService _aiService = AIIntegrationService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Données de démonstration
  final _demoProduct = {
    'title': 'Smartphone Android Premium 2025',
    'description': 'Dernière génération avec appareil photo 200MP, écran 6.8" AMOLED, batterie 5000mAh',
    'category': 'tech',
    'price': 699.99,
  };
  
  // États IA
  Map<String, dynamic>? _validationResult;
  Map<String, dynamic>? _contentGeneration;
  Map<String, dynamic>? _marketAnalysis;
  Map<String, dynamic>? _analyticsInsights;
  Map<String, dynamic>? _salesForecast;
  
  bool _isProcessing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Démo IA - Phase 4'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Section validation IA
            _buildValidationSection(),
            const SizedBox(height: 24),
            
            // Section génération de contenu
            _buildContentGenerationSection(),
            const SizedBox(height: 24),
            
            // Section analyse de marché
            _buildMarketAnalysisSection(),
            const SizedBox(height: 24),
            
            // Section analytics prédictifs
            _buildAnalyticsSection(),
            const SizedBox(height: 24),
            
            // Section prévisions ventes
            _buildSalesForecastSection(),
            const SizedBox(height: 24),
            
            // Bouton de démonstration complète
            _buildCompleteDemoButton(),
          ],
        ),
      ),
    );
  }

  /// En-tête avec description des fonctionnalités IA
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Intelligence Artificielle Révolutionnaire',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Découvrez comment notre IA transforme votre expérience marketplace :',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureChip('⚡ Validation <20 secondes'),
          _buildFeatureChip('🎯 SEO automatique'),
          _buildFeatureChip('📊 Analyse marché temps réel'),
          _buildFeatureChip('🔮 Prévisions prédictives'),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Section validation IA des produits
  Widget _buildValidationSection() {
    return _buildSectionCard(
      title: '🔍 Validation IA Automatique',
      subtitle: 'Analyse complète en <20 secondes',
      child: Column(
        children: [
          if (_validationResult != null) ...[
            AIValidationWidget(validationResult: _validationResult!),
            const SizedBox(height: 16),
          ],
          
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _runAIValidation,
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology),
            label: Text(_isProcessing ? 'Validation en cours...' : 'Valider avec IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Section génération de contenu IA
  Widget _buildContentGenerationSection() {
    return _buildSectionCard(
      title: '✨ Génération de Contenu IA',
      subtitle: 'SEO optimisé automatiquement',
      child: Column(
        children: [
          if (_contentGeneration != null) ...[
            AISuggestionsWidget(suggestions: _contentGeneration!),
            const SizedBox(height: 16),
          ],
          
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _generateContent,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Générer du contenu IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Section analyse de marché IA
  Widget _buildMarketAnalysisSection() {
    return _buildSectionCard(
      title: '📊 Analyse de Marché IA',
      subtitle: 'Positionnement et prix optimaux',
      child: Column(
        children: [
          if (_marketAnalysis != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Analyse Marché',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  _buildMarketMetric('Score marché', '${_marketAnalysis!['score']}/100'),
                  _buildMarketMetric('Position', _marketAnalysis!['marketPosition'] ?? 'N/A'),
                  _buildMarketMetric('Prix optimal', '${_marketAnalysis!['optimalPrice']}€'),
                  _buildMarketMetric('Niveau demande', _marketAnalysis!['demandLevel'] ?? 'N/A'),
                  
                  if (_marketAnalysis!['suggestions'] != null && 
                      (_marketAnalysis!['suggestions'] as List).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Suggestions:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_marketAnalysis!['suggestions'] as List).map((suggestion) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb, size: 16, color: Colors.orange[600]),
                            const SizedBox(width: 8),
                            Expanded(child: Text(suggestion.toString())),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _analyzeMarket,
            icon: const Icon(Icons.analytics),
            label: const Text('Analyser le marché'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Section analytics prédictifs IA
  Widget _buildAnalyticsSection() {
    return _buildSectionCard(
      title: '💡 Analytics Prédictifs IA',
      subtitle: 'Insights et recommandations intelligentes',
      child: Column(
        children: [
          if (_analyticsInsights != null) ...[
            AIAnalyticsWidget(insights: _analyticsInsights!),
            const SizedBox(height: 16),
          ],
          
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _getAnalyticsInsights,
            icon: const Icon(Icons.insights),
            label: const Text('Obtenir des insights'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Section prévisions de ventes IA
  Widget _buildSalesForecastSection() {
    return _buildSectionCard(
      title: '📈 Prévisions de Ventes IA',
      subtitle: 'Prédictions avec intervalles de confiance',
      child: Column(
        children: [
          if (_salesForecast != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Prévisions 30 jours',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  _buildForecastMetric('Confiance', '${(_salesForecast!['confidence'] * 100).round()}%'),
                  _buildForecastMetric('Facteurs', '${(_salesForecast!['factors'] as List).length}'),
                  _buildForecastMetric('Recommandations', '${(_salesForecast!['recommendations'] as List).length}'),
                  
                  const SizedBox(height: 16),
                  Text(
                    'Prévisions détaillées:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (_salesForecast!['predictions'] as List).length,
                      itemBuilder: (context, index) {
                        final prediction = _salesForecast!['predictions'][index];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'J${prediction['day']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${prediction['predictedSales']}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(prediction['confidence'] * 100).round()}%',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _getSalesForecast,
            icon: const Icon(Icons.forecast),
            label: const Text('Prévoir les ventes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton de démonstration complète
  Widget _buildCompleteDemoButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _runCompleteDemo,
        icon: const Icon(Icons.rocket_launch),
        label: const Text('🚀 DÉMONSTRATION COMPLÈTE IA'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Carte de section
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  // ===== MÉTHODES IA =====

  /// Validation IA complète
  Future<void> _runAIValidation() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Simuler des images pour la démo
      final images = [
        XFile('demo_image_1.jpg'),
        XFile('demo_image_2.jpg'),
        XFile('demo_image_3.jpg'),
      ];

      final result = await _aiService.validateProductComplete(
        title: _demoProduct['title'],
        description: _demoProduct['description'],
        price: _demoProduct['price'],
        category: _demoProduct['category'],
        images: images,
      );

      setState(() {
        _validationResult = result;
        _isProcessing = false;
      });

      _showSuccessMessage('Validation IA terminée ! Score: ${result['score']}/100');

    } catch (error) {
      setState(() {
        _error = error.toString();
        _isProcessing = false;
      });
      _showErrorMessage('Erreur lors de la validation IA');
    }
  }

  /// Génération de contenu IA
  Future<void> _generateContent() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await _aiService.generateContent(
        title: _demoProduct['title'],
        category: _demoProduct['category'],
        description: _demoProduct['description'],
      );

      setState(() {
        _contentGeneration = result;
        _isProcessing = false;
      });

      _showSuccessMessage('Contenu IA généré avec succès !');

    } catch (error) {
      setState(() {
        _error = error.toString();
        _isProcessing = false;
      });
      _showErrorMessage('Erreur lors de la génération de contenu');
    }
  }

  /// Analyse de marché IA
  Future<void> _analyzeMarket() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await _aiService.analyzeMarket(
        _demoProduct['category'],
        _demoProduct['price'],
      );

      setState(() {
        _marketAnalysis = result;
        _isProcessing = false;
      });

      _showSuccessMessage('Analyse de marché terminée ! Score: ${result['score']}/100');

    } catch (error) {
      setState(() {
        _error = error.toString();
        _isProcessing = false;
      });
      _showErrorMessage('Erreur lors de l\'analyse de marché');
    }
  }

  /// Insights analytics IA
  Future<void> _getAnalyticsInsights() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await _aiService.getPredictiveAnalytics(
        shopId: 'demo_shop_001',
        timeframe: '24h',
      );

      setState(() {
        _analyticsInsights = result;
        _isProcessing = false;
      });

      _showSuccessMessage('Insights analytics générés !');

    } catch (error) {
      setState(() {
        _error = error.toString();
        _isProcessing = false;
      });
      _showErrorMessage('Erreur lors de la génération d\'insights');
    }
  }

  /// Prévisions de ventes IA
  Future<void> _getSalesForecast() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await _aiService.getPredictiveAnalytics(
        shopId: 'demo_shop_001',
        timeframe: '30d',
      );

      setState(() {
        _salesForecast = result;
        _isProcessing = false;
      });

      _showSuccessMessage('Prévisions de ventes générées !');

    } catch (error) {
      setState(() {
        _error = error.toString();
        _isProcessing = false;
      });
      _showErrorMessage('Erreur lors de la génération de prévisions');
    }
  }

  /// Démonstration complète IA
  Future<void> _runCompleteDemo() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Exécuter toutes les fonctionnalités IA en parallèle
      final results = await Future.wait([
        _runAIValidation(),
        _generateContent(),
        _analyzeMarket(),
        _getAnalyticsInsights(),
        _getSalesForecast(),
      ]);

      setState(() {
        _isProcessing = false;
      });

      _showSuccessMessage('🎉 Démonstration IA complète terminée ! Toutes les fonctionnalités sont opérationnelles.');

    } catch (error) {
      setState(() {
        _error = error.toString();
        _isProcessing = false;
      });
      _showErrorMessage('Erreur lors de la démonstration complète');
    }
  }

  // ===== UTILITAIRES =====

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
