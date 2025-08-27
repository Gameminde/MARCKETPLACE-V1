import 'package:flutter/material.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import '../services/template_manager_service.dart';
import '../services/template_sync_service.dart';

/// Canvas principal du template builder avec drag & drop
/// et synchronisation temps réel avec la preview
class TemplateCanvas extends StatefulWidget {
  final Function(Map<String, dynamic> component) onComponentAdded;
  final Function(String uniqueId, int newPosition) onSectionMoved;
  final Function(String uniqueId) onSectionRemoved;
  final Function(String uniqueId) onSectionDuplicated;
  final Function(String uniqueId) onSectionSelected;

  const TemplateCanvas({
    super.key,
    required this.onComponentAdded,
    required this.onSectionMoved,
    required this.onSectionRemoved,
    required this.onSectionDuplicated,
    required this.onSectionSelected,
  });

  @override
  State<TemplateCanvas> createState() => _TemplateCanvasState();
}

class _TemplateCanvasState extends State<TemplateCanvas>
    with TickerProviderStateMixin {
  late final TemplateManagerService _templateManager;
  late final TemplateSyncService _syncService;
  
  // État local
  String? _selectedSectionId;
  bool _isDragging = false;
  int? _dragTargetIndex;
  
  // Animation controller pour les transitions
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _templateManager = TemplateManagerService();
    _syncService = TemplateSyncService();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _templateManager.getTemplateSections();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header du canvas
          _buildCanvasHeader(),
          
          // Zone de drop principale
          Expanded(
            child: _buildDropZone(sections),
          ),
          
          // Footer avec statistiques
          _buildCanvasFooter(),
        ],
      ),
    );
  }

  /// Header du canvas avec titre et actions
  Widget _buildCanvasHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.design_services,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canvas Template',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Déposez et organisez vos sections',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Actions rapides
          Row(
            children: [
              IconButton(
                onPressed: _templateManager.canUndo() ? _undo : null,
                icon: const Icon(Icons.undo),
                tooltip: 'Annuler',
              ),
              IconButton(
                onPressed: _templateManager.canRedo() ? _redo : null,
                icon: const Icon(Icons.redo),
                tooltip: 'Rétablir',
              ),
              IconButton(
                onPressed: _showTemplateStats,
                icon: const Icon(Icons.analytics),
                tooltip: 'Statistiques',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Zone de drop principale avec sections réorganisables
  Widget _buildDropZone(List<Map<String, dynamic>> sections) {
    if (sections.isEmpty) {
      return _buildEmptyState();
    }
    
    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) => data != null,
      onAccept: (component) {
        widget.onComponentAdded(component);
        _showSectionAddedSnackbar(component['name'] as String);
      },
      builder: (context, candidateData, rejectedData) {
        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return _buildSectionItem(section, index);
          },
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final section = sections[oldIndex];
            widget.onSectionMoved(section['uniqueId'] as String, newIndex);
          },
        );
      },
    );
  }

  /// État vide du canvas
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Commencez votre template',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Glissez des composants depuis la palette\npour créer votre première section',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showQuickStartGuide,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Guide de démarrage'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Item d'une section avec actions
  Widget _buildSectionItem(Map<String, dynamic> section, int index) {
    final isSelected = _selectedSectionId == section['uniqueId'];
    final isRequired = section['constraints']?['required'] == true;
    
    return Container(
      key: ValueKey(section['uniqueId']),
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: isSelected ? 8 : 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _selectSection(section['uniqueId'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Header de la section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icône de la section
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          section['icon'] as IconData,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Informations de la section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  section['name'] as String,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : null,
                                  ),
                                ),
                                if (isRequired) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Requis',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'Ordre: ${index + 1}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Actions de la section
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _duplicateSection(section['uniqueId'] as String),
                            icon: const Icon(Icons.copy),
                            tooltip: 'Dupliquer',
                            iconSize: 20,
                          ),
                          IconButton(
                            onPressed: isRequired ? null : () => _removeSection(section['uniqueId'] as String),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Supprimer',
                            iconSize: 20,
                          ),
                          Icon(
                            Icons.drag_indicator,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Contenu de la section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _buildSectionContent(section),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Contenu d'une section selon son type
  Widget _buildSectionContent(Map<String, dynamic> section) {
    final id = section['id'] as String;
    final content = section['content'] as Map<String, dynamic>? ?? {};
    
    switch (id) {
      case 'header':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content['title'] ?? 'Titre de la boutique',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (content['subtitle'] != null) ...[
              const SizedBox(height: 8),
              Text(
                content['subtitle'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
        
      case 'hero':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content['title'] ?? 'Bienvenue sur notre boutique',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (content['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                content['description'] as String,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (content['ctaText'] != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: Text(content['ctaText'] as String),
              ),
            ],
          ],
        );
        
      case 'products_grid':
        final columns = content['columns'] ?? 4;
        final rows = content['rows'] ?? 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content['title'] ?? 'Nos Produits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (content['subtitle'] != null) ...[
              const SizedBox(height: 8),
              Text(
                content['subtitle'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Grille: ${columns} × ${rows}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${columns * rows} produits affichés',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        
      case 'testimonials':
        final testimonials = content['testimonials'] as List<dynamic>? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content['title'] ?? 'Ce que disent nos clients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (testimonials.isNotEmpty)
              ...testimonials.take(2).map((testimonial) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${testimonial['text'] ?? 'Témoignage'}"',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '— ${testimonial['author'] ?? 'Client'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            testimonial['rating'] ?? 5,
                            (index) => Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          ],
        );
        
      case 'newsletter':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content['title'] ?? 'Restez informé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (content['subtitle'] != null) ...[
              const SizedBox(height: 8),
              Text(
                content['subtitle'] as String,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: content['placeholder'] ?? 'Votre email',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text(content['buttonText'] ?? 'S\'inscrire'),
                  ),
                ],
              ),
            ),
          ],
        );
        
      case 'footer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content['companyName'] ?? 'Nom de l\'entreprise',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (content['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                content['description'] as String,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Liens: ${(content['links'] as List<dynamic>? ?? []).length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Réseaux sociaux: ${(content['socialMedia'] as List<dynamic>? ?? []).length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );
        
      default:
        return Text(
          'Section de type: $id',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  /// Footer du canvas avec statistiques
  Widget _buildCanvasFooter() {
    final stats = _templateManager.getTemplateStats();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats['totalSections']} sections',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Dernière modification: ${_formatLastModified(stats['lastModification'])}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (stats['canUndo'])
                TextButton.icon(
                  onPressed: _undo,
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Annuler'),
                ),
              if (stats['canRedo'])
                TextButton.icon(
                  onPressed: _redo,
                  icon: const Icon(Icons.redo, size: 16),
                  label: const Text('Rétablir'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sélectionner une section
  void _selectSection(String sectionId) {
    setState(() {
      _selectedSectionId = sectionId;
    });
    widget.onSectionSelected(sectionId);
  }

  /// Dupliquer une section
  void _duplicateSection(String uniqueId) {
    _templateManager.duplicateSection(uniqueId);
    setState(() {});
    _showSectionDuplicatedSnackbar();
  }

  /// Supprimer une section
  void _removeSection(String uniqueId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la section'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette section ? '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _templateManager.removeSection(uniqueId);
              setState(() {});
              _showSectionRemovedSnackbar();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// Annuler la dernière action
  void _undo() {
    if (_templateManager.undo()) {
      setState(() {});
      _showUndoSnackbar();
    }
  }

  /// Rétablir l'action annulée
  void _redo() {
    if (_templateManager.redo()) {
      setState(() {});
      _showRedoSnackbar();
    }
  }

  /// Afficher les statistiques du template
  void _showTemplateStats() {
    final stats = _templateManager.getTemplateStats();
    final validation = stats['validation'] as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques du Template'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem('Sections totales', '${stats['totalSections']}'),
              _buildStatItem('Composants', '${stats['componentCount']}'),
              _buildStatItem('Historique', '${stats['historySize']} états'),
              _buildStatItem('Dernière modification', _formatLastModified(stats['lastModification'])),
              const Divider(),
              Text(
                'Validation:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (validation['errors'].isNotEmpty) ...[
                Text(
                  'Erreurs (${validation['errors'].length}):',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                ),
                ...(validation['errors'] as List<dynamic>).map((error) => Text(
                  '• $error',
                  style: TextStyle(color: Colors.red[600]),
                )),
                const SizedBox(height: 8),
              ],
              if (validation['warnings'].isNotEmpty) ...[
                Text(
                  'Avertissements (${validation['warnings'].length}):',
                  style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
                ),
                ...(validation['warnings'] as List<dynamic>).map((warning) => Text(
                  '• $warning',
                  style: TextStyle(color: Colors.orange[600]),
                )),
              ],
            ],
          ),
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

  /// Item de statistique
  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Guide de démarrage rapide
  void _showQuickStartGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guide de démarrage rapide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Étapes pour créer votre premier template:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Commencez par ajouter une section "En-tête" (requis)'),
              Text('2. Ajoutez une section "Héro" pour l\'accueil'),
              Text('3. Intégrez une grille de produits'),
              Text('4. Terminez par un pied de page (requis)'),
              SizedBox(height: 16),
              Text(
                'Conseils:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Utilisez le panel de droite pour personnaliser'),
              Text('• Réorganisez les sections par drag & drop'),
              Text('• Validez votre template avant publication'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// Formatage de la dernière modification
  String _formatLastModified(String? lastModified) {
    if (lastModified == null) return 'Jamais';
    
    try {
      final date = DateTime.parse(lastModified);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours} h';
      } else {
        return 'Il y a ${difference.inDays} jours';
      }
    } catch (e) {
      return 'Inconnu';
    }
  }

  // Snackbars pour feedback utilisateur
  void _showSectionAddedSnackbar(String sectionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Section "$sectionName" ajoutée !'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Personnaliser',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSectionDuplicatedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Section dupliquée !'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSectionRemovedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Section supprimée !'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => _undo(),
        ),
      ),
    );
  }

  void _showUndoSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action annulée'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Rétablir',
          onPressed: () => _redo(),
        ),
      ),
    );
  }

  void _showRedoSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action rétablie'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
