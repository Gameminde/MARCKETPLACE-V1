import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvancedCustomizationPanel extends StatefulWidget {
  final Function(Map<String, dynamic>) onCustomizationChanged;
  final Map<String, dynamic> initialCustomization;
  
  const AdvancedCustomizationPanel({
    super.key,
    required this.onCustomizationChanged,
    this.initialCustomization = const {},
  });

  @override
  State<AdvancedCustomizationPanel> createState() => _AdvancedCustomizationPanelState();
}

class _AdvancedCustomizationPanelState extends State<AdvancedCustomizationPanel> {
  late Map<String, dynamic> _customization;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _customization = Map.from(widget.initialCustomization);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Header avec titre et actions
          _buildHeader(),
          
          // Tabs de personnalisation
          _buildTabs(),
          
          // Contenu des tabs
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
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
            child: Text(
              'Personnalisation Avancée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _resetCustomization,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'icon': Icons.palette, 'label': 'Couleurs'},
      {'icon': Icons.text_fields, 'label': 'Typographie'},
      {'icon': Icons.grid_view, 'label': 'Layout'},
      {'icon': Icons.animation, 'label': 'Animations'},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          final tab = tabs[index];
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 20,
                      color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildColorsTab();
      case 1:
        return _buildTypographyTab();
      case 2:
        return _buildLayoutTab();
      case 3:
        return _buildAnimationsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ===== COLORS TAB =====
  Widget _buildColorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Palettes IA', Icons.auto_awesome),
          const SizedBox(height: 12),
          
          // Palettes IA suggérées
          _buildAIColorPalettes(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Couleurs Personnalisées', Icons.color_lens),
          const SizedBox(height: 12),
          
          // Sélecteur de couleurs
          _buildColorPicker(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Psychologie des Couleurs', Icons.psychology),
          const SizedBox(height: 12),
          
          // Conseils psychologie
          _buildColorPsychologyTips(),
        ],
      ),
    );
  }

  Widget _buildAIColorPalettes() {
    final palettes = [
      {
        'name': 'Moderne & Élégant',
        'colors': ['#2C3E50', '#3498DB', '#E74C3C', '#F39C12', '#ECF0F1'],
        'score': 95,
      },
      {
        'name': 'Nature & Organique',
        'colors': ['#27AE60', '#8BC34A', '#FFC107', '#FF9800', '#795548'],
        'score': 88,
      },
      {
        'name': 'Tech & Innovation',
        'colors': ['#9C27B0', '#673AB7', '#3F51B5', '#2196F3', '#00BCD4'],
        'score': 92,
      },
    ];

    return Column(
      children: palettes.map((palette) {
        return _buildColorPaletteCard(palette);
      }).toList(),
    );
  }

  Widget _buildColorPaletteCard(Map<String, dynamic> palette) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _applyColorPalette(palette),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      palette['name'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${palette['score']}%',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: (palette['colors'] as List<String>).map((color) {
                  return Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Couleur principale',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _customization['primaryColor'] ?? Colors.blue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: InkWell(
                onTap: _showColorPicker,
                borderRadius: BorderRadius.circular(8),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _customization['primaryColor']?.toString() ?? '#2196F3',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPsychologyTips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Conseil IA',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Le bleu inspire confiance et professionnalisme. Parfait pour les boutiques tech et finance.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===== TYPOGRAPHY TAB =====
  Widget _buildTypographyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Google Fonts', Icons.font_download),
          const SizedBox(height: 12),
          
          _buildFontSelector(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Taille & Espacement', Icons.format_size),
          const SizedBox(height: 12),
          
          _buildFontSizeControls(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Suggestions IA', Icons.auto_awesome),
          const SizedBox(height: 12),
          
          _buildFontSuggestions(),
        ],
      ),
    );
  }

  Widget _buildFontSelector() {
    final fonts = [
      'Poppins',
      'Inter',
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Source Sans Pro',
      'Ubuntu',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Police principale',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView.builder(
            itemCount: fonts.length,
            itemBuilder: (context, index) {
              final font = fonts[index];
              final isSelected = _customization['primaryFont'] == font;
              
              return ListTile(
                dense: true,
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: isSelected 
                    ? Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
                ),
                title: Text(
                  font,
                  style: GoogleFonts.getFont(font, fontSize: 16),
                ),
                onTap: () => _selectFont(font),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderControl(
          'Taille titre',
          'titleSize',
          24.0,
          48.0,
          _customization['titleSize'] ?? 32.0,
        ),
        const SizedBox(height: 16),
        _buildSliderControl(
          'Taille texte',
          'bodySize',
          12.0,
          24.0,
          _customization['bodySize'] ?? 16.0,
        ),
        const SizedBox(height: 16),
        _buildSliderControl(
          'Espacement lignes',
          'lineHeight',
          1.0,
          2.0,
          _customization['lineHeight'] ?? 1.5,
        ),
      ],
    );
  }

  Widget _buildFontSuggestions() {
    final suggestions = [
      {
        'font': 'Inter',
        'reason': 'Excellente lisibilité sur tous les écrans',
        'score': 96,
      },
      {
        'font': 'Poppins',
        'reason': 'Moderne et professionnel pour e-commerce',
        'score': 94,
      },
    ];

    return Column(
      children: suggestions.map((suggestion) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            dense: true,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              suggestion['font'] as String,
              style: GoogleFonts.getFont(
                suggestion['font'] as String,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              suggestion['reason'] as String,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                '${suggestion['score']}%',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () => _selectFont(suggestion['font'] as String),
          ),
        );
      }).toList(),
    );
  }

  // ===== LAYOUT TAB =====
  Widget _buildLayoutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Presets Layout', Icons.grid_view),
          const SizedBox(height: 12),
          
          _buildLayoutPresets(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Grille Responsive', Icons.view_column),
          const SizedBox(height: 12),
          
          _buildGridControls(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Espacement', Icons.space_bar),
          const SizedBox(height: 12),
          
          _buildSpacingControls(),
        ],
      ),
    );
  }

  Widget _buildLayoutPresets() {
    final presets = [
      {
        'name': 'Grid Classique',
        'icon': Icons.grid_4x4,
        'description': 'Grille 4 colonnes responsive',
        'type': 'grid',
      },
      {
        'name': 'Masonry',
        'icon': Icons.view_quilt,
        'description': 'Layout Pinterest style',
        'type': 'masonry',
      },
      {
        'name': 'Flexbox',
        'icon': Icons.view_agenda,
        'description': 'Flexible et adaptatif',
        'type': 'flexbox',
      },
      {
        'name': 'Carousel',
        'icon': Icons.view_carousel,
        'description': 'Défilement horizontal',
        'type': 'carousel',
      },
    ];

    return Column(
      children: presets.map((preset) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            dense: true,
            leading: Icon(
              preset['icon'] as IconData,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              preset['name'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              preset['description'] as String,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () => _selectLayoutPreset(preset['type'] as String),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderControl(
          'Colonnes desktop',
          'desktopColumns',
          1.0,
          6.0,
          _customization['desktopColumns'] ?? 4.0,
        ),
        const SizedBox(height: 16),
        _buildSliderControl(
          'Colonnes tablet',
          'tabletColumns',
          1.0,
          4.0,
          _customization['tabletColumns'] ?? 3.0,
        ),
        const SizedBox(height: 16),
        _buildSliderControl(
          'Colonnes mobile',
          'mobileColumns',
          1.0,
          2.0,
          _customization['mobileColumns'] ?? 1.0,
        ),
      ],
    );
  }

  Widget _buildSpacingControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderControl(
          'Espacement grille',
          'gridGap',
          8.0,
          32.0,
          _customization['gridGap'] ?? 16.0,
        ),
        const SizedBox(height: 16),
        _buildSliderControl(
          'Padding sections',
          'sectionPadding',
          16.0,
          64.0,
          _customization['sectionPadding'] ?? 32.0,
        ),
      ],
    );
  }

  // ===== ANIMATIONS TAB =====
  Widget _buildAnimationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Animations Page', Icons.animation),
          const SizedBox(height: 12),
          
          _buildPageAnimationControls(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Micro-interactions', Icons.touch_app),
          const SizedBox(height: 12),
          
          _buildMicroInteractionControls(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Performance', Icons.speed),
          const SizedBox(height: 12),
          
          _buildPerformanceControls(),
        ],
      ),
    );
  }

  Widget _buildPageAnimationControls() {
    final animations = [
      {'name': 'Fade In', 'value': 'fade'},
      {'name': 'Slide Up', 'value': 'slideUp'},
      {'name': 'Zoom In', 'value': 'zoomIn'},
      {'name': 'None', 'value': 'none'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Animation d\'entrée',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...animations.map((animation) {
          final isSelected = _customization['pageAnimation'] == animation['value'];
          return RadioListTile<String>(
            title: Text(animation['name'] as String),
            value: animation['value'] as String,
            groupValue: _customization['pageAnimation'] ?? 'fade',
            onChanged: (value) => _updateCustomization('pageAnimation', value),
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }),
        
        const SizedBox(height: 16),
        _buildSliderControl(
          'Durée animation',
          'animationDuration',
          200.0,
          1000.0,
          _customization['animationDuration'] ?? 400.0,
        ),
      ],
    );
  }

  Widget _buildMicroInteractionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Hover effects'),
          subtitle: const Text('Animations au survol'),
          value: _customization['hoverEffects'] ?? true,
          onChanged: (value) => _updateCustomization('hoverEffects', value),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Click feedback'),
          subtitle: const Text('Retour visuel au clic'),
          value: _customization['clickFeedback'] ?? true,
          onChanged: (value) => _updateCustomization('clickFeedback', value),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Scroll animations'),
          subtitle: const Text('Animations au défilement'),
          value: _customization['scrollAnimations'] ?? false,
          onChanged: (value) => _updateCustomization('scrollAnimations', value),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPerformanceControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Reduced motion'),
          subtitle: const Text('Respecter les préférences utilisateur'),
          value: _customization['reducedMotion'] ?? true,
          onChanged: (value) => _updateCustomization('reducedMotion', value),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('GPU acceleration'),
          subtitle: const Text('Utiliser le GPU pour les animations'),
          value: _customization['gpuAcceleration'] ?? true,
          onChanged: (value) => _updateCustomization('gpuAcceleration', value),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // ===== UTILITY WIDGETS =====
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderControl(String label, String key, double min, double max, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / 0.5).round(),
          onChanged: (newValue) => _updateCustomization(key, newValue),
        ),
      ],
    );
  }

  // ===== METHODS =====
  void _updateCustomization(String key, dynamic value) {
    setState(() {
      _customization[key] = value;
    });
    widget.onCustomizationChanged(_customization);
  }

  void _applyColorPalette(Map<String, dynamic> palette) {
    setState(() {
      _customization['colorPalette'] = palette['name'];
      _customization['colors'] = palette['colors'];
    });
    widget.onCustomizationChanged(_customization);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Palette ${palette['name']} appliquée !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _selectFont(String font) {
    setState(() {
      _customization['primaryFont'] = font;
    });
    widget.onCustomizationChanged(_customization);
  }

  void _selectLayoutPreset(String type) {
    setState(() {
      _customization['layoutType'] = type;
    });
    widget.onCustomizationChanged(_customization);
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une couleur'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _customization['primaryColor'] ?? Colors.blue,
            onColorChanged: (color) {
              setState(() {
                _customization['primaryColor'] = color;
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onCustomizationChanged(_customization);
              Navigator.of(context).pop();
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _resetCustomization() {
    setState(() {
      _customization = {};
    });
    widget.onCustomizationChanged(_customization);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Personnalisation réinitialisée !'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
