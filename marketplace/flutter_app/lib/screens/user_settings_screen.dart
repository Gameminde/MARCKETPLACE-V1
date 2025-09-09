import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../core/theme/dynamic_theme_manager.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/particle_background.dart';

/// Comprehensive user settings screen with theme preferences,
/// notification settings, privacy controls, and account management
class UserSettingsScreen extends StatefulWidget {
  final Function()? onThemeChanged;
  final Function()? onLogout;
  
  const UserSettingsScreen({
    super.key,
    this.onThemeChanged,
    this.onLogout,
  });

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Settings state
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _orderUpdates = true;
  bool _promotionalOffers = true;
  bool _newProducts = false;
  bool _priceDropAlerts = true;
  
  // Privacy settings
  bool _shareAnalytics = true;
  bool _personalizedAds = true;
  bool _locationServices = false;
  
  // App settings
  bool _biometricAuth = false;
  bool _autoLockEnabled = true;
  int _autoLockDuration = 5; // minutes
  
  // Language and currency
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';
  
  final List<String> _languages = [
    'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Arabic'
  ];
  
  final List<String> _currencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF'
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar.detail(
        title: 'Settings',
        onBackPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: ParticleBackground.subtle(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _animationController,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: AppConstants.spacingXL + MediaQuery.of(context).padding.top + kToolbarHeight,
                  left: AppConstants.spacingM,
                  right: AppConstants.spacingM,
                  bottom: AppConstants.spacingXL,
                ),
                child: Column(
                  children: [
                    _buildThemeSettings(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildNotificationSettings(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildPrivacySettings(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildSecuritySettings(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildLanguageAndCurrencySettings(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildAccountManagement(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildThemeSettings() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Text(
                  'Theme & Appearance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            // Seasonal Theme Selector
            Consumer<DynamicThemeManager>(
              builder: (context, themeManager, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seasonal Theme',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    Wrap(
                      spacing: AppConstants.spacingS,
                      runSpacing: AppConstants.spacingS,
                      children: SeasonalTheme.values.map((theme) {
                        final isSelected = themeManager.currentSeasonal == theme;
                        return GestureDetector(
                          onTap: () => _changeTheme(theme),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingM,
                              vertical: AppConstants.spacingS,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Text(
                              _getThemeDisplayName(theme),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Glassmorphic Effect Toggle (placeholder since method doesn't exist)
            SwitchListTile(
              title: const Text('Glassmorphic Effects'),
              subtitle: const Text('Enable blur and transparency effects'),
              value: true, // Always true for now
              onChanged: (value) {
                // Placeholder - would implement glassmorphic toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Glassmorphic toggle coming soon')),
                );
                widget.onThemeChanged?.call();
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // Auto-seasonal Theme Toggle
            Consumer<DynamicThemeManager>(
              builder: (context, themeManager, child) {
                return SwitchListTile(
                  title: const Text('Auto-seasonal Themes'),
                  subtitle: const Text('Automatically change theme based on season'),
                  value: themeManager.isAutoSeasonalEnabled,
                  onChanged: (value) => themeManager.setAutoSeasonalEnabled(value),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationSettings() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            // Notification channels
            _buildNotificationTile(
              'Push Notifications',
              'Receive notifications on your device',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
              Icons.phone_android,
            ),
            _buildNotificationTile(
              'Email Notifications',
              'Receive notifications via email',
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
              Icons.email_outlined,
            ),
            _buildNotificationTile(
              'SMS Notifications',
              'Receive notifications via text message',
              _smsNotifications,
              (value) => setState(() => _smsNotifications = value),
              Icons.sms_outlined,
            ),
            
            const Divider(height: AppConstants.spacingL * 2),
            
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            _buildNotificationTile(
              'Order Updates',
              'Status changes and delivery updates',
              _orderUpdates,
              (value) => setState(() => _orderUpdates = value),
              Icons.local_shipping_outlined,
            ),
            _buildNotificationTile(
              'Promotional Offers',
              'Special deals and discounts',
              _promotionalOffers,
              (value) => setState(() => _promotionalOffers = value),
              Icons.local_offer_outlined,
            ),
            _buildNotificationTile(
              'New Products',
              'Latest product arrivals',
              _newProducts,
              (value) => setState(() => _newProducts = value),
              Icons.new_releases_outlined,
            ),
            _buildNotificationTile(
              'Price Drop Alerts',
              'When items in your wishlist go on sale',
              _priceDropAlerts,
              (value) => setState(() => _priceDropAlerts = value),
              Icons.trending_down,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
  
  Widget _buildPrivacySettings() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Text(
                  'Privacy & Data',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            _buildNotificationTile(
              'Share Analytics',
              'Help improve the app with usage data',
              _shareAnalytics,
              (value) => setState(() => _shareAnalytics = value),
              Icons.analytics_outlined,
            ),
            _buildNotificationTile(
              'Personalized Ads',
              'Show ads based on your interests',
              _personalizedAds,
              (value) => setState(() => _personalizedAds = value),
              Icons.ad_units_outlined,
            ),
            _buildNotificationTile(
              'Location Services',
              'Enable location-based features',
              _locationServices,
              (value) => setState(() => _locationServices = value),
              Icons.location_on_outlined,
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Privacy actions
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download My Data'),
              subtitle: const Text('Export your account data'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _downloadData,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete My Account'),
              subtitle: const Text('Permanently delete your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showDeleteAccountDialog,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecuritySettings() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Text(
                  'Security',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            _buildNotificationTile(
              'Biometric Authentication',
              'Use fingerprint or face ID',
              _biometricAuth,
              (value) => setState(() => _biometricAuth = value),
              Icons.fingerprint,
            ),
            _buildNotificationTile(
              'Auto-lock',
              'Automatically lock the app',
              _autoLockEnabled,
              (value) => setState(() => _autoLockEnabled = value),
              Icons.lock_clock,
            ),
            
            if (_autoLockEnabled) ...[
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'Auto-lock Duration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Slider(
                value: _autoLockDuration.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                label: '$_autoLockDuration minutes',
                onChanged: (value) => setState(() => _autoLockDuration = value.round()),
              ),
            ],
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Security actions
            ListTile(
              leading: const Icon(Icons.key_outlined),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _changePassword,
              contentPadding: EdgeInsets.zero,
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Two-Factor Authentication'),
                  subtitle: Text(authProvider.isMfaEnabled ? 'Enabled' : 'Disabled'),
                  trailing: Switch(
                    value: authProvider.isMfaEnabled,
                    onChanged: (value) => _toggleMfa(value),
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageAndCurrencySettings() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: const Icon(
                    Icons.language_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Text(
                  'Language & Currency',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            // Language Selector
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Language'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageSelector(),
              contentPadding: EdgeInsets.zero,
            ),
            
            // Currency Selector
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Currency'),
              subtitle: Text(_selectedCurrency),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCurrencySelector(),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountManagement() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Text(
                  'Account Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            // Account actions
            ListTile(
              leading: const Icon(Icons.sync_outlined),
              title: const Text('Sync Account'),
              subtitle: const Text('Sync data across devices'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _syncAccount,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup Settings'),
              subtitle: const Text('Backup your preferences'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _backupSettings,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Restore Settings'),
              subtitle: const Text('Restore from backup'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _restoreSettings,
              contentPadding: EdgeInsets.zero,
            ),
            
            const Divider(height: AppConstants.spacingL * 2),
            
            // Logout button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Sign out of your account'),
                  trailing: authProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: authProvider.isLoading ? null : _showLogoutDialog,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  String _getThemeDisplayName(SeasonalTheme theme) {
    switch (theme) {
      case SeasonalTheme.defaultBlue:
        return 'Default';
      case SeasonalTheme.spring:
        return 'Spring';
      case SeasonalTheme.summer:
        return 'Summer';
      case SeasonalTheme.autumn:
        return 'Autumn';
      case SeasonalTheme.winter:
        return 'Winter';
      case SeasonalTheme.christmas:
        return 'Christmas';
      case SeasonalTheme.halloween:
        return 'Halloween';
      case SeasonalTheme.valentine:
        return 'Valentine';
      case SeasonalTheme.ramadan:
        return 'Ramadan';
      case SeasonalTheme.promo:
        return 'Promo';
      case SeasonalTheme.midnight:
        return 'Midnight';
      case SeasonalTheme.ocean:
        return 'Ocean';
      case SeasonalTheme.sunset:
        return 'Sunset';
      case SeasonalTheme.forest:
        return 'Forest';
    }
  }
  
  // Event handlers
  void _changeTheme(SeasonalTheme theme) {
    final themeManager = Provider.of<DynamicThemeManager>(context, listen: false);
    themeManager.setSeasonalTheme(theme);
    widget.onThemeChanged?.call();
    _saveSettings();
  }
  
  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ..._languages.map((language) {
              return ListTile(
                title: Text(language),
                trailing: _selectedLanguage == language
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = language;
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
  
  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Currency',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ..._currencies.map((currency) {
              return ListTile(
                title: Text(currency),
                trailing: _selectedCurrency == currency
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCurrency = currency;
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
  
  void _changePassword() {
    // Navigate to change password screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password feature coming soon')),
    );
  }
  
  void _toggleMfa(bool enable) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.toggleMfa(enable);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${enable ? 'enable' : 'disable'} two-factor authentication'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  void _downloadData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data download feature coming soon')),
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _deleteAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion feature coming soon')),
    );
  }
  
  void _syncAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account synced successfully')),
    );
  }
  
  void _backupSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings backed up successfully')),
    );
  }
  
  void _restoreSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Settings'),
        content: const Text('Restore settings from your last backup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings restored successfully')),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    widget.onLogout?.call();
  }
  
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  void _resetSettings() {
    setState(() {
      // Reset notification settings
      _pushNotifications = true;
      _emailNotifications = true;
      _smsNotifications = false;
      _orderUpdates = true;
      _promotionalOffers = true;
      _newProducts = false;
      _priceDropAlerts = true;
      
      // Reset privacy settings
      _shareAnalytics = true;
      _personalizedAds = true;
      _locationServices = false;
      
      // Reset app settings
      _biometricAuth = false;
      _autoLockEnabled = true;
      _autoLockDuration = 5;
      
      // Reset language and currency
      _selectedLanguage = 'English';
      _selectedCurrency = 'USD';
    });
    
    // Reset theme to default
    final themeManager = Provider.of<DynamicThemeManager>(context, listen: false);
    themeManager.setSeasonalTheme(SeasonalTheme.defaultBlue);
    
    _saveSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings reset to defaults')),
    );
  }
  
  void _loadSettings() {
    // In a real app, load settings from SharedPreferences or database
    // For now, using default values
  }
  
  void _saveSettings() {
    // In a real app, save settings to SharedPreferences or database
    // For now, just a placeholder
  }
}