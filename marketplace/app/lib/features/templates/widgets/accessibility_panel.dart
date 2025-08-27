import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import 'accessible_widgets.dart';

/// 🎯 Panneau de Configuration d'Accessibilité
/// 
/// Ce widget permet aux utilisateurs de configurer leurs préférences
/// d'accessibilité en temps réel avec un aperçu immédiat des changements.
class AccessibilityPanel extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  final bool showAdvancedOptions;

  const AccessibilityPanel({
    super.key,
    this.onSettingsChanged,
    this.showAdvancedOptions = true,
  });

  @override
  State<AccessibilityPanel> createState() => _AccessibilityPanelState();
}

class _AccessibilityPanelState extends State<AccessibilityPanel> {
  late AccessibilityService _accessibilityService;
  late AccessibilitySettings _currentSettings;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _accessibilityService = AccessibilityService();
    _currentSettings = _accessibilityService.currentSettings;
    
    // Écouter les changements de paramètres
    _accessibilityService.settingsStream.listen((settings) {
      if (mounted) {
        setState(() {
          _currentSettings = settings;
        });
        widget.onSettingsChanged?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête du panneau
          _buildHeader(),
          
          // Contenu principal
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildContent(),
          ],
        ],
      ),
    );
  }

  /// Construire l'en-tête du panneau
  Widget _buildHeader() {
    return ListTile(
      leading: const Icon(Icons.accessibility_new, color: Colors.blue),
      title: AccessibleWidgets.heading(
        text: 'Accessibilité',
        level: 3,
        label: 'Panneau de configuration d\'accessibilité',
      ),
      subtitle: Text(
        'Personnalisez votre expérience selon vos besoins',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de score d'accessibilité
          _buildAccessibilityScore(),
          const SizedBox(width: 8),
          // Bouton d'expansion
          AccessibleWidgets.iconButton(
            label: _isExpanded ? 'Réduire' : 'Développer',
            hint: _isExpanded ? 'Réduire le panneau' : 'Développer le panneau',
            icon: _isExpanded ? Icons.expand_less : Icons.expand_more,
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ],
      ),
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
    );
  }

  /// Construire l'indicateur de score d'accessibilité
  Widget _buildAccessibilityScore() {
    final score = _accessibilityService.metrics.averageScore;
    final color = _getScoreColor(score);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getScoreIcon(score),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtenir la couleur du score
  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  /// Obtenir l'icône du score
  IconData _getScoreIcon(double score) {
    if (score >= 90) return Icons.check_circle;
    if (score >= 80) return Icons.info;
    if (score >= 70) return Icons.warning;
    return Icons.error;
  }

  /// Construire le contenu principal du panneau
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section des paramètres de base
          _buildBasicSettings(),
          
          if (widget.showAdvancedOptions) ...[
            const SizedBox(height: 24),
            _buildAdvancedSettings(),
          ],
          
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  /// Construire les paramètres de base
  Widget _buildBasicSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AccessibleWidgets.heading(
          text: 'Paramètres de base',
          level: 4,
          label: 'Configuration d\'accessibilité de base',
        ),
        const SizedBox(height: 16),
        
        // Réduction de mouvement
        AccessibleWidgets.switchTile(
          label: 'Réduire les animations',
          hint: 'Désactive les animations complexes pour réduire la sensibilité au mouvement',
          value: _currentSettings.reduceMotion,
          onChanged: (value) {
            _updateSetting('reduceMotion', value);
          },
        ),
        
        // Contraste élevé
        AccessibleWidgets.switchTile(
          label: 'Contraste élevé',
          hint: 'Augmente le contraste des couleurs pour une meilleure lisibilité',
          value: _currentSettings.highContrast,
          onChanged: (value) {
            _updateSetting('highContrast', value);
          },
        ),
        
        // Texte large
        AccessibleWidgets.switchTile(
          label: 'Texte large',
          hint: 'Augmente la taille de police pour une meilleure lisibilité',
          value: _currentSettings.largeText,
          onChanged: (value) {
            _updateSetting('largeText', value);
          },
        ),
        
        // Navigation au clavier
        AccessibleWidgets.switchTile(
          label: 'Navigation au clavier',
          hint: 'Active la navigation complète au clavier',
          value: _currentSettings.keyboardNavigation,
          onChanged: (value) {
            _updateSetting('keyboardNavigation', value);
          },
        ),
      ],
    );
  }

  /// Construire les paramètres avancés
  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AccessibleWidgets.heading(
          text: 'Paramètres avancés',
          level: 4,
          label: 'Configuration d\'accessibilité avancée',
        ),
        const SizedBox(height: 16),
        
        // Facteur d'échelle du texte
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taille du texte: ${(_currentSettings.textScaleFactor * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            AccessibleWidgets.slider(
              label: 'Facteur d\'échelle du texte',
              hint: 'Ajuste la taille du texte de 50% à 200%',
              value: _currentSettings.textScaleFactor,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (value) {
                _updateSetting('textScaleFactor', value);
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Texte en gras
        AccessibleWidgets.switchTile(
          label: 'Texte en gras',
          hint: 'Rend tout le texte en gras pour une meilleure visibilité',
          value: _currentSettings.boldText,
          onChanged: (value) {
            _updateSetting('boldText', value);
          },
        ),
        
        // Inversion des couleurs
        AccessibleWidgets.switchTile(
          label: 'Inverser les couleurs',
          hint: 'Inverse les couleurs pour un contraste extrême',
          value: _currentSettings.invertColors,
          onChanged: (value) {
            _updateSetting('invertColors', value);
          },
        ),
        
        // Support des lecteurs d'écran
        AccessibleWidgets.switchTile(
          label: 'Mode lecteur d\'écran',
          hint: 'Optimise l\'interface pour les lecteurs d\'écran',
          value: _currentSettings.screenReader,
          onChanged: (value) {
            _updateSetting('screenReader', value);
          },
        ),
      ],
    );
  }

  /// Construire les actions
  Widget _buildActions() {
    return Row(
      children: [
        // Bouton de réinitialisation
        Expanded(
          child: AccessibleWidgets.textButton(
            label: 'Réinitialiser',
            hint: 'Remet tous les paramètres à leurs valeurs par défaut',
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Bouton de rapport
        Expanded(
          child: AccessibleWidgets.button(
            label: 'Générer rapport',
            hint: 'Crée un rapport détaillé de l\'accessibilité',
            onPressed: _generateReport,
            icon: const Icon(Icons.assessment),
          ),
        ),
      ],
    );
  }

  /// Mettre à jour un paramètre spécifique
  void _updateSetting(String settingName, dynamic value) {
    final newSettings = _currentSettings.copyWith(
      reduceMotion: settingName == 'reduceMotion' ? value : _currentSettings.reduceMotion,
      highContrast: settingName == 'highContrast' ? value : _currentSettings.highContrast,
      largeText: settingName == 'largeText' ? value : _currentSettings.largeText,
      keyboardNavigation: settingName == 'keyboardNavigation' ? value : _currentSettings.keyboardNavigation,
      textScaleFactor: settingName == 'textScaleFactor' ? value : _currentSettings.textScaleFactor,
      boldText: settingName == 'boldText' ? value : _currentSettings.boldText,
      invertColors: settingName == 'invertColors' ? value : _currentSettings.invertColors,
      screenReader: settingName == 'screenReader' ? value : _currentSettings.screenReader,
    );
    
    _accessibilityService.updateSettings(newSettings);
  }

  /// Réinitialiser aux valeurs par défaut
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser l\'accessibilité'),
        content: const Text(
          'Êtes-vous sûr de vouloir remettre tous les paramètres d\'accessibilité à leurs valeurs par défaut ?'
        ),
        actions: [
          AccessibleWidgets.textButton(
            label: 'Annuler',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AccessibleWidgets.button(
            label: 'Réinitialiser',
            onPressed: () {
              _accessibilityService.updateSettings(AccessibilitySettings.defaults());
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  /// Générer un rapport d'accessibilité
  void _generateReport() {
    final report = _accessibilityService.generateReport();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rapport d\'accessibilité'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReportSection('Métriques', [
                'Validations totales: ${report.metrics.totalValidations}',
                'Validations réussies: ${report.metrics.successfulValidations}',
                'Validations échouées: ${report.metrics.failedValidations}',
                'Problèmes totaux: ${report.metrics.totalIssues}',
                'Score moyen: ${report.metrics.averageScore.toStringAsFixed(1)}%',
                'Mises à jour: ${report.metrics.settingsUpdates}',
              ]),
              
              const SizedBox(height: 16),
              
              _buildReportSection('Paramètres actuels', [
                'Réduction mouvement: ${report.settings.reduceMotion ? 'Oui' : 'Non'}',
                'Contraste élevé: ${report.settings.highContrast ? 'Oui' : 'Non'}',
                'Texte large: ${report.settings.largeText ? 'Oui' : 'Non'}',
                'Navigation clavier: ${report.settings.keyboardNavigation ? 'Oui' : 'Non'}',
                'Facteur texte: ${(report.settings.textScaleFactor * 100).toStringAsFixed(0)}%',
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

  /// Construire une section du rapport
  Widget _buildReportSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
}
