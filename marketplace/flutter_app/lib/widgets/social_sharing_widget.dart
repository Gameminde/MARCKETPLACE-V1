import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_constants.dart';
import '../services/xp_system.dart';
import '../widgets/glassmorphic_container.dart';
import '../models/product.dart';

/// Social platform enumeration
enum SocialPlatform {
  facebook('Facebook', Icons.facebook, Color(0xFF1877F2)),
  twitter('Twitter', Icons.chat, Color(0xFF1DA1F2)),
  instagram('Instagram', Icons.camera_alt, Color(0xFFE4405F)),
  whatsapp('WhatsApp', Icons.message, Color(0xFF25D366)),
  telegram('Telegram', Icons.send, Color(0xFF0088CC)),
  linkedin('LinkedIn', Icons.work, Color(0xFF0077B5)),
  pinterest('Pinterest', Icons.push_pin, Color(0xFFBD081C)),
  reddit('Reddit', Icons.forum, Color(0xFFFF4500)),
  copyLink('Copy Link', Icons.link, Colors.grey),
  email('Email', Icons.email, Colors.blue),
  sms('SMS', Icons.sms, Colors.green);

  const SocialPlatform(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

/// Share content model
class ShareContent {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final Map<String, String> customData;

  const ShareContent({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    this.customData = const {},
  });

  /// Create share content for a product
  factory ShareContent.fromProduct(Product product, {String? customMessage}) {
    const baseUrl = 'https://marketplace.app/product';
    final url = '$baseUrl/${product.id}';
    
    String description = customMessage ?? 
        'Check out this amazing product: ${product.name}';
    
    if (product.isOnSale && product.discountPercentage != null) {
      description += ' - ${product.discountPercentage!.toStringAsFixed(0)}% OFF!';
    }
    
    return ShareContent(
      title: product.name,
      description: description,
      url: url,
      imageUrl: product.images.isNotEmpty ? product.images.first : null,
      customData: {
        'price': '\$${product.price.toStringAsFixed(2)}',
        'rating': product.rating.toStringAsFixed(1),
        'category': product.category,
      },
    );
  }

  /// Create share content for general content
  factory ShareContent.custom({
    required String title,
    required String description,
    required String url,
    String? imageUrl,
    Map<String, String>? customData,
  }) {
    return ShareContent(
      title: title,
      description: description,
      url: url,
      imageUrl: imageUrl,
      customData: customData ?? {},
    );
  }

  /// Generate platform-specific share text
  String getShareText(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.twitter:
        // Twitter has character limits, so keep it concise
        String text = '$title\n$description';
        if (text.length > 240) {
          text = '${text.substring(0, 237)}...';
        }
        return '$text\n$url';
        
      case SocialPlatform.whatsapp:
      case SocialPlatform.telegram:
        return '*$title*\n\n$description\n\n$url';
        
      case SocialPlatform.linkedin:
        return '$title\n\n$description\n\nLearn more: $url';
        
      case SocialPlatform.email:
        return 'Subject: $title\n\nHi,\n\n$description\n\nCheck it out here: $url\n\nBest regards';
        
      case SocialPlatform.sms:
        return '$title - $description\nLink: $url';
        
      default:
        return '$title\n\n$description\n\n$url';
    }
  }

  /// Generate hashtags based on content
  List<String> generateHashtags() {
    final hashtags = <String>[];
    
    // Add category-based hashtags
    if (customData.containsKey('category')) {
      hashtags.add('#${customData['category']!.replaceAll(' ', '')}');
    }
    
    // Add generic hashtags
    hashtags.addAll(['#shopping', '#marketplace', '#deals']);
    
    // Add discount hashtag if applicable
    if (title.toLowerCase().contains('off') || description.toLowerCase().contains('off')) {
      hashtags.add('#sale');
    }
    
    return hashtags;
  }
}

/// Social sharing service
class SocialSharingService {
  static SocialSharingService? _instance;
  static SocialSharingService get instance => _instance ??= SocialSharingService._internal();
  
  SocialSharingService._internal();

  /// Share content to specified platform
  Future<bool> shareContent(SocialPlatform platform, ShareContent content) async {
    try {
      switch (platform) {
        case SocialPlatform.copyLink:
          return await _copyToClipboard(content.url);
          
        case SocialPlatform.email:
          return await _shareViaEmail(content);
          
        case SocialPlatform.sms:
          return await _shareViaSMS(content);
          
        default:
          return await _shareToSocialPlatform(platform, content);
      }
    } catch (e) {
      debugPrint('Error sharing content: $e');
      return false;
    }
  }

  /// Copy content to clipboard
  Future<bool> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      return false;
    }
  }

  /// Share via email (mock implementation)
  Future<bool> _shareViaEmail(ShareContent content) async {
    // In a real app, this would use url_launcher to open email client
    debugPrint('Sharing via email: ${content.getShareText(SocialPlatform.email)}');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Share via SMS (mock implementation)
  Future<bool> _shareViaSMS(ShareContent content) async {
    // In a real app, this would use url_launcher to open SMS app
    debugPrint('Sharing via SMS: ${content.getShareText(SocialPlatform.sms)}');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Share to social platform (mock implementation)
  Future<bool> _shareToSocialPlatform(SocialPlatform platform, ShareContent content) async {
    // In a real app, this would use platform-specific sharing APIs or url_launcher
    debugPrint('Sharing to ${platform.displayName}: ${content.getShareText(platform)}');
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

/// Comprehensive social sharing widget
class SocialSharingWidget extends StatefulWidget {
  final ShareContent content;
  final List<SocialPlatform> platforms;
  final bool showTitle;
  final String? customTitle;
  final Widget? customHeader;
  final VoidCallback? onShareComplete;
  final bool compact;

  const SocialSharingWidget({
    super.key,
    required this.content,
    this.platforms = const [
      SocialPlatform.facebook,
      SocialPlatform.twitter,
      SocialPlatform.whatsapp,
      SocialPlatform.instagram,
      SocialPlatform.copyLink,
    ],
    this.showTitle = true,
    this.customTitle,
    this.customHeader,
    this.onShareComplete,
    this.compact = false,
  });

  @override
  State<SocialSharingWidget> createState() => _SocialSharingWidgetState();
}

class _SocialSharingWidgetState extends State<SocialSharingWidget> {
  final Map<SocialPlatform, bool> _sharingStates = {};

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactWidget();
    }
    
    return _buildFullWidget();
  }

  Widget _buildCompactWidget() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            Icon(
              Icons.share,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              'Share',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            ...widget.platforms.take(3).map((platform) => 
              Padding(
                padding: const EdgeInsets.only(left: AppConstants.spacingS),
                child: _buildPlatformButton(platform, compact: true),
              ),
            ),
            if (widget.platforms.length > 3) ...[
              const SizedBox(width: AppConstants.spacingS),
              GestureDetector(
                onTap: () => _showFullSharingSheet(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_horiz, size: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidget() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (widget.customHeader != null)
              widget.customHeader!
            else if (widget.showTitle) ...[
              Row(
                children: [
                  Icon(
                    Icons.share,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Text(
                    widget.customTitle ?? 'Share this product',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingL),
            ],
            
            // Content preview
            _buildContentPreview(),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Platform buttons
            _buildPlatformGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPreview() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.content.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            widget.content.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Custom data chips
          if (widget.content.customData.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingM),
            Wrap(
              spacing: AppConstants.spacingS,
              children: widget.content.customData.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppConstants.spacingM,
        mainAxisSpacing: AppConstants.spacingM,
        childAspectRatio: 1,
      ),
      itemCount: widget.platforms.length,
      itemBuilder: (context, index) {
        final platform = widget.platforms[index];
        return _buildPlatformButton(platform);
      },
    );
  }

  Widget _buildPlatformButton(SocialPlatform platform, {bool compact = false}) {
    final isSharing = _sharingStates[platform] ?? false;
    final size = compact ? 32.0 : 56.0;
    final iconSize = compact ? 16.0 : 24.0;

    return GestureDetector(
      onTap: isSharing ? null : () => _shareContent(platform),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: platform.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(compact ? 8 : AppConstants.borderRadius),
          border: Border.all(
            color: platform.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: isSharing
            ? Center(
                child: SizedBox(
                  width: iconSize * 0.8,
                  height: iconSize * 0.8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(platform.color),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    platform.icon,
                    color: platform.color,
                    size: iconSize,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      platform.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: platform.color,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _shareContent(SocialPlatform platform) async {
    setState(() {
      _sharingStates[platform] = true;
    });

    try {
      final success = await SocialSharingService.instance.shareContent(
        platform,
        widget.content,
      );

      if (success && mounted) {
        // Award XP for sharing
        final xpSystem = XPSystem.instance;
        await xpSystem.addXP(
          XPAction.shareProduct,
          customDescription: 'Shared "${widget.content.title}" on ${platform.displayName}',
        );

        // Show success feedback
        if (platform == SocialPlatform.copyLink) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link copied to clipboard!'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Shared on ${platform.displayName}!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        widget.onShareComplete?.call();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share on ${platform.displayName}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sharingStates[platform] = false;
        });
      }
    }
  }

  void _showFullSharingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Full sharing widget
            SocialSharingWidget(
              content: widget.content,
              platforms: SocialPlatform.values,
              onShareComplete: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick share button for easy access
class QuickShareButton extends StatelessWidget {
  final ShareContent content;
  final IconData? icon;
  final String? label;
  final bool showLabel;

  const QuickShareButton({
    super.key,
    required this.content,
    this.icon,
    this.label,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSharingSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.share,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (showLabel) ...[
              const SizedBox(width: AppConstants.spacingS),
              Text(
                label ?? 'Share',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSharingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Sharing widget
            SocialSharingWidget(
              content: content,
              platforms: SocialPlatform.values,
              onShareComplete: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Social sharing mixin for easy integration
mixin SocialSharingMixin<T extends StatefulWidget> on State<T> {
  void shareProduct(Product product, {String? customMessage}) {
    final content = ShareContent.fromProduct(product, customMessage: customMessage);
    _showSharingSheet(content);
  }

  void shareCustomContent({
    required String title,
    required String description,
    required String url,
    String? imageUrl,
    Map<String, String>? customData,
  }) {
    final content = ShareContent.custom(
      title: title,
      description: description,
      url: url,
      imageUrl: imageUrl,
      customData: customData,
    );
    _showSharingSheet(content);
  }

  void _showSharingSheet(ShareContent content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Sharing widget
            SocialSharingWidget(
              content: content,
              platforms: SocialPlatform.values,
              onShareComplete: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}