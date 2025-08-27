import 'package:flutter/material.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import '../../../templates/services/template_manager_service.dart';

/// Palette de composants drag & drop pour le template builder
/// Permet d'ajouter des sections au template via drag & drop
class ComponentPalette extends StatefulWidget {
  final Function(Map<String, dynamic> component) onComponentAdded;
  final Function(String uniqueId, int newPosition) onSectionMoved;
  final Function(String uniqueId) onSectionRemoved;
  final Function(String uniqueId) onSectionDuplicated;

  const ComponentPalette({
    super.key,
    required this.onComponentAdded,
    required this.onSectionMoved,
    required this.onSectionRemoved,
    required this.onSectionDuplicated,
  });

  @override
  State<ComponentPalette> createState() => _ComponentPaletteState();
}

class _ComponentPaletteState extends State<ComponentPalette>
    with TickerProviderStateMixin {
  late final TemplateManagerService _templateManager;
  late final TabController _tabController;
  
  // État local
  String _selectedCategory = 'structure';
  bool _isDragging = false;
  Map<String, dynamic>? _draggedComponent;

  @override
  void initState() {
    super.initState();
    _templateManager = TemplateManagerService();
    _tabController = TabController(
      length: _templateManager.getComponentsByCategory().length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categorizedComponents = _templateManager.getComponentsByCategory();
    final categories = categorizedComponents.keys.toList();
    
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header de la palette
          _buildPaletteHeader(),
          
          // Tabs des catégories
          _buildCategoryTabs(categories),
          
          // Contenu des composants
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories.map((category) {
                return _buildCategoryContent(
                  category,
                  categorizedComponents[category]!,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Header de la palette avec titre et actions
  Widget _buildPaletteHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.palette_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Composants',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Glissez pour ajouter',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showComponentInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Informations sur les composants',
          ),
        ],
      ),
    );
  }

  /// Tabs des catégories de composants
  Widget _buildCategoryTabs(List<String> categories) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: categories.map((category) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getCategoryIcon(category), size: 16),
                const SizedBox(width: 8),
                Text(_getCategoryLabel(category)),
              ],
            ),
          );
        }).toList(),
        onTap: (index) {
          setState(() {
            _selectedCategory = categories[index];
          });
        },
      ),
    );
  }

  /// Contenu d'une catégorie de composants
  Widget _buildCategoryContent(String category, List<Map<String, dynamic>> components) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: components.length,
        itemBuilder: (context, index) {
          final component = components[index];
          return _buildComponentItem(component);
        },
      ),
    );
  }

  /// Item d'un composant avec drag & drop
  Widget _buildComponentItem(Map<String, dynamic> component) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Draggable<Map<String, dynamic>>(
        data: component,
        feedback: _buildDragFeedback(component),
        childWhenDragging: _buildDragPlaceholder(component),
        onDragStarted: () {
          setState(() {
            _isDragging = true;
            _draggedComponent = component;
          });
        },
        onDragEnd: (details) {
          setState(() {
            _isDragging = false;
            _draggedComponent = null;
          });
        },
        child: _buildComponentCard(component),
      ),
    );
  }

  /// Carte d'un composant
  Widget _buildComponentCard(Map<String, dynamic> component) {
    final isRequired = component['constraints']?['required'] == true;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showComponentDetails(component),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header du composant
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      component['icon'] as IconData,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          component['name'] as String,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isRequired)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
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
                    ),
                  ),
                  Icon(
                    Icons.drag_indicator,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description du composant
              Text(
                _getComponentDescription(component),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Propriétés personnalisables
              if (component['customizable'] != null)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (component['customizable'] as List<dynamic>)
                      .take(3)
                      .map((prop) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          prop.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontSize: 10,
                          ),
                        ),
                      ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Feedback visuel pendant le drag
  Widget _buildDragFeedback(Map<String, dynamic> component) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              component['icon'] as IconData,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                component['name'] as String,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.add_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder pendant le drag
  Widget _buildDragPlaceholder(Map<String, dynamic> component) {
    return Opacity(
      opacity: 0.3,
      child: _buildComponentCard(component),
    );
  }

  /// Icône pour une catégorie
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'structure':
        return Icons.architecture;
      case 'content':
        return Icons.article;
      case 'social':
        return Icons.people;
      case 'marketing':
        return Icons.campaign;
      default:
        return Icons.category;
    }
  }

  /// Label pour une catégorie
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'structure':
        return 'Structure';
      case 'content':
        return 'Contenu';
      case 'social':
        return 'Social';
      case 'marketing':
        return 'Marketing';
      default:
        return category;
    }
  }

  /// Description d'un composant
  String _getComponentDescription(Map<String, dynamic> component) {
    switch (component['id']) {
      case 'header':
        return 'En-tête principal de la boutique avec titre et navigation';
      case 'hero':
        return 'Section d\'accueil attractive avec appel à l\'action';
      case 'products_grid':
        return 'Grille de produits avec filtres et pagination';
      case 'testimonials':
        return 'Témoignages clients pour la confiance';
      case 'newsletter':
        return 'Inscription newsletter pour fidélisation';
      case 'footer':
        return 'Pied de page avec liens et informations';
      default:
        return 'Composant personnalisable pour votre boutique';
    }
  }

  /// Afficher les détails d'un composant
  void _showComponentDetails(Map<String, dynamic> component) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              component['icon'] as IconData,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(component['name'] as String),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getComponentDescription(component),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              if (component['customizable'] != null) ...[
                Text(
                  'Propriétés personnalisables:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (component['customizable'] as List<dynamic>)
                      .map((prop) => Chip(
                        label: Text(prop.toString()),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              if (component['constraints'] != null) ...[
                Text(
                  'Contraintes:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildConstraintsList(component['constraints']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onComponentAdded(component);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  /// Liste des contraintes d'un composant
  Widget _buildConstraintsList(Map<String, dynamic> constraints) {
    final items = <Widget>[];
    
    if (constraints['required'] == true) {
      items.add(const ListTile(
        leading: Icon(Icons.check_circle, color: Colors.green),
        title: Text('Section requise'),
        dense: true,
      ));
    }
    
    if (constraints.containsKey('minHeight')) {
      items.add(ListTile(
        leading: const Icon(Icons.height, color: Colors.blue),
        title: Text('Hauteur minimale: ${constraints['minHeight']}px'),
        dense: true,
      ));
    }
    
    if (constraints.containsKey('maxHeight')) {
      items.add(ListTile(
        leading: const Icon(Icons.height, color: Colors.blue),
        title: Text('Hauteur maximale: ${constraints['maxHeight']}px'),
        dense: true,
      ));
    }
    
    if (constraints.containsKey('minColumns')) {
      items.add(ListTile(
        leading: const Icon(Icons.grid_on, color: Colors.orange),
        title: Text('Colonnes min: ${constraints['minColumns']}'),
        dense: true,
      ));
    }
    
    if (constraints.containsKey('maxColumns')) {
      items.add(ListTile(
        leading: const Icon(Icons.grid_on, color: Colors.orange),
        title: Text('Colonnes max: ${constraints['maxColumns']}'),
        dense: true,
      ));
    }
    
    return Column(children: items);
  }

  /// Afficher les informations sur les composants
  void _showComponentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guide des composants'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Comment utiliser les composants:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. Glissez un composant depuis cette palette vers le canvas'),
              Text('2. Déposez-le à l\'endroit souhaité dans votre template'),
              Text('3. Personnalisez le contenu et le style via le panel de droite'),
              Text('4. Réorganisez les sections par drag & drop'),
              SizedBox(height: 16),
              Text(
                'Types de composants:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Structure: En-tête, pied de page (requis)'),
              Text('• Contenu: Sections principales, grilles de produits'),
              Text('• Social: Témoignages, réseaux sociaux'),
              Text('• Marketing: Newsletter, appels à l\'action'),
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
}
