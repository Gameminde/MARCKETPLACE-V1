import 'package:flutter/material.dart';

/// 💡 Widget d'affichage des insights analytics IA
/// 
/// Affiche de manière claire et visuelle :
/// - Métriques de performance
/// - Tendances et patterns
/// - Recommandations prédictives
/// - Alertes et notifications
/// - Graphiques de données
class AIAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> insights;

  const AIAnalyticsWidget({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.insights, color: Colors.orange[600], size: 28),
              const SizedBox(width: 12),
              Text(
                'Analytics Prédictifs IA',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Métriques clés
          if (insights['keyMetrics'] != null) ...[
            _buildKeyMetricsSection(insights['keyMetrics'] as Map<String, dynamic>),
            const SizedBox(height: 16),
          ],
          
          // Tendances détectées
          if (insights['trends'] != null) ...[
            _buildTrendsSection(insights['trends'] as List),
            const SizedBox(height: 16),
          ],
          
          // Recommandations IA
          if (insights['recommendations'] != null) ...[
            _buildRecommendationsSection(insights['recommendations'] as List),
            const SizedBox(height: 16),
          ],
          
          // Alertes et notifications
          if (insights['alerts'] != null) ...[
            _buildAlertsSection(insights['alerts'] as List),
            const SizedBox(height: 16),
          ],
          
          // Prédictions futures
          if (insights['predictions'] != null) ...[
            _buildPredictionsSection(insights['predictions'] as Map<String, dynamic>),
          ],
        ],
      ),
    );
  }

  /// Section des métriques clés
  Widget _buildKeyMetricsSection(Map<String, dynamic> keyMetrics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Text(
                '📊 Métriques Clés',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Grille de métriques
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildMetricCard('Ventes', keyMetrics['sales'] ?? 'N/A', Colors.green),
              _buildMetricCard('Visiteurs', keyMetrics['visitors'] ?? 'N/A', Colors.blue),
              _buildMetricCard('Conversion', keyMetrics['conversion'] ?? 'N/A', Colors.purple),
              _buildMetricCard('Revenus', keyMetrics['revenue'] ?? 'N/A', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  /// Carte de métrique
  Widget _buildMetricCard(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Section des tendances
  Widget _buildTrendsSection(List trends) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green[600], size: 24),
              const SizedBox(width: 12),
              Text(
                '📈 Tendances Détectées',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Liste des tendances
          ...trends.map((trend) {
            final type = trend['type'] ?? 'neutral';
            final description = trend['description'] ?? 'Tendance détectée';
            final confidence = trend['confidence'] ?? 0;
            
            Color trendColor;
            IconData trendIcon;
            
            switch (type) {
              case 'positive':
                trendColor = Colors.green;
                trendIcon = Icons.trending_up;
                break;
              case 'negative':
                trendColor = Colors.red;
                trendIcon = Icons.trending_down;
                break;
              case 'neutral':
                trendColor = Colors.grey;
                trendIcon = Icons.trending_flat;
                break;
              default:
                trendColor = Colors.blue;
                trendIcon = Icons.analytics;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: trendColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: trendColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(confidence * 100).round()}%',
                      style: TextStyle(
                        color: trendColor,
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

  /// Section des recommandations
  Widget _buildRecommendationsSection(List recommendations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.purple[600], size: 24),
              const SizedBox(width: 12),
              Text(
                '💡 Recommandations IA',
                style: TextStyle(
                  color: Colors.purple[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Liste des recommandations
          ...recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final recommendation = entry.value;
            final priority = recommendation['priority'] ?? 'medium';
            final action = recommendation['action'] ?? 'Action recommandée';
            final impact = recommendation['impact'] ?? 'Impact moyen';
            
            Color priorityColor;
            String priorityText;
            
            switch (priority) {
              case 'high':
                priorityColor = Colors.red;
                priorityText = 'HAUTE';
                break;
              case 'medium':
                priorityColor = Colors.orange;
                priorityText = 'MOYENNE';
                break;
              case 'low':
                priorityColor = Colors.green;
                priorityText = 'FAIBLE';
                break;
              default:
                priorityColor = Colors.grey;
                priorityText = 'N/A';
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: priorityColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          priorityText,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Impact: $impact',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  
                  if (recommendation['reasoning'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      recommendation['reasoning'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Section des alertes
  Widget _buildAlertsSection(List alerts) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600], size: 24),
              const SizedBox(width: 12),
              Text(
                '⚠️ Alertes & Notifications',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Liste des alertes
          ...alerts.map((alert) {
            final severity = alert['severity'] ?? 'info';
            final message = alert['message'] ?? 'Alerte détectée';
            final timestamp = alert['timestamp'] ?? 'Maintenant';
            
            Color alertColor;
            IconData alertIcon;
            
            switch (severity) {
              case 'critical':
                alertColor = Colors.red;
                alertIcon = Icons.error;
                break;
              case 'warning':
                alertColor = Colors.orange;
                alertIcon = Icons.warning;
                break;
              case 'info':
                alertColor = Colors.blue;
                alertIcon = Icons.info;
                break;
              default:
                alertColor = Colors.grey;
                alertIcon = Icons.notifications;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: alertColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(alertIcon, color: alertColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 14,
                            color: alertColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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

  /// Section des prédictions
  Widget _buildPredictionsSection(Map<String, dynamic> predictions) {
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
              Icon(Icons.psychology, color: Colors.indigo[600], size: 24),
              const SizedBox(width: 12),
              Text(
                '🔮 Prédictions IA',
                style: TextStyle(
                  color: Colors.indigo[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Prédictions avec intervalles de confiance
          if (predictions['nextPeriod'] != null) ...[
            _buildPredictionItem(
              'Prochaine période',
              predictions['nextPeriod'],
              Colors.indigo,
            ),
            const SizedBox(height: 12),
          ],
          
          if (predictions['seasonalTrends'] != null) ...[
            _buildPredictionItem(
              'Tendances saisonnières',
              predictions['seasonalTrends'],
              Colors.teal,
            ),
            const SizedBox(height: 12),
          ],
          
          if (predictions['marketConditions'] != null) ...[
            _buildPredictionItem(
              'Conditions de marché',
              predictions['marketConditions'],
              Colors.amber,
            ),
          ],
        ],
      ),
    );
  }

  /// Élément de prédiction
  Widget _buildPredictionItem(String label, dynamic prediction, Color color) {
    final value = prediction['value'] ?? 'N/A';
    final confidence = prediction['confidence'] ?? 0;
    final reasoning = prediction['reasoning'] ?? 'Prédiction basée sur l\'analyse IA';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(confidence * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            reasoning,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
