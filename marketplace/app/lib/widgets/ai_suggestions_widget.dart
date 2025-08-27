import 'package:flutter/material.dart';

/// ✨ Widget d'affichage des suggestions et génération de contenu IA
/// 
/// Affiche de manière organisée :
/// - Titres SEO optimisés
/// - Descriptions enrichies
/// - Mots-clés ciblés
/// - Meta tags générés
/// - Suggestions d'amélioration
class AISuggestionsWidget extends StatelessWidget {
  final Map<String, dynamic> suggestions;

  const AISuggestionsWidget({
    super.key,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple[600], size: 28),
              const SizedBox(width: 12),
              Text(
                'Suggestions IA - Contenu Optimisé',
                style: TextStyle(
                  color: Colors.purple[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Titres SEO
          if (suggestions['seoTitles'] != null) ...[
            _buildSuggestionSection(
              '🎯 Titres SEO Optimisés',
              suggestions['seoTitles'] as List,
              Icons.title,
              Colors.blue,
            ),
            const SizedBox(height: 16),
          ],
          
          // Descriptions enrichies
          if (suggestions['enrichedDescriptions'] != null) ...[
            _buildSuggestionSection(
              '📝 Descriptions Enrichies',
              suggestions['enrichedDescriptions'] as List,
              Icons.description,
              Colors.green,
            ),
            const SizedBox(height: 16),
          ],
          
          // Mots-clés ciblés
          if (suggestions['targetedKeywords'] != null) ...[
            _buildSuggestionSection(
              '🔑 Mots-clés Ciblés',
              suggestions['targetedKeywords'] as List,
              Icons.key,
              Colors.orange,
            ),
            const SizedBox(height: 16),
          ],
          
          // Meta tags
          if (suggestions['metaTags'] != null) ...[
            _buildMetaTagsSection(suggestions['metaTags'] as Map<String, dynamic>),
            const SizedBox(height: 16),
          ],
          
          // Suggestions d'amélioration
          if (suggestions['improvementSuggestions'] != null) ...[
            _buildImprovementSuggestions(suggestions['improvementSuggestions'] as List),
          ],
        ],
      ),
    );
  }

  /// Construction d'une section de suggestions
  Widget _buildSuggestionSection(
    String title,
    List suggestions,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Liste des suggestions avec scores
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            final score = suggestion['score'] ?? 0;
            final text = suggestion['text'] ?? suggestion.toString();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$score%',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Section des meta tags
  Widget _buildMetaTagsSection(Map<String, dynamic> metaTags) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, color: Colors.indigo[600], size: 24),
              const SizedBox(width: 12),
              Text(
                '🏷️ Meta Tags Générés',
                style: TextStyle(
                  color: Colors.indigo[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Meta tags avec syntaxe HTML
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              fontFamily: 'monospace',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '<!-- Meta Tags IA Générés -->',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                
                if (metaTags['title'] != null) ...[
                  _buildMetaTagLine('title', metaTags['title']),
                ],
                
                if (metaTags['description'] != null) ...[
                  _buildMetaTagLine('description', metaTags['description']),
                ],
                
                if (metaTags['keywords'] != null) ...[
                  _buildMetaTagLine('keywords', metaTags['keywords']),
                ],
                
                if (metaTags['ogTitle'] != null) ...[
                  _buildMetaTagLine('og:title', metaTags['ogTitle']),
                ],
                
                if (metaTags['ogDescription'] != null) ...[
                  _buildMetaTagLine('og:description', metaTags['ogDescription']),
                ],
                
                if (metaTags['twitterCard'] != null) ...[
                  _buildMetaTagLine('twitter:card', metaTags['twitterCard']),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne de meta tag
  Widget _buildMetaTagLine(String property, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            height: 1.4,
          ),
          children: [
            const TextSpan(
              text: '<meta ',
              style: TextStyle(color: Colors.purple),
            ),
            TextSpan(
              text: 'property="',
              style: TextStyle(color: Colors.blue[700]),
            ),
            TextSpan(
              text: property,
              style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: '" ',
              style: TextStyle(color: Colors.blue[700]),
            ),
            TextSpan(
              text: 'content="',
              style: TextStyle(color: Colors.green[700]),
            ),
            TextSpan(
              text: content,
              style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.w500),
            ),
            const TextSpan(
              text: '" />',
              style: TextStyle(color: Colors.green[700]),
            ),
          ],
        ),
      ),
    );
  }

  /// Suggestions d'amélioration
  Widget _buildImprovementSuggestions(List suggestions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[600]),
              const SizedBox(width: 8),
              Text(
                '💡 Suggestions d\'Amélioration',
                style: TextStyle(
                  color: Colors.amber[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion.toString(),
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
