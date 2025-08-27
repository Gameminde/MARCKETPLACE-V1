import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/api_provider.dart';
import '../../services/ai_integration_service.dart';
import '../../widgets/image_picker_widget.dart';

/// 🚀 UPLOAD SCREEN AVEC VALIDATION IA COMPLÈTE - PHASE 4 MARKETPLACE
/// 
/// Cet écran intègre la validation IA révolutionnaire :
/// - Validation automatique <20 secondes
/// - Suggestions d'amélioration en temps réel
/// - Génération automatique de contenu SEO
/// - Analyse de marché et positionnement prix
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  
  String _selectedCategory = '';
  List<String> _selectedTags = [];
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _error;
  
  // Résultats de validation IA
  Map<String, dynamic>? _aiValidationResult;
  Map<String, dynamic>? _aiSuggestions;
  Map<String, dynamic>? _seoOptimizations;
  
  // Service IA
  late final AIIntegrationService _aiService;

  final List<String> _categories = [
    'Mode & Accessoires',
    'Beauté & Santé',
    'Maison & Jardin',
    'Sport & Loisirs',
    'Technologie',
    'Livres & Médias',
    'Jouets & Jeux',
    'Automobile',
    'Alimentation',
    'Autres',
  ];

  final List<String> _availableTags = [
    'Nouveau', 'Populaire', 'Promotion', 'Éco-responsable',
    'Fait main', 'Vintage', 'Luxueux', 'Économique',
    'Rapide', 'Durable', 'Tendance', 'Classique',
  ];

  @override
  void initState() {
    super.initState();
    _aiService = AIIntegrationService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un produit'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publier'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images du produit
              _buildImageSection(),
              const SizedBox(height: 32),
              
              // Validation IA en temps réel
              if (_aiValidationResult != null) _buildAIValidationResult(),
              if (_aiValidationResult != null) const SizedBox(height: 32),
              
              // Suggestions d'amélioration IA
              if (_aiSuggestions != null) _buildAIImprovementSuggestions(),
              if (_aiSuggestions != null) const SizedBox(height: 32),
              
              // Optimisations SEO IA
              if (_seoOptimizations != null) _buildSEOOptimizations(),
              if (_seoOptimizations != null) const SizedBox(height: 32),
              
              // Informations de base
              _buildBasicInfoSection(),
              const SizedBox(height: 32),
              
              // Prix et stock
              _buildPricingStockSection(),
              const SizedBox(height: 32),
              
              // Catégorie et tags
              _buildCategoryTagsSection(),
              const SizedBox(height: 32),
              
              // Bouton d'analyse IA
              _buildAIAnalysisButton(),
              const SizedBox(height: 32),
              
              // Gestion des erreurs
              if (_error != null) _buildErrorSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🖼️ Section de sélection d'images avec validation IA
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images du produit *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoutez au moins 3 images de qualité pour maximiser vos ventes',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Widget de sélection d'images
        ImagePickerWidget(
          images: _selectedImages.map((e) => e.path).toList(),
          onImagesChanged: (images) {
            // Convertir les chemins en XFile pour la compatibilité
            setState(() {
              _selectedImages = images.map((path) => XFile(path)).toList();
            });
            
            // Déclencher la validation IA automatiquement
            if (images.length >= 3) {
              _triggerAIValidation();
            }
          },
          maxImages: 8,
        ),
        
        // Indicateur de qualité des images
        if (_aiValidationResult != null && _aiValidationResult!['analysis']?['images'] != null)
          _buildImageQualityIndicator(),
      ],
    );
  }

  /// 📊 Résultat de validation IA
  Widget _buildAIValidationResult() {
    final result = _aiValidationResult!;
    final score = result['score'] ?? 0;
    final approved = result['approved'] ?? false;
    final processingTime = result['processingTime'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: approved ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: approved ? Colors.green[200]! : Colors.orange[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved ? Icons.check_circle : Icons.warning,
                color: approved ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                approved ? 'Produit validé par IA' : 'Améliorations recommandées',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: approved ? Colors.green[700] : Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Score de qualité
          Row(
            children: [
              Text(
                'Score de qualité: ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(score),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score/100',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          // Temps de traitement
          Text(
            'Validation en ${processingTime}ms',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          // Niveau de risque
          if (result['riskLevel'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Niveau de risque: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRiskColor(result['riskLevel']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRiskLabel(result['riskLevel']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 💡 Suggestions d'amélioration IA
  Widget _buildAIImprovementSuggestions() {
    final improvements = _aiSuggestions!['improvements'] as List<dynamic>? ?? [];
    
    if (improvements.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue[600], size: 24),
              const SizedBox(width: 8),
              Text(
                'Suggestions d\'amélioration IA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...improvements.map((improvement) => _buildImprovementCard(improvement)),
        ],
      ),
    );
  }

  /// 🎯 Carte d'amélioration individuelle
  Widget _buildImprovementCard(Map<String, dynamic> improvement) {
    final priority = improvement['priority'] ?? 'medium';
    final priorityColor = _getPriorityColor(priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  improvement['title'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            improvement['description'] ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: Colors.green[600]),
              const SizedBox(width: 4),
              Text(
                improvement['impact'] ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.work, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 4),
              Text(
                'Effort: ${improvement['effort'] ?? 'medium'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🏷️ Optimisations SEO IA
  Widget _buildSEOOptimizations() {
    final seo = _seoOptimizations!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.purple[600], size: 24),
              const SizedBox(width: 8),
              Text(
                'Optimisations SEO IA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Titre optimisé
          if (seo['title'] != null) ...[
            _buildSEOField(
              'Titre SEO',
              seo['title']['current'] ?? '',
              seo['title']['suggested'] ?? '',
              seo['title']['score'] ?? 0,
            ),
            const SizedBox(height: 12),
          ],
          
          // Description optimisée
          if (seo['description'] != null) ...[
            _buildSEOField(
              'Description SEO',
              seo['description']['current'] ?? '',
              seo['description']['suggested'] ?? '',
              seo['description']['score'] ?? 0,
            ),
            const SizedBox(height: 12),
          ],
          
          // Mots-clés
          if (seo['keywords'] != null && seo['keywords'].isNotEmpty) ...[
            Text(
              'Mots-clés suggérés:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (seo['keywords'] as List<dynamic>).map((keyword) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    keyword.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.purple[700],
                    ),
                  ),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 🏷️ Champ SEO individuel
  Widget _buildSEOField(String label, String current, String suggested, int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        
        // Score SEO
        Row(
          children: [
            Text(
              'Score: ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getScoreColor(score),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$score/100',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Texte actuel
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Actuel: $current',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Texte suggéré
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Suggéré: $suggested',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.purple[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        // Bouton d'application
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _applySEOSuggestion(label, suggested),
          icon: const Icon(Icons.check, size: 16),
          label: Text('Appliquer cette suggestion'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.purple[700],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ],
    );
  }

  /// 🎯 Indicateur de qualité des images
  Widget _buildImageQualityIndicator() {
    final imageAnalysis = _aiValidationResult!['analysis']['images'];
    final score = imageAnalysis['score'] ?? 0;
    final quality = imageAnalysis['quality'] ?? 'basic';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.image,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qualité des images: ${_getQualityLabel(quality)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.blue[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Score: $score/100',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔍 Bouton d'analyse IA
  Widget _buildAIAnalysisButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _selectedImages.length >= 3 && !_isAnalyzing ? _triggerAIValidation : null,
        icon: _isAnalyzing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.psychology),
        label: Text(_isAnalyzing ? 'Analyse en cours...' : 'Analyser avec IA'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ===== MÉTHODES DE VALIDATION IA =====

  /// Déclencher la validation IA complète
  Future<void> _triggerAIValidation() async {
    if (_selectedImages.length < 3) {
      _showError('Ajoutez au moins 3 images pour la validation IA');
      return;
    }

    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showError('Remplissez le titre et la description pour la validation IA');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      // Validation IA complète
      final validationResult = await _aiService.validateProductComplete(
        title: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        category: _selectedCategory,
        images: _selectedImages,
      );

      setState(() {
        _aiValidationResult = validationResult;
        _aiSuggestions = {
          'improvements': validationResult['improvements'],
          'estimatedConversion': validationResult['estimatedConversion'],
        };
        _seoOptimizations = validationResult['seoSuggestions'];
        _isAnalyzing = false;
      });

      // Afficher les résultats
      _showAIResults(validationResult);

    } catch (error) {
      setState(() {
        _isAnalyzing = false;
        _error = 'Erreur lors de la validation IA: $error';
      });
    }
  }

  /// Afficher les résultats de l'IA
  void _showAIResults(Map<String, dynamic> result) {
    final score = result['score'] ?? 0;
    final approved = result['approved'] ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              approved ? Icons.check_circle : Icons.warning,
              color: approved ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(approved ? 'Validation réussie !' : 'Améliorations nécessaires'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score de qualité: $score/100'),
            const SizedBox(height: 8),
            Text(
              approved
                  ? 'Votre produit est prêt pour la publication !'
                  : 'Consultez les suggestions d\'amélioration ci-dessous.',
            ),
            if (result['estimatedConversion'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'Taux de conversion estimé: ${result['estimatedConversion']['estimated']}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Appliquer une suggestion SEO
  void _applySEOSuggestion(String field, String suggestion) {
    switch (field) {
      case 'Titre SEO':
        _nameController.text = suggestion;
        break;
      case 'Description SEO':
        _descriptionController.text = suggestion;
        break;
    }
    
    // Rafraîchir l'interface
    setState(() {});
    
    // Afficher confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Suggestion SEO appliquée pour $field'),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  // ===== MÉTHODES UTILITAIRES =====

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getRiskLabel(String riskLevel) {
    switch (riskLevel) {
      case 'low': return 'Faible';
      case 'medium': return 'Moyen';
      case 'high': return 'Élevé';
      default: return 'Inconnu';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getQualityLabel(String quality) {
    switch (quality) {
      case 'excellent': return 'Excellente';
      case 'very_good': return 'Très bonne';
      case 'good': return 'Bonne';
      case 'acceptable': return 'Acceptable';
      case 'basic': return 'Basique';
      case 'poor': return 'Mauvaise';
      default: return 'Inconnue';
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
      ),
    );
  }

  // ===== SECTIONS EXISTANTES (à conserver) =====

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de base',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Nom du produit
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du produit *',
            hintText: 'Ex: Smartphone Android Premium',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir le nom du produit';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Décrivez votre produit en détail...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir une description';
            }
            if (value.length < 50) {
              return 'La description doit contenir au moins 50 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Marque
        TextFormField(
          controller: _brandController,
          decoration: const InputDecoration(
            labelText: 'Marque',
            hintText: 'Ex: Samsung, Apple, Nike...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prix et stock',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix *',
                  hintText: '0.00',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le prix';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Prix invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  hintText: 'Quantité disponible',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie et tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Catégorie
        DropdownButtonFormField<String>(
          value: _selectedCategory.isEmpty ? null : _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Catégorie *',
            border: OutlineInputBorder(),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une catégorie';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Tags
        Text(
          'Tags (sélectionnez jusqu\'à 5)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected && _selectedTags.length < 5) {
                    _selectedTags.add(tag);
                  } else if (!selected) {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Sauvegarder le produit
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      _showError('Veuillez sélectionner au moins une image');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Implémenter la sauvegarde du produit
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit publié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Retourner à l'écran précédent
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() {
        _error = 'Erreur lors de la sauvegarde: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
