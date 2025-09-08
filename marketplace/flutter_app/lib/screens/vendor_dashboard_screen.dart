import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../models/shop.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';

/// Vendor dashboard for comprehensive shop management
class VendorDashboardScreen extends StatefulWidget {
  final Shop shop;

  const VendorDashboardScreen({super.key, required this.shop});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.shop.name} - Dashboard'),
        backgroundColor: widget.shop.branding.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openShopSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Products', icon: Icon(Icons.inventory)),
            Tab(text: 'Orders', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildProductsTab(),
          _buildOrdersTab(),
          _buildAnalyticsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: AppConstants.spacingL),
          _buildQuickStats(),
          const SizedBox(height: AppConstants.spacingL),
          _buildQuickActions(),
          const SizedBox(height: AppConstants.spacingL),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return GlassmorphicContainer.card(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.shop.branding.primaryColor.withOpacity(0.1),
              widget.shop.branding.secondaryColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          children: [
            if (widget.shop.logoUrl != null)
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(widget.shop.logoUrl!),
              )
            else
              CircleAvatar(
                radius: 30,
                backgroundColor: widget.shop.branding.primaryColor,
                child: Text(
                  widget.shop.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: AppConstants.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: widget.shop.branding.primaryColor,
                    ),
                  ),
                  Text(
                    widget.shop.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: widget.shop.isVerified ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.shop.verificationStatus.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.shop.verificationStatus.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Revenue',
                '\$${widget.shop.statistics.totalRevenue.toStringAsFixed(0)}',
                Icons.monetization_on,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildStatCard(
                'Monthly Revenue',
                '\$${widget.shop.statistics.monthlyRevenue.toStringAsFixed(0)}',
                Icons.trending_up,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Products',
                '${widget.shop.totalProducts}',
                Icons.inventory,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildStatCard(
                'Total Orders',
                '${widget.shop.totalOrders}',
                Icons.shopping_cart,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add Product',
                Icons.add_shopping_cart,
                widget.shop.branding.primaryColor,
                _addNewProduct,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildActionCard(
                'View Orders',
                Icons.list_alt,
                widget.shop.branding.secondaryColor,
                _viewOrders,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Manage Inventory',
                Icons.warehouse,
                Colors.orange,
                _manageInventory,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildActionCard(
                'View Analytics',
                Icons.bar_chart,
                Colors.purple,
                _viewAnalytics,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GlassmorphicContainer.card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        GlassmorphicContainer.card(
          child: Column(
            children: [
              _buildActivityItem(
                'New order received',
                'Order #1234 from John Doe',
                Icons.shopping_cart,
                Colors.green,
                '2 hours ago',
              ),
              const Divider(),
              _buildActivityItem(
                'Product updated',
                'Updated "Fashion Shirt" inventory',
                Icons.edit,
                Colors.blue,
                '4 hours ago',
              ),
              const Divider(),
              _buildActivityItem(
                'Review received',
                '5-star review on "Smart Tablet"',
                Icons.star,
                Colors.amber,
                '1 day ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, String time) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Products',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addNewProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.shop.branding.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildProductsList(),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    // Mock product data
    return Column(
      children: List.generate(5, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: GlassmorphicContainer.card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppConstants.spacingM),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, size: 32),
              ),
              title: Text('Product ${index + 1}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$${(50 + index * 10).toStringAsFixed(2)}'),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'In Stock',
                          style: TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Stock: ${20 + index * 5}'),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleProductAction(value, index),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOrdersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildOrdersList(),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Column(
      children: List.generate(8, (index) {
        final statuses = ['pending', 'confirmed', 'shipped', 'delivered'];
        final colors = [Colors.orange, Colors.blue, Colors.purple, Colors.green];
        final statusIndex = index % 4;
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: GlassmorphicContainer.card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppConstants.spacingM),
              leading: CircleAvatar(
                backgroundColor: colors[statusIndex].withOpacity(0.1),
                child: Icon(Icons.shopping_cart, color: colors[statusIndex]),
              ),
              title: Text('Order #${1000 + index}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: John Doe ${index + 1}'),
                  Text('\$${(100 + index * 25).toStringAsFixed(2)}'),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors[statusIndex].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statuses[statusIndex].toUpperCase(),
                          style: TextStyle(color: colors[statusIndex], fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${index + 1} items'),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _viewOrderDetails(index),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          _buildAnalyticsCards(),
          const SizedBox(height: AppConstants.spacingL),
          _buildPerformanceChart(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Views',
                '${widget.shop.statistics.totalViews}',
                Icons.visibility,
                Colors.blue,
                '+12%',
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildAnalyticsCard(
                'Conversion',
                '${widget.shop.statistics.conversionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
                '+0.5%',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Avg Order',
                '\$${widget.shop.statistics.averageOrderValue.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.orange,
                '+8%',
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildAnalyticsCard(
                'Rating',
                '${widget.shop.rating.toStringAsFixed(1)}',
                Icons.star,
                Colors.amber,
                '+0.1',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color, String change) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change,
                    style: const TextStyle(color: Colors.green, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Container(
              height: 200,
              child: const Center(
                child: Text('Chart placeholder - Sales data visualization'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          _buildSettingsSection('Shop Information', [
            _buildSettingItem('Shop Name', widget.shop.name, Icons.store),
            _buildSettingItem('Description', widget.shop.description, Icons.description),
            _buildSettingItem('Category', widget.shop.category.displayName, Icons.category),
          ]),
          _buildSettingsSection('Business Settings', [
            _buildSettingItem('Processing Time', '${widget.shop.settings.processingDays} days', Icons.schedule),
            _buildSettingItem('Minimum Order', '\$${widget.shop.settings.minimumOrderAmount}', Icons.monetization_on),
            _buildSwitchSetting('Accept Orders', widget.shop.settings.acceptOrders),
            _buildSwitchSetting('Auto Approve Returns', widget.shop.settings.autoApproveReturns),
          ]),
          _buildSettingsSection('Communication', [
            _buildSwitchSetting('Enable Chat', widget.shop.settings.enableChat),
            _buildSettingItem('Response Time', 'Within 24 hours', Icons.message),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        GlassmorphicContainer.card(
          child: Column(children: children),
        ),
        const SizedBox(height: AppConstants.spacingL),
      ],
    );
  }

  Widget _buildSettingItem(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _editSetting(title),
    );
  }

  Widget _buildSwitchSetting(String title, bool value) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (newValue) => _toggleSetting(title, newValue),
    );
  }

  // Action methods
  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening notifications...')),
    );
  }

  void _openShopSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening shop settings...')),
    );
  }

  void _addNewProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening product creation...')),
    );
  }

  void _viewOrders() {
    _tabController.animateTo(2);
  }

  void _manageInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening inventory management...')),
    );
  }

  void _viewAnalytics() {
    _tabController.animateTo(3);
  }

  void _handleProductAction(String action, int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action product ${index + 1}')),
    );
  }

  void _viewOrderDetails(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening order ${1000 + index} details')),
    );
  }

  void _editSetting(String setting) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing $setting')),
    );
  }

  void _toggleSetting(String setting, bool value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$setting: ${value ? "Enabled" : "Disabled"}')),
    );
  }
}

extension on double {
  String toFixed(int decimals) => toStringAsFixed(decimals);
}