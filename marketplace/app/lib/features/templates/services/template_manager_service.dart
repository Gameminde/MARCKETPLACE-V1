import 'dart:convert';
import 'package:flutter/material.dart';

/// Service de gestion des templates avec composants drag & drop
/// et gestion intelligente des sections
class TemplateManagerService {
  static final TemplateManagerService _instance = TemplateManagerService._internal();
  factory TemplateManagerService() => _instance;
  TemplateManagerService._internal();

  // Composants disponibles pour drag & drop
  final List<Map<String, dynamic>> _availableComponents = [
    {
      'id': 'header',
      'type': 'section',
      'name': 'En-tête',
      'icon': Icons.view_headline,
      'category': 'structure',
      'defaultContent': {
        'title': 'Titre de la boutique',
        'subtitle': 'Sous-titre accrocheur',
        'background': 'gradient',
        'height': 200.0,
      },
      'customizable': ['title', 'subtitle', 'background', 'height', 'textColor'],
      'constraints': {
        'minHeight': 100.0,
        'maxHeight': 400.0,
        'required': true,
      },
    },
    {
      'id': 'hero',
      'type': 'section',
      'name': 'Section Héro',
      'icon': Icons.auto_awesome,
      'category': 'content',
      'defaultContent': {
        'title': 'Bienvenue sur notre boutique',
        'description': 'Découvrez nos produits exceptionnels',
        'ctaText': 'Commencer à acheter',
        'ctaLink': '/products',
        'image': 'hero-image.jpg',
      },
      'customizable': ['title', 'description', 'ctaText', 'ctaLink', 'image', 'layout'],
      'constraints': {
        'minHeight': 300.0,
        'maxHeight': 600.0,
        'required': false,
      },
    },
    {
      'id': 'products_grid',
      'type': 'section',
      'name': 'Grille Produits',
      'icon': Icons.grid_view,
      'category': 'content',
      'defaultContent': {
        'title': 'Nos Produits',
        'subtitle': 'Découvrez notre sélection',
        'columns': 4,
        'rows': 2,
        'showFilters': true,
        'showPagination': true,
      },
      'customizable': ['title', 'subtitle', 'columns', 'rows', 'showFilters', 'showPagination', 'layout'],
      'constraints': {
        'minColumns': 1,
        'maxColumns': 6,
        'minRows': 1,
        'maxRows': 10,
        'required': true,
      },
    },
    {
      'id': 'testimonials',
      'type': 'section',
      'name': 'Témoignages',
      'icon': Icons.rate_review,
      'category': 'social',
      'defaultContent': {
        'title': 'Ce que disent nos clients',
        'testimonials': [
          {'text': 'Excellent service !', 'author': 'Client 1', 'rating': 5},
          {'text': 'Produits de qualité', 'author': 'Client 2', 'rating': 5},
        ],
        'layout': 'carousel',
        'autoPlay': true,
      },
      'customizable': ['title', 'testimonials', 'layout', 'autoPlay', 'style'],
      'constraints': {
        'minTestimonials': 1,
        'maxTestimonials': 10,
        'required': false,
      },
    },
    {
      'id': 'newsletter',
      'type': 'section',
      'name': 'Newsletter',
      'icon': Icons.email,
      'category': 'marketing',
      'defaultContent': {
        'title': 'Restez informé',
        'subtitle': 'Recevez nos dernières offres',
        'placeholder': 'Votre email',
        'buttonText': 'S\'inscrire',
        'privacyText': 'En vous inscrivant, vous acceptez notre politique de confidentialité',
      },
      'customizable': ['title', 'subtitle', 'placeholder', 'buttonText', 'privacyText', 'style'],
      'constraints': {
        'required': false,
      },
    },
    {
      'id': 'footer',
      'type': 'section',
      'name': 'Pied de page',
      'icon': Icons.footer,
      'category': 'structure',
      'defaultContent': {
        'companyName': 'Nom de l\'entreprise',
        'description': 'Description courte de l\'entreprise',
        'links': [
          {'text': 'À propos', 'url': '/about'},
          {'text': 'Contact', 'url': '/contact'},
          {'text': 'Mentions légales', 'url': '/legal'},
        ],
        'socialMedia': [
          {'platform': 'facebook', 'url': '#'},
          {'platform': 'instagram', 'url': '#'},
          {'platform': 'twitter', 'url': '#'},
        ],
      },
      'customizable': ['companyName', 'description', 'links', 'socialMedia', 'style'],
      'constraints': {
        'required': true,
      },
    },
  ];

  // Sections actuellement dans le template
  final List<Map<String, dynamic>> _templateSections = [];
  
  // Historique des modifications
  final List<List<Map<String, dynamic>>> _history = [];
  int _currentHistoryIndex = -1;
  
  // Métriques de performance
  int _componentCount = 0;
  DateTime? _lastModificationTime;

  /// Obtenir tous les composants disponibles
  List<Map<String, dynamic>> getAvailableComponents() {
    return List.from(_availableComponents);
  }

  /// Obtenir les composants par catégorie
  Map<String, List<Map<String, dynamic>>> getComponentsByCategory() {
    final categorized = <String, List<Map<String, dynamic>>>{};
    
    for (final component in _availableComponents) {
      final category = component['category'] as String;
      categorized.putIfAbsent(category, () => []).add(component);
    }
    
    return categorized;
  }

  /// Ajouter une section au template
  void addSection(Map<String, dynamic> component, {int? position}) {
    try {
      // Cloner le composant pour éviter les références partagées
      final section = Map<String, dynamic>.from(component);
      
      // Générer un ID unique
      section['uniqueId'] = '${component['id']}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Ajouter des métadonnées
      section['addedAt'] = DateTime.now().toIso8601String();
      section['order'] = position ?? _templateSections.length;
      
      // Ajouter à l'historique
      _addToHistory();
      
      // Insérer à la position spécifiée ou à la fin
      if (position != null && position <= _templateSections.length) {
        _templateSections.insert(position, section);
        // Mettre à jour l'ordre des sections suivantes
        for (int i = position + 1; i < _templateSections.length; i++) {
          _templateSections[i]['order'] = i;
        }
      } else {
        section['order'] = _templateSections.length;
        _templateSections.add(section);
      }
      
      _componentCount++;
      _lastModificationTime = DateTime.now();
      
    } catch (e) {
      print('Erreur ajout section: $e');
      rethrow;
    }
  }

  /// Supprimer une section du template
  void removeSection(String uniqueId) {
    try {
      final index = _templateSections.indexWhere((section) => section['uniqueId'] == uniqueId);
      
      if (index != -1) {
        // Ajouter à l'historique
        _addToHistory();
        
        // Supprimer la section
        _templateSections.removeAt(index);
        
        // Mettre à jour l'ordre des sections restantes
        for (int i = index; i < _templateSections.length; i++) {
          _templateSections[i]['order'] = i;
        }
        
        _componentCount--;
        _lastModificationTime = DateTime.now();
      }
    } catch (e) {
      print('Erreur suppression section: $e');
      rethrow;
    }
  }

  /// Déplacer une section (drag & drop)
  void moveSection(String uniqueId, int newPosition) {
    try {
      final currentIndex = _templateSections.indexWhere((section) => section['uniqueId'] == uniqueId);
      
      if (currentIndex != -1 && newPosition != currentIndex) {
        // Ajouter à l'historique
        _addToHistory();
        
        // Déplacer la section
        final section = _templateSections.removeAt(currentIndex);
        
        // Ajuster la position si nécessaire
        final adjustedPosition = newPosition > currentIndex ? newPosition - 1 : newPosition;
        _templateSections.insert(adjustedPosition, section);
        
        // Mettre à jour l'ordre de toutes les sections
        for (int i = 0; i < _templateSections.length; i++) {
          _templateSections[i]['order'] = i;
        }
        
        _lastModificationTime = DateTime.now();
      }
    } catch (e) {
      print('Erreur déplacement section: $e');
      rethrow;
    }
  }

  /// Mettre à jour le contenu d'une section
  void updateSectionContent(String uniqueId, Map<String, dynamic> newContent) {
    try {
      final index = _templateSections.indexWhere((section) => section['uniqueId'] == uniqueId);
      
      if (index != -1) {
        // Ajouter à l'historique
        _addToHistory();
        
        // Mettre à jour le contenu
        final section = _templateSections[index];
        section['content'] = Map<String, dynamic>.from(newContent);
        section['lastModified'] = DateTime.now().toIso8601String();
        
        _lastModificationTime = DateTime.now();
      }
    } catch (e) {
      print('Erreur mise à jour section: $e');
      rethrow;
    }
  }

  /// Dupliquer une section
  void duplicateSection(String uniqueId) {
    try {
      final index = _templateSections.indexWhere((section) => section['uniqueId'] == uniqueId);
      
      if (index != -1) {
        // Ajouter à l'historique
        _addToHistory();
        
        // Cloner la section
        final originalSection = _templateSections[index];
        final duplicatedSection = Map<String, dynamic>.from(originalSection);
        
        // Générer un nouvel ID unique
        duplicatedSection['uniqueId'] = '${originalSection['id']}_${DateTime.now().millisecondsSinceEpoch}';
        duplicatedSection['addedAt'] = DateTime.now().toIso8601String();
        duplicatedSection['order'] = _templateSections.length;
        
        // Ajouter la section dupliquée
        _templateSections.add(duplicatedSection);
        
        _componentCount++;
        _lastModificationTime = DateTime.now();
      }
    } catch (e) {
      print('Erreur duplication section: $e');
      rethrow;
    }
  }

  /// Obtenir toutes les sections du template
  List<Map<String, dynamic>> getTemplateSections() {
    return List.from(_templateSections);
  }

  /// Obtenir une section spécifique
  Map<String, dynamic>? getSection(String uniqueId) {
    try {
      final index = _templateSections.indexWhere((section) => section['uniqueId'] == uniqueId);
      return index != -1 ? Map<String, dynamic>.from(_templateSections[index]) : null;
    } catch (e) {
      print('Erreur récupération section: $e');
      return null;
    }
  }

  /// Valider la structure du template
  Map<String, dynamic> validateTemplate() {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Vérifier les sections requises
    final requiredSections = _availableComponents
        .where((component) => component['constraints']?['required'] == true)
        .map((component) => component['id'])
        .toList();
    
    final existingSectionIds = _templateSections.map((section) => section['id']).toList();
    
    for (final requiredId in requiredSections) {
      if (!existingSectionIds.contains(requiredId)) {
        errors.add('Section requise manquante: $requiredId');
      }
    }
    
    // Vérifier l'ordre des sections
    if (_templateSections.isNotEmpty) {
      final firstSection = _templateSections.first;
      if (firstSection['id'] != 'header') {
        warnings.add('Il est recommandé de commencer par une section en-tête');
      }
      
      final lastSection = _templateSections.last;
      if (lastSection['id'] != 'footer') {
        warnings.add('Il est recommandé de terminer par une section pied de page');
      }
    }
    
    // Vérifier les contraintes des sections
    for (final section in _templateSections) {
      final component = _availableComponents.firstWhere(
        (comp) => comp['id'] == section['id'],
        orElse: () => <String, dynamic>{},
      );
      
      if (component.isNotEmpty) {
        final constraints = component['constraints'] as Map<String, dynamic>?;
        if (constraints != null) {
          // Vérifier les contraintes de colonnes
          if (constraints.containsKey('minColumns') && constraints.containsKey('maxColumns')) {
            final content = section['content'] as Map<String, dynamic>?;
            if (content != null && content.containsKey('columns')) {
              final columns = content['columns'] as num;
              if (columns < constraints['minColumns'] || columns > constraints['maxColumns']) {
                errors.add('${section['name']}: Nombre de colonnes invalide (${constraints['minColumns']}-${constraints['maxColumns']})');
              }
            }
          }
        }
      }
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'sectionCount': _templateSections.length,
      'requiredSections': requiredSections,
      'existingSections': existingSectionIds,
    };
  }

  /// Générer le HTML du template
  String generateTemplateHTML() {
    try {
      final sections = _templateSections.map((section) => _generateSectionHTML(section)).join('\n');
      
      return '''
        <!DOCTYPE html>
        <html lang="fr">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Template Marketplace</title>
          <style>
            /* CSS sera injecté dynamiquement par TemplatePreviewService */
          </style>
        </head>
        <body>
          $sections
        </body>
        </html>
      ''';
    } catch (e) {
      print('Erreur génération HTML: $e');
      return '<div>Erreur de génération du template</div>';
    }
  }

  /// Générer le HTML d'une section
  String _generateSectionHTML(Map<String, dynamic> section) {
    final id = section['id'] as String;
    final uniqueId = section['uniqueId'] as String;
    final content = section['content'] as Map<String, dynamic>? ?? {};
    
    switch (id) {
      case 'header':
        return '''
          <header class="header" data-section-id="$uniqueId">
            <h1>${content['title'] ?? 'Titre de la boutique'}</h1>
            <p>${content['subtitle'] ?? 'Sous-titre accrocheur'}</p>
          </header>
        ''';
        
      case 'hero':
        return '''
          <section class="hero" data-section-id="$uniqueId">
            <div class="hero-content">
              <h2>${content['title'] ?? 'Bienvenue sur notre boutique'}</h2>
              <p>${content['description'] ?? 'Découvrez nos produits exceptionnels'}</p>
              <a href="${content['ctaLink'] ?? '/products'}" class="cta-button">
                ${content['ctaText'] ?? 'Commencer à acheter'}
              </a>
            </div>
          </section>
        ''';
        
      case 'products_grid':
        final columns = content['columns'] ?? 4;
        final rows = content['rows'] ?? 2;
        final products = List.generate(columns * rows, (index) => '''
          <div class="card product-card">
            <div class="product-image"></div>
            <h3>Produit ${index + 1}</h3>
            <p>Description du produit ${index + 1}</p>
            <span class="price">€${(20 + index * 5)}</span>
          </div>
        ''').join('');
        
        return '''
          <section class="products-section" data-section-id="$uniqueId">
            <h2>${content['title'] ?? 'Nos Produits'}</h2>
            <p>${content['subtitle'] ?? 'Découvrez notre sélection'}</p>
            <div class="grid products-grid" style="grid-template-columns: repeat($columns, 1fr);">
              $products
            </div>
          </section>
        ''';
        
      case 'testimonials':
        final testimonials = (content['testimonials'] as List<dynamic>? ?? []).map((testimonial) => '''
          <div class="testimonial">
            <p>"${testimonial['text'] ?? 'Témoignage'}"</p>
            <div class="author">
              <strong>${testimonial['author'] ?? 'Client'}</strong>
              <div class="rating">
                ${'★' * (testimonial['rating'] ?? 5)}
              </div>
            </div>
          </div>
        ''').join('');
        
        return '''
          <section class="testimonials-section" data-section-id="$uniqueId">
            <h2>${content['title'] ?? 'Ce que disent nos clients'}</h2>
            <div class="testimonials-container">
              $testimonials
            </div>
          </section>
        ''';
        
      case 'newsletter':
        return '''
          <section class="newsletter-section" data-section-id="$uniqueId">
            <h2>${content['title'] ?? 'Restez informé'}</h2>
            <p>${content['subtitle'] ?? 'Recevez nos dernières offres'}</p>
            <form class="newsletter-form">
              <input type="email" placeholder="${content['placeholder'] ?? 'Votre email'}" required>
              <button type="submit">${content['buttonText'] ?? 'S\'inscrire'}</button>
            </form>
            <p class="privacy-text">${content['privacyText'] ?? 'En vous inscrivant, vous acceptez notre politique de confidentialité'}</p>
          </section>
        ''';
        
      case 'footer':
        final links = (content['links'] as List<dynamic>? ?? []).map((link) => '''
          <a href="${link['url'] ?? '#'}">${link['text'] ?? 'Lien'}</a>
        ''').join('');
        
        return '''
          <footer class="footer" data-section-id="$uniqueId">
            <div class="footer-content">
              <div class="company-info">
                <h3>${content['companyName'] ?? 'Nom de l\'entreprise'}</h3>
                <p>${content['description'] ?? 'Description courte de l\'entreprise'}</p>
              </div>
              <div class="footer-links">
                $links
              </div>
            </div>
          </footer>
        ''';
        
      default:
        return '''
          <section class="unknown-section" data-section-id="$uniqueId">
            <p>Section inconnue: $id</p>
          </section>
        ''';
    }
  }

  /// Ajouter à l'historique
  void _addToHistory() {
    // Supprimer les éléments après l'index actuel
    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }
    
    // Ajouter l'état actuel
    _history.add(_templateSections.map((section) => Map<String, dynamic>.from(section)).toList());
    _currentHistoryIndex = _history.length - 1;
    
    // Limiter l'historique à 20 états
    if (_history.length > 20) {
      _history.removeAt(0);
      _currentHistoryIndex--;
    }
  }

  /// Annuler la dernière action
  bool undo() {
    if (_currentHistoryIndex > 0) {
      _currentHistoryIndex--;
      _templateSections.clear();
      _templateSections.addAll(_history[_currentHistoryIndex].map((section) => Map<String, dynamic>.from(section)));
      _lastModificationTime = DateTime.now();
      return true;
    }
    return false;
  }

  /// Rétablir l'action annulée
  bool redo() {
    if (_currentHistoryIndex < _history.length - 1) {
      _currentHistoryIndex++;
      _templateSections.clear();
      _templateSections.addAll(_history[_currentHistoryIndex].map((section) => Map<String, dynamic>.from(section)));
      _lastModificationTime = DateTime.now();
      return true;
    }
    return false;
  }

  /// Obtenir les statistiques du template
  Map<String, dynamic> getTemplateStats() {
    return {
      'totalSections': _templateSections.length,
      'componentCount': _componentCount,
      'lastModification': _lastModificationTime?.toIso8601String(),
      'canUndo': _currentHistoryIndex > 0,
      'canRedo': _currentHistoryIndex < _history.length - 1,
      'historySize': _history.length,
      'validation': validateTemplate(),
    };
  }

  /// Réinitialiser le template
  void resetTemplate() {
    _addToHistory();
    _templateSections.clear();
    _componentCount = 0;
    _lastModificationTime = DateTime.now();
  }

  /// Nettoyer les ressources
  void dispose() {
    _templateSections.clear();
    _history.clear();
    _currentHistoryIndex = -1;
  }
}
