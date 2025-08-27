import 'package:flutter/material.dart';

class TemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;

  const TemplateSelector({
    super.key,
    required this.selectedTemplate,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final templates = [
      {
        'id': 'feminine',
        'name': 'Féminin',
        'description': 'Design élégant et doux',
        'colors': [const Color(0xFFFF69B4), const Color(0xFFFF1493)],
        'icon': Icons.favorite,
      },
      {
        'id': 'masculine',
        'name': 'Masculin',
        'description': 'Design moderne et fort',
        'colors': [const Color(0xFF4169E1), const Color(0xFF000080)],
        'icon': Icons.sports,
      },
      {
        'id': 'neutral',
        'name': 'Neutre',
        'description': 'Design équilibré',
        'colors': [const Color(0xFF808080), const Color(0xFF696969)],
        'icon': Icons.balance,
      },
      {
        'id': 'urban',
        'name': 'Urbain',
        'description': 'Design moderne et dynamique',
        'colors': [const Color(0xFF32CD32), const Color(0xFF228B22)],
        'icon': Icons.location_city,
      },
      {
        'id': 'minimal',
        'name': 'Minimal',
        'description': 'Design épuré et simple',
        'colors': [const Color(0xFFF5F5F5), const Color(0xFFD3D3D3)],
        'icon': Icons.minimize,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = selectedTemplate == template['id'];
        
        return GestureDetector(
          onTap: () => onTemplateSelected(template['id'] as String),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: template['colors'] as List<Color>,
              ),
            ),
            child: Stack(
              children: [
                // Contenu du template
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        template['icon'] as IconData,
                        color: Colors.white,
                        size: 32,
                      ),
                      const Spacer(),
                      Text(
                        template['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template['description'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Indicateur de sélection
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget alternatif pour la compatibilité
class TemplateSelectorWidget extends StatelessWidget {
  const TemplateSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TemplateSelector(
      selectedTemplate: 'feminine',
      onTemplateSelected: (template) {
        // Action par défaut
      },
    );
  }
}