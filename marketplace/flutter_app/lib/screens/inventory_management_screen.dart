import 'package:flutter/material.dart';

import '../core/config/app_constants.dart';
import '../models/product.dart';
import '../widgets/glassmorphic_container.dart';

/// Comprehensive inventory management system for vendors
class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Inventory'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('Import Products'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Inventory Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Products', icon: Icon(Icons.inventory)),
            Tab(text: 'Low Stock', icon: Icon(Icons.warning)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildLowStockTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewProduct,
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        _buildInventorySummary(),
        _buildQuickFilters(),
        Expanded(child: _buildProductsList()),
      ],
    );
  }

  Widget _buildInventorySummary() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Products',
                  '156',
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'In Stock',
                  '142',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Low Stock',
                  '8',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Out of Stock',
                  '6',
                  Icons.error,
                  Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', 'all', 156),
          _buildFilterChip('In Stock', 'in_stock', 142),
          _buildFilterChip('Low Stock', 'low_stock', 8),
          _buildFilterChip('Out of Stock', 'out_of_stock', 6),
          _buildFilterChip('Recently Added', 'recent', 12),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    
    return Container(
      margin: const EdgeInsets.only(right: AppConstants.spacingS),
      child: FilterChip(
        selected: isSelected,
        label: Text('$label ($count)'),
        onSelected: (selected) {
          setState(() => _selectedFilter = selected ? value : 'all');
        },
      ),
    );
  }

  Widget _buildProductsList() {
    // Mock inventory data
    final mockInventory = List.generate(20, (index) {
      return InventoryItem(
        id: 'item_$index',
        productName: 'Product ${index + 1}',
        sku: 'SKU${(1000 + index).toString()}',
        category: MockProducts.trendingProducts[index % MockProducts.trendingProducts.length].category,
        currentStock: 25 - (index % 30),
        minStock: 5,
        maxStock: 100,
        cost: 25.0 + (index * 5),
        price: 50.0 + (index * 10),
        lastUpdated: DateTime.now().subtract(Duration(days: index % 7)),
        status: (25 - (index % 30)) <= 5 
            ? InventoryStatus.lowStock 
            : (25 - (index % 30)) <= 0 
                ? InventoryStatus.outOfStock 
                : InventoryStatus.inStock,
      );
    });

    // Filter based on selected filter
    final filteredItems = mockInventory.where((item) {
      switch (_selectedFilter) {
        case 'in_stock':
          return item.status == InventoryStatus.inStock;
        case 'low_stock':
          return item.status == InventoryStatus.lowStock;
        case 'out_of_stock':
          return item.status == InventoryStatus.outOfStock;
        case 'recent':
          return item.lastUpdated.isAfter(DateTime.now().subtract(const Duration(days: 7)));
        default:
          return true;
      }
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: _buildInventoryCard(item),
        );
      },
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, size: 32),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'SKU: ${item.sku}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Category: ${item.category}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.status.displayName,
                    style: TextStyle(
                      color: item.status.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn('Current Stock', '${item.currentStock}'),
                ),
                Expanded(
                  child: _buildInfoColumn('Min Stock', '${item.minStock}'),
                ),
                Expanded(
                  child: _buildInfoColumn('Cost', '\$${item.cost.toStringAsFixed(2)}'),
                ),
                Expanded(
                  child: _buildInfoColumn('Price', '\$${item.price.toStringAsFixed(2)}'),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Stock level indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Level',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${((item.currentStock / item.maxStock) * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: item.currentStock / item.maxStock,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(item.status.color),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            Row(
              children: [
                Text(
                  'Last updated: ${_formatDate(item.lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _updateStock(item),
                  child: const Text('Update Stock'),
                ),
                TextButton(
                  onPressed: () => _editProduct(item),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassmorphicContainer.card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 28),
                      const SizedBox(width: AppConstants.spacingM),
                      Text(
                        'Low Stock Alert',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'These products are running low on stock and need immediate attention.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Low stock items list
          ...List.generate(8, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
              child: GlassmorphicContainer.card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppConstants.spacingM),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning, color: Colors.orange),
                  ),
                  title: Text('Product ${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current stock: ${5 - index % 6}'),
                      const Text('Minimum required: 5'),
                      LinearProgressIndicator(
                        value: (5 - index % 6) / 5,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _restockProduct(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Restock'),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Analytics cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Inventory Value',
                  '\$45,678',
                  Icons.attach_money,
                  Colors.green,
                  '+12%',
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildAnalyticsCard(
                  'Turnover Rate',
                  '8.2x',
                  Icons.sync,
                  Colors.blue,
                  '+0.5x',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Avg Days to Sell',
                  '12 days',
                  Icons.schedule,
                  Colors.purple,
                  '-2 days',
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildAnalyticsCard(
                  'Stockout Rate',
                  '3.8%',
                  Icons.trending_down,
                  Colors.orange,
                  '-1.2%',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          // Top performing products
          GlassmorphicContainer.card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Performing Products',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  
                  ...List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.green.withOpacity(0.1),
                            child: Text('${index + 1}'),
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Product ${index + 1}'),
                                Text(
                                  'Sold: ${50 - index * 8} units',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${(1000 - index * 150).toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Inventory'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter product name or SKU',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            // Add filter options here
            const Text('Filter options would be implemented here'),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exporting inventory...')),
        );
        break;
      case 'import':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening import wizard...')),
        );
        break;
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening inventory settings...')),
        );
        break;
    }
  }

  void _addNewProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening product creation...')),
    );
  }

  void _updateStock(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => _StockUpdateDialog(item: item),
    );
  }

  void _editProduct(InventoryItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${item.productName}...')),
    );
  }

  void _restockProduct(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restocking Product ${index + 1}...')),
    );
  }
}

/// Stock update dialog
class _StockUpdateDialog extends StatefulWidget {
  final InventoryItem item;

  const _StockUpdateDialog({required this.item});

  @override
  State<_StockUpdateDialog> createState() => _StockUpdateDialogState();
}

class _StockUpdateDialogState extends State<_StockUpdateDialog> {
  final _stockController = TextEditingController();
  final _reasonController = TextEditingController();
  String _updateType = 'add';

  @override
  void initState() {
    super.initState();
    _stockController.text = widget.item.currentStock.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Stock - ${widget.item.productName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Add'),
                  value: 'add',
                  groupValue: _updateType,
                  onChanged: (value) => setState(() => _updateType = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Set'),
                  value: 'set',
                  groupValue: _updateType,
                  onChanged: (value) => setState(() => _updateType = value!),
                ),
              ),
            ],
          ),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _updateType == 'add' ? 'Quantity to Add' : 'New Stock Level',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stock updated successfully')),
            );
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

/// Inventory item model
class InventoryItem {
  final String id;
  final String productName;
  final String sku;
  final String category;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final double cost;
  final double price;
  final DateTime lastUpdated;
  final InventoryStatus status;

  const InventoryItem({
    required this.id,
    required this.productName,
    required this.sku,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.cost,
    required this.price,
    required this.lastUpdated,
    required this.status,
  });
}

/// Inventory status enum
enum InventoryStatus {
  inStock('In Stock', Colors.green),
  lowStock('Low Stock', Colors.orange),
  outOfStock('Out of Stock', Colors.red);

  const InventoryStatus(this.displayName, this.color);
  final String displayName;
  final Color color;
}