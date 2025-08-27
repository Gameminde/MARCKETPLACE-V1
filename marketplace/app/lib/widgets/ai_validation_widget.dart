import 'package:flutter/material.dart';

/// 🔍 Widget d'affichage des résultats de validation IA
/// 
/// Affiche de manière claire et visuelle :
/// - Score de validation global
/// - Détails par catégorie (images, contenu, prix, etc.)
/// - Suggestions d'amélioration
/// - Statut de validation (approuvé/rejeté)
class AIValidationWidget extends StatelessWidget {
  final Map<String, dynamic> validationResult;

  const AIValidationWidget({
    super.key,
    required this.validationResult,
  });

  @override
  Widget build(BuildContext context) {
    final score = validationResult['score'] ?? 0;
    final isApproved = score >= 70;
    final status = isApproved ? 'APPROUVÉ' : 'REJETÉ';
    final statusColor = isApproved ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec score et statut
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Score IA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$score/100',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Détails de validation par catégorie
          _buildValidationCategory(
            '🖼️ Images',
            validationResult['imageValidation'] ?? {},
            Icons.image,
          ),
          
          const SizedBox(height: 16),
          
          _buildValidationCategory(
            '📝 Contenu',
            validationResult['contentValidation'] ?? {},
            Icons.description,
          ),
          
          const SizedBox(height: 16),
          
          _buildValidationCategory(
            '💰 Prix & Marché',
            validationResult['priceValidation'] ?? {},
            Icons.attach_money,
          ),
          
          const SizedBox(height: 16),
          
          _buildValidationCategory(
            '🏷️ Catégorisation',
            validationResult['categoryValidation'] ?? {},
            Icons.category,
          ),
          
          // Suggestions d'amélioration
          if (validationResult['suggestions'] != null && 
              (validationResult['suggestions'] as List).isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSuggestionsSection(validationResult['suggestions'] as List),
          ],
          
          // Temps de traitement
          if (validationResult['processingTime'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Traitement IA: ${validationResult['processingTime']}ms',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construction d'une catégorie de validation
  Widget _buildValidationCategory(
    String title,
    Map<String, dynamic> categoryData,
    IconData icon,
  ) {
    final score = categoryData['score'] ?? 0;
    final status = categoryData['status'] ?? 'unknown';
    final details = categoryData['details'] ?? [];
    
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approuvé';
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusText = 'Attention';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejeté';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Score de la catégorie
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$score/100',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          // Détails de la validation
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    detail['status'] == 'success' ? Icons.check_circle : 
                    detail['status'] == 'warning' ? Icons.warning : Icons.error,
                    size: 16,
                    color: detail['status'] == 'success' ? Colors.green :
                           detail['status'] == 'warning' ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail['message'] ?? 'Détail de validation',
                      style: TextStyle(
                        fontSize: 13,
                        color: detail['status'] == 'success' ? Colors.green[700] :
                               detail['status'] == 'warning' ? Colors.orange[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  /// Section des suggestions d'amélioration
  Widget _buildSuggestionsSection(List suggestions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(
                'Suggestions d\'amélioration',
                style: TextStyle(
                  color: Colors.orange[700],
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
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion.toString(),
                    style: TextStyle(
                      color: Colors.orange[700],
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
