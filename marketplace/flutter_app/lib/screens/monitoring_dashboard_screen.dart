import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/config/app_constants.dart';
import '../services/performance_service.dart';
import '../services/crash_reporting_service.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/custom_app_bar.dart';

/// Comprehensive monitoring dashboard for performance and crash analytics
/// 
/// Displays real-time performance metrics, crash reports, and system health
/// information for debugging and monitoring the marketplace application.
class MonitoringDashboardScreen extends StatefulWidget {
  const MonitoringDashboardScreen({super.key});

  @override
  State<MonitoringDashboardScreen> createState() => _MonitoringDashboardScreenState();
}

class _MonitoringDashboardScreenState extends State<MonitoringDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Monitoring Dashboard',
        showBackButton: true,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPerformanceTab(),
                _buildCrashReportsTab(),
                _buildSystemHealthTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.speed),
            text: 'Performance',
          ),
          Tab(
            icon: Icon(Icons.bug_report),
            text: 'Crashes',
          ),
          Tab(
            icon: Icon(Icons.health_and_safety),
            text: 'System Health',
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceOverview(),
          const SizedBox(height: AppConstants.spacingL),
          _buildScreenPerformanceMetrics(),
          const SizedBox(height: AppConstants.spacingL),
          _buildNetworkPerformanceMetrics(),
          const SizedBox(height: AppConstants.spacingL),
          _buildMemoryUsageChart(),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    final summary = PerformanceService.instance.getPerformanceSummary();
    
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Performance Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Metrics',
                    summary.totalMetrics.toString(),
                    Icons.data_usage,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: _buildMetricCard(
                    'Screen Views',
                    summary.screenViews.values
                        .fold(0, (sum, views) => sum + views)
                        .toString(),
                    Icons.visibility,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Avg Load Time',
                    summary.screenLoadAverages.values.isNotEmpty
                        ? '${summary.screenLoadAverages.values.reduce((a, b) => a + b) / summary.screenLoadAverages.values.length ~/ 1}ms'
                        : 'N/A',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: _buildMetricCard(
                    'Operations',
                    summary.operationAverages.length.toString(),
                    Icons.settings,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenPerformanceMetrics() {
    final summary = PerformanceService.instance.getPerformanceSummary();
    
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screen Performance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingM),
            if (summary.screenLoadAverages.isNotEmpty) ...[
              ...summary.screenLoadAverages.entries.map((entry) =>
                _buildPerformanceItem(
                  entry.key,
                  '${entry.value.toInt()}ms',
                  entry.value < 500 ? Colors.green : 
                  entry.value < 1000 ? Colors.orange : Colors.red,
                ),
              ),
            ] else ...[
              const Center(
                child: Text('No screen performance data available'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String name, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(child: Text(name)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkPerformanceMetrics() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Performance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingM),
            // Mock network performance data
            _buildPerformanceItem('API Requests', '1,245', Colors.blue),
            _buildPerformanceItem('Avg Response Time', '245ms', Colors.green),
            _buildPerformanceItem('Success Rate', '98.5%', Colors.green),
            _buildPerformanceItem('Failed Requests', '18', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryUsageChart() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Memory Usage Over Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingL),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateMemoryData(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateMemoryData() {
    // Mock memory usage data
    return [
      const FlSpot(0, 45),
      const FlSpot(1, 52),
      const FlSpot(2, 48),
      const FlSpot(3, 61),
      const FlSpot(4, 55),
      const FlSpot(5, 68),
      const FlSpot(6, 72),
    ];
  }

  Widget _buildCrashReportsTab() {
    final crashStats = CrashReportingService.instance.getCrashStatistics();
    final crashReports = CrashReportingService.instance.getCrashReports();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCrashOverview(crashStats),
          const SizedBox(height: AppConstants.spacingL),
          _buildCrashList(crashReports),
        ],
      ),
    );
  }

  Widget _buildCrashOverview(CrashStatistics stats) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Crash Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Crashes',
                    stats.totalCrashes.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: _buildMetricCard(
                    'Fatal Crashes',
                    stats.fatalCrashes.toString(),
                    Icons.dangerous,
                    Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Last 24h',
                    stats.crashes24Hours.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: _buildMetricCard(
                    'This Week',
                    stats.crashesThisWeek.toString(),
                    Icons.calendar_week,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrashList(List<CrashReport> crashes) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Crashes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _clearAllCrashes(),
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            if (crashes.isNotEmpty) ...[
              ...crashes.take(10).map((crash) => _buildCrashItem(crash)),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.spacingL),
                  child: Text('No crashes recorded'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCrashItem(CrashReport crash) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border.all(
          color: crash.fatal 
              ? Colors.red.withOpacity(0.3) 
              : Colors.orange.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                crash.fatal ? Icons.dangerous : Icons.warning,
                color: crash.fatal ? Colors.red : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  crash.exception.split('\n').first,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(crash.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (crash.reason != null) ...[
            const SizedBox(height: 4),
            Text(
              crash.reason!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemOverview(),
          const SizedBox(height: AppConstants.spacingL),
          _buildResourceUsage(),
          const SizedBox(height: AppConstants.spacingL),
          _buildHealthChecks(),
        ],
      ),
    );
  }

  Widget _buildSystemOverview() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.health_and_safety,
                  color: Colors.green,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'System Health',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Healthy',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),
            _buildHealthIndicator('Performance', 0.92, Colors.green),
            _buildHealthIndicator('Memory Usage', 0.68, Colors.orange),
            _buildHealthIndicator('Network', 0.95, Colors.green),
            _buildHealthIndicator('Storage', 0.45, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceUsage() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resource Usage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildResourceItem('CPU Usage', '23%', Colors.blue),
            _buildResourceItem('Memory Usage', '68%', Colors.orange),
            _buildResourceItem('Storage Used', '45%', Colors.green),
            _buildResourceItem('Network Usage', '12 MB', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthChecks() {
    final healthChecks = [
      {'name': 'API Connectivity', 'status': 'Healthy', 'color': Colors.green},
      {'name': 'Database Connection', 'status': 'Healthy', 'color': Colors.green},
      {'name': 'Cache System', 'status': 'Warning', 'color': Colors.orange},
      {'name': 'Authentication Service', 'status': 'Healthy', 'color': Colors.green},
      {'name': 'Payment Gateway', 'status': 'Healthy', 'color': Colors.green},
    ];

    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Checks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingM),
            ...healthChecks.map((check) => _buildHealthCheckItem(
              check['name'] as String,
              check['status'] as String,
              check['color'] as Color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCheckItem(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            status == 'Healthy' ? Icons.check_circle : Icons.warning,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(child: Text(name)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _clearAllCrashes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Crashes'),
        content: const Text('Are you sure you want to clear all crash data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              CrashReportingService.instance.clearCrashData();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}