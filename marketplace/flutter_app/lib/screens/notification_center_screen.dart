import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../widgets/glassmorphic_container.dart';

/// Notification center screen
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  NotificationType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchBar,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_chat_read),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear all'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.notifications)),
            Tab(text: 'Unread', icon: Icon(Icons.notifications_active)),
            Tab(text: 'Recent', icon: Icon(Icons.schedule)),
          ],
        ),
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (!notificationService.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationService.errorMessage != null) {
            return _buildErrorState(notificationService.errorMessage!);
          }

          return Column(
            children: [
              if (_selectedType != null) _buildFilterChip(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList(notificationService.notifications),
                    _buildNotificationList(notificationService.unreadNotifications),
                    _buildNotificationList(notificationService.recentNotifications),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          ElevatedButton(
            onPressed: _initializeNotifications,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          FilterChip(
            avatar: Icon(_selectedType!.icon, size: 16),
            label: Text(_selectedType!.displayName),
            selected: true,
            onSelected: (_) => setState(() => _selectedType = null),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => _selectedType = null),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    // Apply search filter
    List<NotificationModel> filteredNotifications = notifications;
    
    if (_searchQuery.isNotEmpty) {
      filteredNotifications = NotificationService.instance.searchNotifications(_searchQuery);
    }
    
    // Apply type filter
    if (_selectedType != null) {
      filteredNotifications = filteredNotifications
          .where((n) => n.type == _selectedType)
          .toList();
    }

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
            child: NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onDismiss: () => _dismissNotification(notification),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      await NotificationService.instance.markAsRead(notification.id);
    }

    // Handle action
    if (notification.hasAction && notification.actionUrl != null) {
      // In a real app, navigate to the action URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to: ${notification.actionUrl}'),
        ),
      );
    }
  }

  void _dismissNotification(NotificationModel notification) async {
    await NotificationService.instance.deleteNotification(notification.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification dismissed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // In a real app, restore the notification
            },
          ),
        ),
      );
    }
  }

  Future<void> _refreshNotifications() async {
    // In a real app, this would refresh from API
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showSearchBar() {
    showSearch(
      context: context,
      delegate: NotificationSearchDelegate(),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Wrap(
              spacing: AppConstants.spacingS,
              runSpacing: AppConstants.spacingS,
              children: NotificationType.values.map((type) {
                return FilterChip(
                  avatar: Icon(type.icon, size: 16),
                  label: Text(type.displayName),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = selected ? type : null;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _selectedType = null);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear Filter'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        NotificationService.instance.markAllAsRead();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'settings':
        _showNotificationSettings();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationService.instance.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }
}

/// Individual notification card widget
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.spacingL),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      child: GlassmorphicContainer.card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppConstants.spacingM),
          leading: _buildLeading(context),
          title: Text(
            notification.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    notification.type.icon,
                    size: 14,
                    color: notification.type.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notification.type.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: notification.type.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    notification.timeAgo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (notification.hasAction) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: notification.type.color,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 32),
                  ),
                  child: Text(notification.actionLabel!),
                ),
              ],
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: notification.hasAction ? null : onTap,
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (notification.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          notification.imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildIconLeading(context),
        ),
      );
    }
    
    return _buildIconLeading(context);
  }

  Widget _buildIconLeading(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: notification.type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        notification.type.icon,
        color: notification.type.color,
        size: 24,
      ),
    );
  }
}

/// Notification settings screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late NotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = NotificationService.instance.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSettings(),
            const SizedBox(height: AppConstants.spacingL),
            _buildTypeSettings(),
            const SizedBox(height: AppConstants.spacingL),
            _buildQuietHoursSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on this device'),
              value: _settings.pushEnabled,
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(pushEnabled: value);
              }),
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: _settings.emailEnabled,
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(emailEnabled: value);
              }),
            ),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Receive notifications via SMS'),
              value: _settings.smsEnabled,
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(smsEnabled: value);
              }),
            ),
            SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text('Play sound for notifications'),
              value: _settings.soundEnabled,
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(soundEnabled: value);
              }),
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate for notifications'),
              value: _settings.vibrationEnabled,
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(vibrationEnabled: value);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSettings() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ...NotificationType.values.map((type) {
              return SwitchListTile(
                title: Row(
                  children: [
                    Icon(type.icon, size: 20, color: type.color),
                    const SizedBox(width: 8),
                    Text(type.displayName),
                  ],
                ),
                value: _settings.isTypeEnabled(type),
                onChanged: (value) => setState(() {
                  final newTypeSettings = Map<NotificationType, bool>.from(_settings.typeSettings);
                  newTypeSettings[type] = value;
                  _settings = _settings.copyWith(typeSettings: newTypeSettings);
                }),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSettings() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiet Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Mute non-urgent notifications during these hours',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(_settings.quietHoursStart ?? 'Not set'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(_settings.quietHoursEnd ?? 'Not set'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectTime(bool isStart) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _settings = _settings.copyWith(quietHoursStart: timeString);
        } else {
          _settings = _settings.copyWith(quietHoursEnd: timeString);
        }
      });
    }
  }

  void _saveSettings() async {
    await NotificationService.instance.updateSettings(_settings);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }
}

/// Search delegate for notifications
class NotificationSearchDelegate extends SearchDelegate<NotificationModel?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentNotifications(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = NotificationService.instance.searchNotifications(query);
    
    if (results.isEmpty) {
      return const Center(
        child: Text('No notifications found'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final notification = results[index];
        return ListTile(
          title: Text(notification.title),
          subtitle: Text(notification.body),
          leading: Icon(notification.type.icon, color: notification.type.color),
          trailing: Text(notification.timeAgo),
          onTap: () => close(context, notification),
        );
      },
    );
  }

  Widget _buildRecentNotifications(BuildContext context) {
    final recent = NotificationService.instance.recentNotifications;

    return ListView.builder(
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final notification = recent[index];
        return ListTile(
          title: Text(notification.title),
          subtitle: Text(notification.body),
          leading: Icon(notification.type.icon, color: notification.type.color),
          trailing: Text(notification.timeAgo),
          onTap: () {
            query = notification.title;
            showResults(context);
          },
        );
      },
    );
  }
}
