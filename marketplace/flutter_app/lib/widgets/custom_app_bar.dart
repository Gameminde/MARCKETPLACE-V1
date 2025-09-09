import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../core/config/app_constants.dart';
import 'glassmorphic_container.dart';

/// Comprehensive custom app bar widget with glassmorphic design,
/// search functionality, notifications, and various styles
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool enableGlassmorphism;
  final AppBarStyle style;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onMenuTap;
  final bool hasNotifications;
  final bool hasChatMessages;
  final int notificationCount;
  final int chatCount;
  final double? elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final bool enableSearch;
  final String? searchHint;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final bool showBackButton;
  final bool showMenuButton;
  final SystemUiOverlayStyle? systemOverlayStyle;
  
  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.enableGlassmorphism = true,
    this.style = AppBarStyle.elevated,
    this.onSearchTap,
    this.onNotificationTap,
    this.onChatTap,
    this.onMenuTap,
    this.hasNotifications = false,
    this.hasChatMessages = false,
    this.notificationCount = 0,
    this.chatCount = 0,
    this.elevation,
    this.backgroundColor,
    this.bottom,
    this.enableSearch = false,
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.showBackButton = false,
    this.showMenuButton = false,
    this.systemOverlayStyle,
  });

  /// Factory constructor for home app bar
  factory CustomAppBar.home({
    Key? key,
    VoidCallback? onSearchTap,
    VoidCallback? onNotificationTap,
    VoidCallback? onChatTap,
    VoidCallback? onMenuTap,
    bool hasNotifications = false,
    bool hasChatMessages = false,
    int notificationCount = 0,
    int chatCount = 0,
  }) {
    return CustomAppBar(
      key: key,
      style: AppBarStyle.home,
      onSearchTap: onSearchTap,
      onNotificationTap: onNotificationTap,
      onChatTap: onChatTap,
      onMenuTap: onMenuTap,
      hasNotifications: hasNotifications,
      hasChatMessages: hasChatMessages,
      notificationCount: notificationCount,
      chatCount: chatCount,
      showMenuButton: true,
    );
  }

  /// Factory constructor for search app bar
  factory CustomAppBar.search({
    Key? key,
    String? searchHint,
    TextEditingController? searchController,
    Function(String)? onSearchChanged,
    VoidCallback? onNotificationTap,
    VoidCallback? onChatTap,
    bool hasNotifications = false,
    bool hasChatMessages = false,
  }) {
    return CustomAppBar(
      key: key,
      style: AppBarStyle.search,
      enableSearch: true,
      searchHint: searchHint,
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      onNotificationTap: onNotificationTap,
      onChatTap: onChatTap,
      hasNotifications: hasNotifications,
      hasChatMessages: hasChatMessages,
      showBackButton: true,
    );
  }

  /// Factory constructor for detail app bar
  factory CustomAppBar.detail({
    Key? key,
    String? title,
    List<Widget>? actions,
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBar(
      key: key,
      title: title,
      actions: actions,
      style: AppBarStyle.detail,
      showBackButton: true,
    );
  }

  /// Factory constructor for transparent overlay app bar
  factory CustomAppBar.overlay({
    Key? key,
    List<Widget>? actions,
    Widget? leading,
  }) {
    return CustomAppBar(
      key: key,
      style: AppBarStyle.overlay,
      actions: actions,
      leading: leading,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Set system overlay style
    SystemChrome.setSystemUIOverlayStyle(
      systemOverlayStyle ?? _getSystemOverlayStyle(isDark),
    );
    
    switch (style) {
      case AppBarStyle.home:
        return _buildHomeAppBar(context, theme, isDark);
      case AppBarStyle.search:
        return _buildSearchAppBar(context, theme, isDark);
      case AppBarStyle.detail:
        return _buildDetailAppBar(context, theme, isDark);
      case AppBarStyle.overlay:
        return _buildOverlayAppBar(context, theme, isDark);
      case AppBarStyle.elevated:
      default:
        return _buildElevatedAppBar(context, theme, isDark);
    }
  }

  Widget _buildHomeAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return SizedBox(
      height: preferredSize.height,
      child: enableGlassmorphism
          ? GlassmorphicContainer.navigation(
              child: _buildHomeContent(context, theme, isDark),
            )
          : Container(
              color: backgroundColor ?? theme.appBarTheme.backgroundColor,
              child: _buildHomeContent(context, theme, isDark),
            ),
    );
  }

  Widget _buildHomeContent(BuildContext context, ThemeData theme, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Menu/Logo section
            if (showMenuButton)
              _buildIconButton(
                Icons.menu_rounded,
                onMenuTap,
                context,
                tooltip: 'Menu',
              )
            else
              _buildLogo(context),
            
            // Actions section
            Row(
              children: [
                if (onSearchTap != null)
                  _buildIconButton(
                    Icons.search_rounded,
                    onSearchTap,
                    context,
                    tooltip: 'Search',
                  ),
                const SizedBox(width: AppConstants.spacingS),
                if (onNotificationTap != null)
                  _buildNotificationButton(context),
                const SizedBox(width: AppConstants.spacingS),
                if (onChatTap != null)
                  _buildChatButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: enableGlassmorphism ? Colors.transparent : backgroundColor,
      elevation: elevation ?? 0,
      leading: showBackButton ? const BackButton() : leading,
      title: enableSearch ? _buildSearchField(context, theme) : _buildTitle(context, theme),
      actions: _buildActions(context),
      centerTitle: centerTitle,
      systemOverlayStyle: systemOverlayStyle ?? _getSystemOverlayStyle(isDark),
      flexibleSpace: enableGlassmorphism ? _buildGlassBackground() : null,
      bottom: bottom,
    );
  }

  Widget _buildDetailAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: enableGlassmorphism ? Colors.transparent : backgroundColor,
      elevation: elevation ?? 0,
      leading: showBackButton ? const BackButton() : leading,
      title: _buildTitle(context, theme),
      actions: actions,
      centerTitle: centerTitle,
      systemOverlayStyle: systemOverlayStyle ?? _getSystemOverlayStyle(isDark),
      flexibleSpace: enableGlassmorphism ? _buildGlassBackground() : null,
      bottom: bottom,
    );
  }

  Widget _buildOverlayAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return SizedBox(
      height: preferredSize.height,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              leading ?? const SizedBox(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: enableGlassmorphism ? Colors.transparent : backgroundColor,
      elevation: elevation ?? (enableGlassmorphism ? 0 : 4),
      leading: showBackButton ? const BackButton() : leading,
      title: _buildTitle(context, theme),
      actions: _buildActions(context),
      centerTitle: centerTitle,
      systemOverlayStyle: systemOverlayStyle ?? _getSystemOverlayStyle(isDark),
      flexibleSpace: enableGlassmorphism ? _buildGlassBackground() : null,
      bottom: bottom,
    );
  }

  Widget _buildGlassBackground() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppConstants.glassBlurRadius,
          sigmaY: AppConstants.glassBlurRadius,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(AppConstants.glassOpacity),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(AppConstants.glassBorderOpacity),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, ThemeData theme) {
    if (titleWidget != null) return titleWidget!;
    if (title == null) return const SizedBox();
    
    return Text(
      title!,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.appBarTheme.foregroundColor,
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, ThemeData theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: searchHint ?? 'Search products...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actionsList = <Widget>[];
    
    if (onNotificationTap != null) {
      actionsList.add(_buildNotificationButton(context));
    }
    
    if (onChatTap != null) {
      actionsList.add(_buildChatButton(context));
    }
    
    if (actions != null) {
      actionsList.addAll(actions!);
    }
    
    return actionsList;
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      child: Text(
        'Marketplace',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback? onTap,
    BuildContext context, {
    String? tooltip,
  }) {
    return GlassmorphicContainer.button(
      onTap: onTap ?? () {},
      padding: const EdgeInsets.all(AppConstants.spacingS),
      child: Icon(
        icon,
        size: AppConstants.iconSizeM,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: onNotificationTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppConstants.iconSizeM),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              size: AppConstants.iconSizeM,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            if (hasNotifications || notificationCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: notificationCount > 0
                        ? Text(
                            notificationCount > 99 ? '99+' : notificationCount.toString(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onError,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton(BuildContext context) {
    return GestureDetector(
      onTap: onChatTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppConstants.iconSizeM),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Stack(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: AppConstants.iconSizeM,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            if (hasChatMessages || chatCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: chatCount > 0
                        ? Text(
                            chatCount > 99 ? '99+' : chatCount.toString(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SystemUiOverlayStyle _getSystemOverlayStyle(bool isDark) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Size get preferredSize {
    final baseHeight = style == AppBarStyle.home ? 80.0 : kToolbarHeight;
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(baseHeight + bottomHeight);
  }
}

/// App bar styles
enum AppBarStyle {
  elevated,
  home,
  search,
  detail,
  overlay,
}