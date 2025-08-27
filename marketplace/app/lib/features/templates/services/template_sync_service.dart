import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

/// Service de synchronisation temps réel entre le panel de personnalisation
/// et la preview WebView pour une expérience révolutionnaire
class TemplateSyncService {
  static final TemplateSyncService _instance = TemplateSyncService._internal();
  factory TemplateSyncService() => _instance;
  TemplateSyncService._internal();

  // Stream controllers pour la synchronisation temps réel
  final StreamController<Map<String, dynamic>> _customizationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  final StreamController<String> _cssController = 
      StreamController<String>.broadcast();
  
  final StreamController<Map<String, dynamic>> _aiSuggestionController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Cache des personnalisations
  final Map<String, dynamic> _customizationCache = {};
  
  // Historique des modifications pour undo/redo
  final List<Map<String, dynamic>> _history = [];
  int _currentHistoryIndex = -1;
  
  // Métriques de performance
  int _syncCount = 0;
  DateTime? _lastSyncTime;
  final List<double> _syncTimes = [];

  // Getters pour les streams
  Stream<Map<String, dynamic>> get customizationStream => _customizationController.stream;
  Stream<String> get cssStream => _cssController.stream;
  Stream<Map<String, dynamic>> get aiSuggestionStream => _aiSuggestionController.stream;

  /// Synchronise une personnalisation en temps réel
  void syncCustomization(Map<String, dynamic> customization) {
    try {
      // Validation des données
      final validated = _validateCustomization(customization);
      
      // Mise en cache
      _customizationCache.addAll(validated);
      
      // Ajout à l'historique
      _addToHistory(validated);
      
      // Génération CSS optimisée
      final css = _generateOptimizedCSS(validated);
      
      // Broadcast des changements
      _customizationController.add(validated);
      _cssController.add(css);
      
      // Mise à jour des métriques
      _updateSyncMetrics();
      
    } catch (e) {
      print('Erreur synchronisation: $e');
      // Fallback avec anciennes valeurs
      _rollbackToLastValid();
    }
  }

  /// Applique une suggestion IA avec animation
  void applyAISuggestion(Map<String, dynamic> suggestion) {
    try {
      // Préparation de la transition
      final transition = _prepareAITransition(suggestion);
      
      // Broadcast de la suggestion
      _aiSuggestionController.add({
        'type': 'ai_suggestion',
        'data': suggestion,
        'transition': transition,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Application progressive
      _applyProgressiveCustomization(suggestion);
      
    } catch (e) {
      print('Erreur application IA: $e');
    }
  }

  /// Génère CSS optimisé avec variables CSS custom
  String _generateOptimizedCSS(Map<String, dynamic> customization) {
    final primaryColor = customization['primaryColor'] ?? '#2196F3';
    final primaryFont = customization['primaryFont'] ?? 'Inter';
    final titleSize = customization['titleSize'] ?? 32.0;
    final bodySize = customization['bodySize'] ?? 16.0;
    final lineHeight = customization['lineHeight'] ?? 1.5;
    final gridGap = customization['gridGap'] ?? 16.0;
    final sectionPadding = customization['sectionPadding'] ?? 32.0;
    final layoutType = customization['layoutType'] ?? 'grid';
    final desktopColumns = customization['desktopColumns'] ?? 4.0;
    final tabletColumns = customization['tabletColumns'] ?? 3.0;
    final mobileColumns = customization['mobileColumns'] ?? 1.0;

    return '''
      :root {
        --primary-color: $primaryColor;
        --primary-font: '$primaryFont', -apple-system, BlinkMacSystemFont, sans-serif;
        --title-size: ${titleSize}px;
        --body-size: ${bodySize}px;
        --line-height: $lineHeight;
        --grid-gap: ${gridGap}px;
        --section-padding: ${sectionPadding}px;
        --desktop-columns: $desktopColumns;
        --tablet-columns: $tabletColumns;
        --mobile-columns: $mobileColumns;
        --layout-type: $layoutType;
      }

      * {
        box-sizing: border-box;
      }

      body {
        font-family: var(--primary-font);
        line-height: var(--line-height);
        color: #333;
        margin: 0;
        padding: 0;
        background: #fafafa;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }

      .header {
        background: var(--primary-color);
        color: white;
        padding: var(--section-padding);
        text-align: center;
        font-size: var(--title-size);
        font-weight: bold;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        position: sticky;
        top: 0;
        z-index: 100;
      }

      .content {
        padding: var(--section-padding);
        max-width: 1200px;
        margin: 0 auto;
      }

      .section {
        margin-bottom: var(--section-padding);
        padding: var(--section-padding);
        border-radius: 12px;
        background: white;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        border: 1px solid rgba(0,0,0,0.05);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        overflow: hidden;
      }

      .section:hover {
        transform: translateY(-4px);
        box-shadow: 0 8px 25px rgba(0,0,0,0.15);
      }

      .section-title {
        font-size: var(--title-size);
        color: var(--primary-color);
        margin-bottom: 16px;
        font-weight: bold;
        position: relative;
      }

      .section-title::after {
        content: '';
        position: absolute;
        bottom: -8px;
        left: 0;
        width: 60px;
        height: 3px;
        background: var(--primary-color);
        border-radius: 2px;
      }

      .section-content {
        font-size: var(--body-size);
        line-height: var(--line-height);
        color: #555;
      }

      .grid {
        display: grid;
        gap: var(--grid-gap);
        grid-template-columns: repeat(var(--desktop-columns), 1fr);
      }

      .card {
        background: white;
        border-radius: 12px;
        padding: 20px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        border: 1px solid rgba(0,0,0,0.05);
        transition: all 0.3s ease;
        cursor: pointer;
      }

      .card:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 16px rgba(0,0,0,0.12);
        border-color: var(--primary-color);
      }

      .footer {
        background: linear-gradient(135deg, var(--primary-color), #1a1a1a);
        color: white;
        padding: var(--section-padding);
        text-align: center;
        font-size: var(--body-size);
        margin-top: var(--section-padding);
      }

      /* Layout variations */
      .layout-masonry {
        column-count: var(--desktop-columns);
        column-gap: var(--grid-gap);
      }

      .layout-masonry .card {
        break-inside: avoid;
        margin-bottom: var(--grid-gap);
      }

      .layout-flexbox {
        display: flex;
        flex-wrap: wrap;
        gap: var(--grid-gap);
      }

      .layout-flexbox .card {
        flex: 1 1 calc((100% / var(--desktop-columns)) - var(--grid-gap));
        min-width: 250px;
      }

      .layout-carousel {
        display: flex;
        overflow-x: auto;
        gap: var(--grid-gap);
        padding: 20px 0;
        scroll-snap-type: x mandatory;
      }

      .layout-carousel .card {
        flex: 0 0 300px;
        scroll-snap-align: start;
      }

      /* Animations avancées */
      @keyframes fadeInUp {
        from {
          opacity: 0;
          transform: translateY(30px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }

      .section {
        animation: fadeInUp 0.6s ease-out;
      }

      .section:nth-child(1) { animation-delay: 0.1s; }
      .section:nth-child(2) { animation-delay: 0.2s; }
      .section:nth-child(3) { animation-delay: 0.3s; }
      .section:nth-child(4) { animation-delay: 0.4s; }

      /* Micro-interactions */
      .card:active {
        transform: scale(0.98);
      }

      /* Responsive design avancé */
      @media (max-width: 1024px) {
        .grid {
          grid-template-columns: repeat(var(--tablet-columns), 1fr);
        }
        
        .layout-masonry {
          column-count: var(--tablet-columns);
        }
        
        .layout-flexbox .card {
          flex: 1 1 calc((100% / var(--tablet-columns)) - var(--grid-gap));
        }
      }

      @media (max-width: 768px) {
        :root {
          --section-padding: 16px;
          --grid-gap: 12px;
        }
        
        .grid {
          grid-template-columns: repeat(var(--mobile-columns), 1fr);
        }
        
        .layout-masonry {
          column-count: var(--mobile-columns);
        }
        
        .layout-flexbox .card {
          flex: 1 1 100%;
        }
        
        .layout-carousel .card {
          flex: 0 0 250px;
        }
        
        .section-title::after {
          width: 40px;
          height: 2px;
        }
      }

      @media (max-width: 480px) {
        .content {
          padding: 16px;
        }
        
        .section {
          padding: 16px;
          margin-bottom: 16px;
        }
        
        .header {
          padding: 20px 16px;
          font-size: calc(var(--title-size) * 0.8);
        }
      }

      /* Performance optimizations */
      .section {
        will-change: transform;
        backface-visibility: hidden;
      }

      /* Accessibility */
      @media (prefers-reduced-motion: reduce) {
        .section,
        .card {
          animation: none;
          transition: none;
        }
      }

      /* Dark mode support */
      @media (prefers-color-scheme: dark) {
        body {
          background: #1a1a1a;
          color: #e0e0e0;
        }
        
        .section {
          background: #2d2d2d;
          border-color: rgba(255,255,255,0.1);
        }
        
        .card {
          background: #2d2d2d;
          border-color: rgba(255,255,255,0.1);
        }
        
        .section-content {
          color: #b0b0b0;
        }
      }
    ''';
  }

  /// Validation des personnalisations
  Map<String, dynamic> _validateCustomization(Map<String, dynamic> customization) {
    final validated = <String, dynamic>{};
    
    // Validation des couleurs
    if (customization['primaryColor'] != null) {
      validated['primaryColor'] = customization['primaryColor'];
    }
    
    // Validation des polices
    final validFonts = ['Inter', 'Poppins', 'Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Source Sans Pro', 'Ubuntu'];
    if (customization['primaryFont'] != null && validFonts.contains(customization['primaryFont'])) {
      validated['primaryFont'] = customization['primaryFont'];
    }
    
    // Validation des tailles
    if (customization['titleSize'] != null) {
      validated['titleSize'] = (customization['titleSize'] as num).clamp(16.0, 72.0);
    }
    
    if (customization['bodySize'] != null) {
      validated['bodySize'] = (customization['bodySize'] as num).clamp(12.0, 24.0);
    }
    
    // Validation des espacements
    if (customization['lineHeight'] != null) {
      validated['lineHeight'] = (customization['lineHeight'] as num).clamp(1.0, 3.0);
    }
    
    if (customization['gridGap'] != null) {
      validated['gridGap'] = (customization['gridGap'] as num).clamp(4.0, 64.0);
    }
    
    if (customization['sectionPadding'] != null) {
      validated['sectionPadding'] = (customization['sectionPadding'] as num).clamp(8.0, 128.0);
    }
    
    // Validation des colonnes
    if (customization['desktopColumns'] != null) {
      validated['desktopColumns'] = (customization['desktopColumns'] as num).clamp(1.0, 8.0);
    }
    
    if (customization['tabletColumns'] != null) {
      validated['tabletColumns'] = (customization['tabletColumns'] as num).clamp(1.0, 6.0);
    }
    
    if (customization['mobileColumns'] != null) {
      validated['mobileColumns'] = (customization['mobileColumns'] as num).clamp(1.0, 3.0);
    }
    
    // Validation du layout
    final validLayouts = ['grid', 'masonry', 'flexbox', 'carousel'];
    if (customization['layoutType'] != null && validLayouts.contains(customization['layoutType'])) {
      validated['layoutType'] = customization['layoutType'];
    }
    
    return validated;
  }

  /// Préparation de la transition IA
  Map<String, dynamic> _prepareAITransition(Map<String, dynamic> suggestion) {
    return {
      'duration': 800,
      'easing': 'cubic-bezier(0.4, 0, 0.2, 1)',
      'stagger': 100,
      'properties': ['color', 'font', 'size', 'spacing'],
    };
  }

  /// Application progressive des personnalisations
  void _applyProgressiveCustomization(Map<String, dynamic> suggestion) {
    // Simulation d'application progressive
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Logique d'application progressive
      if (timer.tick >= 8) {
        timer.cancel();
      }
    });
  }

  /// Ajout à l'historique pour undo/redo
  void _addToHistory(Map<String, dynamic> customization) {
    // Supprimer les éléments après l'index actuel
    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }
    
    // Ajouter la nouvelle personnalisation
    _history.add(Map.from(customization));
    _currentHistoryIndex = _history.length - 1;
    
    // Limiter l'historique à 50 éléments
    if (_history.length > 50) {
      _history.removeAt(0);
      _currentHistoryIndex--;
    }
  }

  /// Annuler la dernière action
  bool undo() {
    if (_currentHistoryIndex > 0) {
      _currentHistoryIndex--;
      final previous = _history[_currentHistoryIndex];
      syncCustomization(previous);
      return true;
    }
    return false;
  }

  /// Rétablir l'action annulée
  bool redo() {
    if (_currentHistoryIndex < _history.length - 1) {
      _currentHistoryIndex++;
      final next = _history[_currentHistoryIndex];
      syncCustomization(next);
      return true;
    }
    return false;
  }

  /// Rollback vers la dernière version valide
  void _rollbackToLastValid() {
    if (_history.isNotEmpty) {
      final lastValid = _history[_currentHistoryIndex];
      _customizationCache.clear();
      _customizationCache.addAll(lastValid);
    }
  }

  /// Mise à jour des métriques de performance
  void _updateSyncMetrics() {
    _syncCount++;
    final now = DateTime.now();
    
    if (_lastSyncTime != null) {
      final syncTime = now.difference(_lastSyncTime!).inMilliseconds.toDouble();
      _syncTimes.add(syncTime);
      
      // Garder seulement les 100 dernières mesures
      if (_syncTimes.length > 100) {
        _syncTimes.removeAt(0);
      }
    }
    
    _lastSyncTime = now;
  }

  /// Obtenir les statistiques de performance
  Map<String, dynamic> getPerformanceStats() {
    if (_syncTimes.isEmpty) {
      return {
        'totalSyncs': _syncCount,
        'averageSyncTime': 0.0,
        'lastSync': _lastSyncTime?.toIso8601String(),
        'historySize': _history.length,
      };
    }
    
    final averageSyncTime = _syncTimes.reduce((a, b) => a + b) / _syncTimes.length;
    
    return {
      'totalSyncs': _syncCount,
      'averageSyncTime': averageSyncTime,
      'minSyncTime': _syncTimes.reduce((a, b) => a < b ? a : b),
      'maxSyncTime': _syncTimes.reduce((a, b) => a > b ? a : b),
      'lastSync': _lastSyncTime?.toIso8601String(),
      'historySize': _history.length,
      'canUndo': _currentHistoryIndex > 0,
      'canRedo': _currentHistoryIndex < _history.length - 1,
    };
  }

  /// Nettoyer les ressources
  void dispose() {
    _customizationController.close();
    _cssController.close();
    _aiSuggestionController.close();
    _customizationCache.clear();
    _history.clear();
  }
}
