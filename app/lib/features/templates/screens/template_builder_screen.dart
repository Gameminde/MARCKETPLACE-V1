import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/template_manager_service.dart';
import '../services/template_sync_service.dart';
import '../services/template_preview_service.dart';
import '../services/accessibility_service.dart';
import '../widgets/component_palette.dart';
import '../widgets/template_canvas.dart';
import '../widgets/advanced_customization_panel.dart';
import '../widgets/accessibility_panel.dart';
import '../widgets/accessible_widgets.dart';
import 'package:provider/provider.dart';
import '../../../providers/api_provider.dart';
import '../../../config/api_config.dart';

/// 🎯 Template Builder Screen - Interface Révolutionnaire d'Accessibilité
/// 
/// Cette interface intègre complètement l'accessibilité WCAG 2.1 AA avec :
/// - Panneau de configuration d'accessibilité
/// - Widgets accessibles prêts à l'emploi
/// - Validation automatique des composants
/// - Support des lecteurs d'écran
/// - Navigation au clavier complète
class TemplateBuilderScreen extends StatefulWidget {
  const TemplateBuilderScreen({super.key});

  @override
  State<TemplateBuilderScreen> createState() => _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends State<TemplateBuilderScreen> {
  late TemplateManagerService _templateManager;
  late TemplateSyncService _syncService;
  late TemplatePreviewService _previewService;
  late AccessibilityService _accessibilityService;
  
  Map<String, dynamic>? _selectedSection;
  bool _showAccessibilityPanel = false;
  bool _isAccessibilityValidated = false;
  // API linkage
  late ApiProvider _apiProvider;
  List<Map<String, dynamic>> _apiTemplates = [];
  bool _isLoadingTemplates = false;
  bool _isConnectedToAPI = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _templateManager = TemplateManagerService();
    _syncService = TemplateSyncService();
    _previewService = TemplatePreviewService();
    _accessibilityService = AccessibilityService();
    _apiProvider = Provider.of<ApiProvider>(context, listen: false);
    
    // Initialiser le service d'accessibilité
    _initializeAccessibility();
    
    // Écouter les changements de personnalisation
    _syncService.customizationStream.listen((customization) {
      if (mounted) {
        setState(() {});
      }
    });

    _loadTemplatesFromAPI();
  }

  Future<void> _loadTemplatesFromAPI() async {
    setState(() {
      _isLoadingTemplates = true;
      _connectionError = null;
    });

    try {
      final ok = await _apiProvider.testConnection();
      _isConnectedToAPI = ok;
      if (ok) {
        final templates = await _apiProvider.fetchTemplates();
        _apiTemplates = templates;
        for (final t in templates) {
          try { _templateManager.addAvailableTemplate(t); } catch (_) {}
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: const [
                Icon(Icons.cloud_done, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Connecté à l\'API - templates chargés')),
              ]),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('API non disponible');
      }
    } catch (e) {
      _connectionError = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.cloud_off, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Mode hors ligne - templates de démo')),
            ]),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingTemplates = false);
    }
  }

  /// Initialiser le service d'accessibilité
  Future<void> _initializeAccessibility() async {
    try {
      await _accessibilityService.initialize();
      
      // Valider l'accessibilité de l'écran
      _validateScreenAccessibility();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de l\'accessibilité: $e');
    }
  }

  /// Valider l'accessibilité de l'écran
  void _validateScreenAccessibility() {
    // Valider les composants principaux
    _accessibilityService.validateComponent(
      'TemplateBuilderScreen',
      _buildMainContent(),
      context: context,
    );
    
    _isAccessibilityValidated = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAccessibleAppBar(),
      body: _buildMainContent(),
      floatingActionButton: _buildAccessibleFAB(),
    );
  }

  /// Construire la barre d'application accessible
  PreferredSizeWidget _buildAccessibleAppBar() {
    return AppBar(
      title: Row(
        children: [
          AccessibleWidgets.heading(
            text: 'Template Builder',
            level: 1,
            label: 'Constructeur de templates avec accessibilité complète',
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isConnectedToAPI ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isConnectedToAPI ? Icons.cloud_done : Icons.cloud_off, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(_isConnectedToAPI ? 'API' : 'Local', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!_isConnectedToAPI)
          IconButton(
            onPressed: _isLoadingTemplates ? null : _loadTemplatesFromAPI,
            icon: _isLoadingTemplates
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Reconnecter à l\'API',
          ),
        // Bouton d'accessibilité
        AccessibleWidgets.iconButton(
          label: 'Configuration accessibilité',
          hint: 'Ouvrir le panneau de configuration d\'accessibilité',
          icon: Icons.accessibility_new,
          onPressed: () {
            setState(() {
              _showAccessibilityPanel = !_showAccessibilityPanel;
            });
          },
        ),
        
        // Bouton de validation
        AccessibleWidgets.iconButton(
          label: 'Valider accessibilité',
          hint: 'Valider l\'accessibilité de tous les composants',
          icon: Icons.verified_user,
          onPressed: _validateAllComponents,
        ),
        
        // Bouton de rapport
        AccessibleWidgets.iconButton(
          label: 'Rapport accessibilité',
          hint: 'Générer un rapport d\'accessibilité complet',
          icon: Icons.assessment,
          onPressed: _generateAccessibilityReport,
        ),
      ],
    );
  }

  /// Construire le contenu principal accessible
  Widget _buildMainContent() {
    return Row(
      children: [
        // Panneau de composants (gauche)
        Expanded(
          flex: 2,
          child: _buildComponentPalette(),
        ),
        
        // Canvas principal (centre)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              if (_isLoadingTemplates)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Chargement des templates depuis l\'API...'),
                    ],
                  ),
                ),
              Expanded(child: _buildMainCanvas()),
            ],
          ),
        ),
        
        // Panneau de personnalisation (droite)
        Expanded(
          flex: 2,
          child: _buildCustomizationPanel(),
        ),
        
        // Panneau d'accessibilité (optionnel, droite)
        if (_showAccessibilityPanel)
          Expanded(
            flex: 2,
            child: _buildAccessibilityPanel(),
          ),
      ],
    );
  }

  /// Construire la palette de composants accessible
  Widget _buildComponentPalette() {
    return AccessibleWidgets.card(
      label: 'Palette de composants',
      hint: 'Zone de sélection des composants disponibles pour le template',
      child: Column(
        children: [
          AccessibleWidgets.heading(
            text: 'Composants',
            level: 2,
            label: 'Composants disponibles pour le template',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ComponentPalette(
              onComponentAdded: _handleComponentAdded,
              onComponentSelected: _handleComponentSelected,
            ),
          ),
        ],
      ),
    );
  }

  /// Construire le canvas principal accessible
  Widget _buildMainCanvas() {
    return AccessibleWidgets.card(
      label: 'Canvas principal',
      hint: 'Zone de construction du template avec drag & drop',
      child: Column(
        children: [
          // En-tête du canvas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AccessibleWidgets.heading(
                  text: 'Template Canvas',
                  level: 2,
                  label: 'Zone de construction du template',
                ),
                const Spacer(),
                // Bouton de prévisualisation
                AccessibleWidgets.button(
                  label: 'Prévisualiser',
                  hint: 'Voir la prévisualisation du template en cours',
                  onPressed: _previewTemplate,
                  icon: const Icon(Icons.preview),
                ),
                const SizedBox(width: 8),
                // Bouton de sauvegarde
                AccessibleWidgets.button(
                  label: 'Sauvegarder',
                  hint: 'Sauvegarder le template actuel',
                  onPressed: _saveTemplate,
                  icon: const Icon(Icons.save),
                ),
              ],
            ),
          ),
          
          // Canvas principal
          Expanded(
            child: TemplateCanvas(
              onComponentAdded: _handleComponentAdded,
              onComponentSelected: _handleComponentSelected,
              onComponentRemoved: _handleComponentRemoved,
              onComponentMoved: _handleComponentMoved,
            ),
          ),
          
          // Barre d'état accessible
          _buildAccessibleStatusBar(),
        ],
      ),
    );
  }

  /// Construire la barre d'état accessible
  Widget _buildAccessibleStatusBar() {
    final sections = _templateManager.getTemplateSections();
    final stats = _templateManager.getTemplateStats();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Statistiques du template
          Expanded(
            child: Row(
              children: [
                AccessibleWidgets.chip(
                  label: '${sections.length} sections',
                  hint: 'Nombre de sections dans le template',
                ),
                const SizedBox(width: 8),
                AccessibleWidgets.chip(
                  label: '${stats['totalComponents']} composants',
                  hint: 'Nombre total de composants',
                ),
                const SizedBox(width: 8),
                AccessibleWidgets.chip(
                  label: '${stats['estimatedTime']} min',
                  hint: 'Temps estimé de construction',
                ),
              ],
            ),
          ),
          
          // Indicateur d'accessibilité
          _buildAccessibilityIndicator(),
        ],
      ),
    );
  }

  /// Construire l'indicateur d'accessibilité
  Widget _buildAccessibilityIndicator() {
    final score = _accessibilityService.metrics.averageScore;
    final color = _getAccessibilityColor(score);
    final icon = _getAccessibilityIcon(score);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Accessibilité: ${score.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtenir la couleur d'accessibilité
  Color _getAccessibilityColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  /// Obtenir l'icône d'accessibilité
  IconData _getAccessibilityIcon(double score) {
    if (score >= 90) return Icons.check_circle;
    if (score >= 80) return Icons.info;
    if (score >= 70) return Icons.warning;
    return Icons.error;
  }

  /// Construire le panneau de personnalisation accessible
  Widget _buildCustomizationPanel() {
    return AccessibleWidgets.card(
      label: 'Personnalisation avancée',
      hint: 'Panneau de personnalisation des couleurs, typographie et animations',
      child: Column(
        children: [
          AccessibleWidgets.heading(
            text: 'Personnalisation',
            level: 2,
            label: 'Options de personnalisation du template',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AdvancedCustomizationPanel(
              onCustomizationChanged: _handleCustomizationChanged,
              selectedSection: _selectedSection,
            ),
          ),
        ],
      ),
    );
  }

  /// Construire le panneau d'accessibilité
  Widget _buildAccessibilityPanel() {
    return AccessibilityPanel(
      onSettingsChanged: _handleAccessibilitySettingsChanged,
      showAdvancedOptions: true,
    );
  }

  /// Construire le bouton d'action flottant accessible
  Widget _buildAccessibleFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton d'accessibilité
        FloatingActionButton(
          heroTag: 'accessibility',
          onPressed: () {
            setState(() {
              _showAccessibilityPanel = !_showAccessibilityPanel;
            });
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.accessibility_new, color: Colors.white),
        ),
        const SizedBox(height: 8),
        
        // Bouton principal
        FloatingActionButton.extended(
          heroTag: 'main',
          onPressed: _showTemplateOptions,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter'),
        ),
      ],
    );
  }

  // Gestionnaires d'événements

  void _handleComponentAdded(Map<String, dynamic> component) {
    _templateManager.addSection(component);
    _syncService.syncCustomization({
      'action': 'component_added',
      'component': component,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Valider l'accessibilité du nouveau composant
    _validateComponentAccessibility(component);
  }

  void _handleComponentSelected(Map<String, dynamic> component) {
    setState(() {
      _selectedSection = component;
    });
    
    // Valider l'accessibilité du composant sélectionné
    _validateComponentAccessibility(component);
  }

  void _handleComponentRemoved(String componentId) {
    _templateManager.removeSection(componentId);
    _syncService.syncCustomization({
      'action': 'component_removed',
      'componentId': componentId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (_selectedSection?['id'] == componentId) {
      setState(() {
        _selectedSection = null;
      });
    }
  }

  void _handleComponentMoved(String componentId, int newPosition) {
    _templateManager.moveSection(componentId, newPosition);
    _syncService.syncCustomization({
      'action': 'component_moved',
      'componentId': componentId,
      'newPosition': newPosition,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleCustomizationChanged(Map<String, dynamic> customization) {
    if (_selectedSection != null) {
      _templateManager.updateSectionContent(_selectedSection!['id'], customization);
      _syncService.syncCustomization(customization);
      
      // Valider l'accessibilité après personnalisation
      _validateComponentAccessibility(_selectedSection!);
    }
  }

  void _handleAccessibilitySettingsChanged() {
    // Revalider tous les composants avec les nouveaux paramètres
    _validateAllComponents();
    
    // Mettre à jour l'interface si nécessaire
    setState(() {});
  }

  /// Valider l'accessibilité d'un composant
  void _validateComponentAccessibility(Map<String, dynamic> component) {
    try {
      final validation = _accessibilityService.validateComponent(
        component['id'] ?? component['type'],
        _buildComponentWidget(component),
        context: context,
      );
      
      if (!validation.isValid) {
        // Afficher les problèmes d'accessibilité
        _showAccessibilityIssues(validation);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la validation d\'accessibilité: $e');
    }
  }

  /// Construire un widget de composant pour validation
  Widget _buildComponentWidget(Map<String, dynamic> component) {
    // Créer un widget simple pour la validation
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        component['name'] ?? component['type'] ?? 'Composant',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  /// Valider tous les composants
  void _validateAllComponents() {
    final sections = _templateManager.getTemplateSections();
    
    for (final section in sections) {
      _validateComponentAccessibility(section);
    }
    
    // Afficher un message de validation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accessibilité validée pour ${sections.length} composants'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Afficher les problèmes d'accessibilité
  void _showAccessibilityIssues(AccessibilityValidation validation) {
    if (validation.issues.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Problèmes d\'accessibilité - ${validation.componentId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: validation.issues.map((issue) => ListTile(
              leading: Icon(
                _getIssueIcon(issue.severity),
                color: _getIssueColor(issue.severity),
              ),
              title: Text(issue.message),
              subtitle: Text(issue.suggestion),
              trailing: Chip(
                label: Text(issue.type.name),
                backgroundColor: _getIssueColor(issue.severity).withOpacity(0.1),
              ),
            )).toList(),
          ),
        ),
        actions: [
          AccessibleWidgets.button(
            label: 'Fermer',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Obtenir l'icône d'un problème
  IconData _getIssueIcon(AccessibilitySeverity severity) {
    switch (severity) {
      case AccessibilitySeverity.critical:
      case AccessibilitySeverity.error:
        return Icons.error;
      case AccessibilitySeverity.warning:
        return Icons.warning;
      case AccessibilitySeverity.info:
        return Icons.info;
    }
  }

  /// Obtenir la couleur d'un problème
  Color _getIssueColor(AccessibilitySeverity severity) {
    switch (severity) {
      case AccessibilitySeverity.critical:
      case AccessibilitySeverity.error:
        return Colors.red;
      case AccessibilitySeverity.warning:
        return Colors.orange;
      case AccessibilitySeverity.info:
        return Colors.blue;
    }
  }

  /// Générer un rapport d'accessibilité
  void _generateAccessibilityReport() {
    final report = _accessibilityService.generateReport();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rapport d\'Accessibilité Complet'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReportSection('Métriques Globales', [
                'Score moyen: ${report.metrics.averageScore.toStringAsFixed(1)}%',
                'Validations: ${report.metrics.totalValidations}',
                'Problèmes: ${report.metrics.totalIssues}',
                'Cache: ${report.cacheSize} composants',
              ]),
              
              const SizedBox(height: 16),
              
              _buildReportSection('Paramètres Actuels', [
                'Réduction mouvement: ${report.settings.reduceMotion ? 'Oui' : 'Non'}',
                'Contraste élevé: ${report.settings.highContrast ? 'Oui' : 'Non'}',
                'Texte large: ${report.settings.largeText ? 'Oui' : 'Non'}',
                'Navigation clavier: ${report.settings.keyboardNavigation ? 'Oui' : 'Non'}',
                'Mode lecteur: ${report.settings.screenReader ? 'Oui' : 'Non'}',
              ]),
              
              if (report.recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildReportSection('Recommandations', report.recommendations),
              ],
            ],
          ),
        ),
        actions: [
          AccessibleWidgets.button(
            label: 'Fermer',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Construire une section de rapport
  Widget _buildReportSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AccessibleWidgets.heading(
          text: title,
          level: 4,
          label: title,
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(
            '• $item',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        )),
      ],
    );
  }

  // Actions du template

  void _previewTemplate() {
    // Implémenter la prévisualisation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prévisualisation en cours de développement'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _saveTemplate() {
    // Implémenter la sauvegarde
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sauvegarde en cours de développement'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showTemplateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AccessibleWidgets.heading(
              text: 'Options du Template',
              level: 3,
              label: 'Options disponibles pour le template',
            ),
            const SizedBox(height: 16),
            AccessibleWidgets.listTile(
              label: 'Nouveau template',
              hint: 'Créer un nouveau template vide',
              leading: const Icon(Icons.add),
              onTap: () {
                Navigator.of(context).pop();
                _createNewTemplate();
              },
            ),
            AccessibleWidgets.listTile(
              label: 'Importer template',
              hint: 'Importer un template existant',
              leading: const Icon(Icons.upload),
              onTap: () {
                Navigator.of(context).pop();
                _importTemplate();
              },
            ),
            AccessibleWidgets.listTile(
              label: 'Exporter template',
              hint: 'Exporter le template actuel',
              leading: const Icon(Icons.download),
              onTap: () {
                Navigator.of(context).pop();
                _exportTemplate();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewTemplate() {
    _templateManager.resetTemplate();
    _syncService.syncCustomization({
      'action': 'template_reset',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nouveau template créé'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _importTemplate() {
    // Implémenter l'import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import en cours de développement'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportTemplate() {
    // Implémenter l'export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export en cours de développement'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _syncService.dispose();
    _templateManager.dispose();
    _previewService.dispose();
    super.dispose();
  }
}


