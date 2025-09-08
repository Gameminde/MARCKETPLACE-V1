import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../core/config/app_constants.dart';
import '../core/theme/app_theme.dart';
import 'glassmorphic_container.dart';

/// Comprehensive loading states widget collection with skeleton loaders,
/// spinners, and various loading animations
class LoadingStates extends StatelessWidget {
  final LoadingType type;
  final LoadingSize size;
  final Color? color;
  final Duration duration;
  final bool enableGlassmorphism;
  final String? message;
  final double? width;
  final double? height;
  
  const LoadingStates({
    super.key,
    this.type = LoadingType.spinner,
    this.size = LoadingSize.medium,
    this.color,
    this.duration = const Duration(milliseconds: 1000),
    this.enableGlassmorphism = false,
    this.message,
    this.width,
    this.height,
  });

  /// Factory constructor for skeleton product card
  factory LoadingStates.skeletonProductCard({
    Key? key,
    bool enableGlassmorphism = false,
  }) {
    return LoadingStates(
      key: key,
      type: LoadingType.skeletonProductCard,
      enableGlassmorphism: enableGlassmorphism,
      width: AppConstants.productCardHeight,
      height: AppConstants.productCardHeight,
    );
  }

  /// Factory constructor for skeleton list item
  factory LoadingStates.skeletonListItem({
    Key? key,
    bool enableGlassmorphism = false,
  }) {
    return LoadingStates(
      key: key,
      type: LoadingType.skeletonListItem,
      enableGlassmorphism: enableGlassmorphism,
    );
  }

  /// Factory constructor for skeleton profile
  factory LoadingStates.skeletonProfile({
    Key? key,
    bool enableGlassmorphism = false,
  }) {
    return LoadingStates(
      key: key,
      type: LoadingType.skeletonProfile,
      enableGlassmorphism: enableGlassmorphism,
    );
  }

  /// Factory constructor for page loading overlay
  factory LoadingStates.pageLoading({
    Key? key,
    String? message,
    Color? backgroundColor,
  }) {
    return LoadingStates(
      key: key,
      type: LoadingType.pageOverlay,
      message: message,
      enableGlassmorphism: true,
    );
  }

  /// Factory constructor for pull to refresh
  factory LoadingStates.pullToRefresh({
    Key? key,
    Color? color,
  }) {
    return LoadingStates(
      key: key,
      type: LoadingType.pullToRefresh,
      size: LoadingSize.small,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingType.spinner:
        return _buildSpinner(context);
      case LoadingType.dots:
        return _buildDotsLoader(context);
      case LoadingType.pulse:
        return _buildPulseLoader(context);
      case LoadingType.wave:
        return _buildWaveLoader(context);
      case LoadingType.skeletonProductCard:
        return _buildSkeletonProductCard(context);
      case LoadingType.skeletonListItem:
        return _buildSkeletonListItem(context);
      case LoadingType.skeletonProfile:
        return _buildSkeletonProfile(context);
      case LoadingType.skeletonText:
        return _buildSkeletonText(context);
      case LoadingType.pageOverlay:
        return _buildPageOverlay(context);
      case LoadingType.pullToRefresh:
        return _buildPullToRefresh(context);
      case LoadingType.shimmer:
        return _buildShimmerLoader(context);
    }
  }

  Widget _buildSpinner(BuildContext context) {
    final theme = Theme.of(context);
    final spinnerColor = color ?? theme.colorScheme.primary;
    final spinnerSize = _getSize();
    
    return SizedBox(
      width: spinnerSize,
      height: spinnerSize,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        strokeWidth: _getStrokeWidth(),
      ),
    );
  }

  Widget _buildDotsLoader(BuildContext context) {
    return _AnimatedDotsLoader(
      color: color ?? Theme.of(context).colorScheme.primary,
      size: _getSize(),
      duration: duration,
    );
  }

  Widget _buildPulseLoader(BuildContext context) {
    return _AnimatedPulseLoader(
      color: color ?? Theme.of(context).colorScheme.primary,
      size: _getSize(),
      duration: duration,
    );
  }

  Widget _buildWaveLoader(BuildContext context) {
    return _AnimatedWaveLoader(
      color: color ?? Theme.of(context).colorScheme.primary,
      size: _getSize(),
      duration: duration,
    );
  }

  Widget _buildSkeletonProductCard(BuildContext context) {
    final skeleton = _SkeletonProductCard(
      enableGlassmorphism: enableGlassmorphism,
    );
    
    return _ShimmerWrapper(
      child: skeleton,
    );
  }

  Widget _buildSkeletonListItem(BuildContext context) {
    final skeleton = _SkeletonListItem(
      enableGlassmorphism: enableGlassmorphism,
    );
    
    return _ShimmerWrapper(
      child: skeleton,
    );
  }

  Widget _buildSkeletonProfile(BuildContext context) {
    final skeleton = _SkeletonProfile(
      enableGlassmorphism: enableGlassmorphism,
    );
    
    return _ShimmerWrapper(
      child: skeleton,
    );
  }

  Widget _buildSkeletonText(BuildContext context) {
    return _ShimmerWrapper(
      child: _SkeletonBox(
        width: width ?? 200,
        height: height ?? 16,
        enableGlassmorphism: enableGlassmorphism,
      ),
    );
  }

  Widget _buildPageOverlay(BuildContext context) {
    return _PageLoadingOverlay(
      message: message,
      enableGlassmorphism: enableGlassmorphism,
      color: color,
    );
  }

  Widget _buildPullToRefresh(BuildContext context) {
    return _buildSpinner(context);
  }

  Widget _buildShimmerLoader(BuildContext context) {
    return _ShimmerWrapper(
      child: Container(
        width: width ?? 100,
        height: height ?? 20,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }

  double _getSize() {
    switch (size) {
      case LoadingSize.small:
        return 20.0;
      case LoadingSize.medium:
        return 32.0;
      case LoadingSize.large:
        return 48.0;
      case LoadingSize.extraLarge:
        return 64.0;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingSize.small:
        return 2.0;
      case LoadingSize.medium:
        return 3.0;
      case LoadingSize.large:
        return 4.0;
      case LoadingSize.extraLarge:
        return 5.0;
    }
  }
}

/// Loading types enumeration
enum LoadingType {
  spinner,
  dots,
  pulse,
  wave,
  skeletonProductCard,
  skeletonListItem,
  skeletonProfile,
  skeletonText,
  pageOverlay,
  pullToRefresh,
  shimmer,
}

/// Loading sizes enumeration
enum LoadingSize {
  small,
  medium,
  large,
  extraLarge,
}

/// Animated dots loader
class _AnimatedDotsLoader extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  
  const _AnimatedDotsLoader({
    required this.color,
    required this.size,
    required this.duration,
  });
  
  @override
  State<_AnimatedDotsLoader> createState() => _AnimatedDotsLoaderState();
}

class _AnimatedDotsLoaderState extends State<_AnimatedDotsLoader>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: widget.duration,
        vsync: this,
      );
    });
    
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    
    _startAnimations();
  }
  
  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.1),
              child: Opacity(
                opacity: 0.3 + (0.7 * _animations[index].value),
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Animated pulse loader
class _AnimatedPulseLoader extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  
  const _AnimatedPulseLoader({
    required this.color,
    required this.size,
    required this.duration,
  });
  
  @override
  State<_AnimatedPulseLoader> createState() => _AnimatedPulseLoaderState();
}

class _AnimatedPulseLoaderState extends State<_AnimatedPulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.3 + (0.7 * _animation.value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Animated wave loader
class _AnimatedWaveLoader extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  
  const _AnimatedWaveLoader({
    required this.color,
    required this.size,
    required this.duration,
  });
  
  @override
  State<_AnimatedWaveLoader> createState() => _AnimatedWaveLoaderState();
}

class _AnimatedWaveLoaderState extends State<_AnimatedWaveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WavePainter(
            color: widget.color,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

/// Wave painter for wave loader
class _WavePainter extends CustomPainter {
  final Color color;
  final double progress;
  
  _WavePainter({required this.color, required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    for (int i = 0; i < 3; i++) {
      final radius = maxRadius * ((progress + (i * 0.3)) % 1.0);
      final opacity = 1.0 - ((progress + (i * 0.3)) % 1.0);
      
      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Skeleton product card
class _SkeletonProductCard extends StatelessWidget {
  final bool enableGlassmorphism;
  
  const _SkeletonProductCard({
    required this.enableGlassmorphism,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image placeholder
        _SkeletonBox(
          width: double.infinity,
          height: AppConstants.productImageHeight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppConstants.cardBorderRadius),
            topRight: Radius.circular(AppConstants.cardBorderRadius),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppConstants.productCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title placeholder
              _SkeletonBox(
                width: double.infinity,
                height: 16,
                enableGlassmorphism: enableGlassmorphism,
              ),
              const SizedBox(height: AppConstants.spacingS),
              // Subtitle placeholder
              _SkeletonBox(
                width: 120,
                height: 14,
                enableGlassmorphism: enableGlassmorphism,
              ),
              const SizedBox(height: AppConstants.spacingM),
              // Price and rating row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SkeletonBox(
                    width: 60,
                    height: 16,
                    enableGlassmorphism: enableGlassmorphism,
                  ),
                  _SkeletonBox(
                    width: 50,
                    height: 14,
                    enableGlassmorphism: enableGlassmorphism,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    
    if (enableGlassmorphism) {
      return GlassmorphicContainer.card(
        child: content,
      );
    }
    
    return Card(
      child: content,
    );
  }
}

/// Skeleton list item
class _SkeletonListItem extends StatelessWidget {
  final bool enableGlassmorphism;
  
  const _SkeletonListItem({
    required this.enableGlassmorphism,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          // Avatar placeholder
          _SkeletonBox(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(25),
            enableGlassmorphism: enableGlassmorphism,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title placeholder
                _SkeletonBox(
                  width: double.infinity,
                  height: 16,
                  enableGlassmorphism: enableGlassmorphism,
                ),
                const SizedBox(height: AppConstants.spacingS),
                // Subtitle placeholder
                _SkeletonBox(
                  width: 150,
                  height: 14,
                  enableGlassmorphism: enableGlassmorphism,
                ),
              ],
            ),
          ),
          // Action placeholder
          _SkeletonBox(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(12),
            enableGlassmorphism: enableGlassmorphism,
          ),
        ],
      ),
    );
    
    if (enableGlassmorphism) {
      return GlassmorphicContainer.card(
        child: content,
      );
    }
    
    return Card(
      child: content,
    );
  }
}

/// Skeleton profile
class _SkeletonProfile extends StatelessWidget {
  final bool enableGlassmorphism;
  
  const _SkeletonProfile({
    required this.enableGlassmorphism,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        children: [
          // Profile picture placeholder
          _SkeletonBox(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(40),
            enableGlassmorphism: enableGlassmorphism,
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Name placeholder
          _SkeletonBox(
            width: 120,
            height: 18,
            enableGlassmorphism: enableGlassmorphism,
          ),
          const SizedBox(height: AppConstants.spacingS),
          // Email placeholder
          _SkeletonBox(
            width: 160,
            height: 14,
            enableGlassmorphism: enableGlassmorphism,
          ),
          const SizedBox(height: AppConstants.spacingL),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return Column(
                children: [
                  _SkeletonBox(
                    width: 40,
                    height: 16,
                    enableGlassmorphism: enableGlassmorphism,
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  _SkeletonBox(
                    width: 60,
                    height: 12,
                    enableGlassmorphism: enableGlassmorphism,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
    
    if (enableGlassmorphism) {
      return GlassmorphicContainer.card(
        child: content,
      );
    }
    
    return Card(
      child: content,
    );
  }
}

/// Basic skeleton box
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool enableGlassmorphism;
  
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius,
    this.enableGlassmorphism = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadius),
      ),
    );
  }
}

/// Shimmer wrapper for skeleton loading effect
class _ShimmerWrapper extends StatefulWidget {
  final Widget child;
  
  const _ShimmerWrapper({
    required this.child,
  });
  
  @override
  State<_ShimmerWrapper> createState() => _ShimmerWrapperState();
}

class _ShimmerWrapperState extends State<_ShimmerWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.transparent,
                isDark ? Colors.white24 : Colors.white70,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: GradientRotation(_animation.value * math.pi / 4),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Page loading overlay
class _PageLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool enableGlassmorphism;
  final Color? color;
  
  const _PageLoadingOverlay({
    this.message,
    required this.enableGlassmorphism,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadingStates(
          type: LoadingType.spinner,
          size: LoadingSize.large,
          color: color ?? theme.colorScheme.primary,
        ),
        if (message != null) ...[
          const SizedBox(height: AppConstants.spacingL),
          Text(
            message!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
    
    if (enableGlassmorphism) {
      content = GlassmorphicContainer.dialog(
        child: content,
      );
    } else {
      content = Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: content,
        ),
      );
    }
    
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: content,
      ),
    );
  }
}