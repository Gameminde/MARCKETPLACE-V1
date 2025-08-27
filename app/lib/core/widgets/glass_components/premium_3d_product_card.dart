import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../theme/glass_theme.dart';
import '../../../models/product.dart';

/// Premium Product Card avec animations 3D et glassmorphisme
/// Basé sur les spécifications de glassify-forge avec optimisations Flutter
class Premium3DProductCard extends StatefulWidget {
  final Product product;
  final int animationDelay;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final ProductCategory category;
  final bool enableHaptics;
  
  const Premium3DProductCard({
    super.key,
    required this.product,
    this.animationDelay = 0,
    this.onTap,
    this.onFavorite,
    this.category = ProductCategory.neutral,
    this.enableHaptics = true,
  });

  @override
  State<Premium3DProductCard> createState() => _Premium3DProductCardState();
}

class _Premium3DProductCardState extends State<Premium3DProductCard>
    with TickerProviderStateMixin {
  
  // Contrôleurs d'animation
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _favoriteController;
  late AnimationController _entryController;
  
  // Animations
  late Animation<double> _elevationAnimation;
  late Animation<double> _rotationXAnimation;
  late Animation<double> _rotationYAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isHovered = false;
  bool _isFavorite = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntryAnimation();
  }
  
  void _initializeAnimations() {
    // Contrôleur pour hover effect (300ms - spécification)
    _hoverController = AnimationController(
      duration: GlassTheme.progressReward, // 300ms
      vsync: this,
    );
    
    // Contrôleur pour press effect (100ms - feedback instantané)
    _pressController = AnimationController(
      duration: GlassTheme.instantFeedback, // 100ms
      vsync: this,
    );
    
    // Contrôleur pour favorite animation (600ms - accomplissement)
    _favoriteController = AnimationController(
      duration: GlassTheme.achievementBurst, // 600ms
      vsync: this,
    );
    
    // Contrôleur pour animation d'entrée
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animation d'élévation (Float effect - 8px)
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: GlassTheme.easeBack, // Courbe élastique
    ));
    
    // Animation de rotation X (3° selon spécification)
    _rotationXAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05, // ~3 degrés en radians
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: GlassTheme.easeElastic,
    ));
    
    // Animation de rotation Y
    _rotationYAnimation = Tween<double>(
      begin: 0.0,
      end: 0.03, // ~2 degrés en radians
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: GlassTheme.easeElastic,
    ));
    
    // Animation de scale (Scale effect)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03, // 3% d'agrandissement
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: GlassTheme.easeSignature,
    ));
    
    // Animation de glow (intensité de l'ombre)
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0, // Augmentation du blur
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
    
    // Animation d'entrée - opacité
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    ));
    
    // Animation d'entrée - slide
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: GlassTheme.easeBack,
    ));
  }
  
  void _startEntryAnimation() {
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _entryController.forward();
      }
    });
  }
  
  void _handleHoverStart() {
    if (!_isHovered) {
      setState(() => _isHovered = true);
      _hoverController.forward();
      
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
    }
  }
  
  void _handleHoverEnd() {
    if (_isHovered) {
      setState(() => _isHovered = false);
      _hoverController.reverse();
    }
  }
  
  void _handleTapDown(TapDownDetails details) {
    _pressController.forward();
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
  }
  
  void _handleTapCancel() {
    _pressController.reverse();
  }
  
  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      if (widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    }
  }
  
  void _handleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _favoriteController.forward().then((_) {
      _favoriteController.reverse();
    });
    
    if (widget.onFavorite != null) {
      widget.onFavorite!();
    }
    
    if (widget.enableHaptics) {
      HapticFeedback.heavyImpact();
    }
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _favoriteController.dispose();
    _entryController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final categoryColor = GlassTheme.getColorByCategory(widget.category);
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _hoverController,
        _pressController,
        _entryController,
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: MouseRegion(
              onEnter: (_) => _handleHoverStart(),
              onExit: (_) => _handleHoverEnd(),
              child: GestureDetector(
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                onTap: _handleTap,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..translate(
                      0.0,
                      -_elevationAnimation.value,
                      0.0,
                    )
                    ..rotateX(_rotationXAnimation.value)
                    ..rotateY(_rotationYAnimation.value)
                    ..scale(_scaleAnimation.value * (1.0 - _pressController.value * 0.05)),
                  child: Container(
                    width: 180,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        // Ombre colorée principale
                        BoxShadow(
                          color: categoryColor.withOpacity(
                            GlassTheme.shadowIntensity + _glowAnimation.value * 0.02,
                          ),
                          blurRadius: 20 + _glowAnimation.value,
                          offset: Offset(0, 8 + _elevationAnimation.value),
                        ),
                        // Ombre de profondeur
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10 + _glowAnimation.value * 0.5,
                          offset: Offset(0, 4 + _elevationAnimation.value * 0.5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: GlassTheme.primaryBlur,
                          sigmaY: GlassTheme.primaryBlur,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            // Glassmorphisme
                            color: Colors.white.withOpacity(
                              GlassTheme.backgroundOpacity + _hoverController.value * 0.05,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                GlassTheme.borderOpacity + _hoverController.value * 0.1,
                              ),
                              width: 1,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                categoryColor.withOpacity(0.1),
                                categoryColor.withOpacity(0.05),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: _buildCardContent(categoryColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCardContent(Color categoryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image du produit avec overlay
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              // Image principale
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  color: Colors.grey.shade100,
                ),
                child: widget.product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              _buildImagePlaceholder(),
                        ),
                      )
                    : _buildImagePlaceholder(),
              ),
              
              // Bouton favori avec animation
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedBuilder(
                  animation: _favoriteController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + _favoriteController.value * 0.3,
                      child: GestureDetector(
                        onTap: _handleFavorite,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Badge catégorie
              if (widget.category != ProductCategory.neutral)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getCategoryLabel(widget.category),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Informations produit
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom du produit
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Prix avec animation
                AnimatedDefaultTextStyle(
                  duration: GlassTheme.explorationHint,
                  style: TextStyle(
                    fontSize: _isHovered ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                  child: Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                  ),
                ),
                
                const Spacer(),
                
                // Rating si disponible
                if (widget.product.rating != null)
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < (widget.product.rating ?? 0).floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.product.reviewCount ?? 0})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image,
        size: 48,
        color: Colors.grey.shade400,
      ),
    );
  }
  
  String _getCategoryLabel(ProductCategory category) {
    switch (category) {
      case ProductCategory.luxury:
        return 'LUXURY';
      case ProductCategory.tech:
        return 'TECH';
      case ProductCategory.fashion:
        return 'FASHION';
      case ProductCategory.urgent:
        return 'SALE';
      case ProductCategory.action:
        return 'NEW';
      default:
        return '';
    }
  }
}

/// Extension pour faciliter l'utilisation
extension ProductCardExtension on Product {
  /// Crée une Premium3DProductCard à partir du produit
  Widget toPremium3DCard({
    int animationDelay = 0,
    VoidCallback? onTap,
    VoidCallback? onFavorite,
    ProductCategory category = ProductCategory.neutral,
    bool enableHaptics = true,
  }) {
    return Premium3DProductCard(
      product: this,
      animationDelay: animationDelay,
      onTap: onTap,
      onFavorite: onFavorite,
      category: category,
      enableHaptics: enableHaptics,
    );
  }
}