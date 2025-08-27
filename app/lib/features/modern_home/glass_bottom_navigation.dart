import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../core/theme/glass_theme.dart';

/// Glass Bottom Navigation avec animations fluides
/// Basé sur les spécifications de glassmorphisme de glassify-forge
class GlassBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;
  
  const GlassBottomNavigation({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  State<GlassBottomNavigation> createState() => _GlassBottomNavigationState();
}

class _GlassBottomNavigationState extends State<GlassBottomNavigation>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _iconController;
  late List<AnimationController> _itemControllers;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _iconScale;
  
  int _currentIndex = 0;
  
  final List<NavigationItem> _items = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      color: GlassTheme.luxuryPrimary,
    ),
    NavigationItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: 'Search',
      color: GlassTheme.trustSecondary,
    ),
    NavigationItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      label: 'Favorites',
      color: GlassTheme.urgencyDanger,
    ),
    NavigationItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      label: 'Cart',
      color: GlassTheme.actionAccent,
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      color: GlassTheme.energyWarning,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    // Animation de slide pour l'indicateur
    _slideController = AnimationController(
      duration: GlassTheme.progressReward, // 300ms
      vsync: this,
    );
    
    // Animation d'échelle pour les icônes
    _iconController = AnimationController(
      duration: GlassTheme.explorationHint, // 200ms
      vsync: this,
    );
    
    // Contrôleurs individuels pour chaque item
    _itemControllers = List.generate(
      _items.length,
      (index) => AnimationController(
        duration: GlassTheme.instantFeedback, // 100ms
        vsync: this,
      ),
    );
    
    // Animation de slide
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: GlassTheme.easeBack,
    ));
    
    // Animation d'échelle
    _iconScale = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: GlassTheme.easeBounce,
    ));
  }
  
  void _handleTap(int index) {
    if (index == _currentIndex) return;
    
    setState(() {
      _currentIndex = index;
    });
    
    // Animations
    _slideController.forward().then((_) {
      _slideController.reverse();
    });
    
    _iconController.forward().then((_) {
      _iconController.reverse();
    });
    
    _itemControllers[index].forward().then((_) {
      _itemControllers[index].reverse();
    });
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Callback
    if (widget.onTap != null) {
      widget.onTap!(index);
    }
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _iconController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: GlassTheme.luxuryPrimary.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTheme.primaryBlur,
            sigmaY: GlassTheme.primaryBlur,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // Indicateur de sélection animé
                _buildAnimatedIndicator(),
                
                // Items de navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildNavigationItem(item, index);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedIndicator() {
    return AnimatedPositioned(
      duration: GlassTheme.progressReward,
      curve: GlassTheme.easeBack,
      left: _currentIndex * (MediaQuery.of(context).size.width - 32) / _items.length,
      top: 8,
      child: Container(
        width: (MediaQuery.of(context).size.width - 32) / _items.length,
        height: 64,
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _items[_currentIndex].color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _items[_currentIndex].color.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _items[_currentIndex].color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavigationItem(NavigationItem item, int index) {
    final isSelected = index == _currentIndex;
    
    return Expanded(
      child: AnimatedBuilder(
        animation: _itemControllers[index],
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + _itemControllers[index].value * 0.1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleTap(index),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  height: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icône avec animation
                      AnimatedSwitcher(
                        duration: GlassTheme.explorationHint,
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          key: ValueKey(isSelected),
                          color: isSelected 
                              ? item.color
                              : Colors.white.withOpacity(0.6),
                          size: isSelected ? 28 : 24,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Label avec animation
                      AnimatedDefaultTextStyle(
                        duration: GlassTheme.explorationHint,
                        style: TextStyle(
                          fontSize: isSelected ? 12 : 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected 
                              ? item.color
                              : Colors.white.withOpacity(0.6),
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Classe pour représenter un item de navigation
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  
  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

/// Version avancée avec morphing icons
class MorphingGlassBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final List<NavigationItem> items;
  
  const MorphingGlassBottomNavigation({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    required this.items,
  });

  @override
  State<MorphingGlassBottomNavigation> createState() => _MorphingGlassBottomNavigationState();
}

class _MorphingGlassBottomNavigationState extends State<MorphingGlassBottomNavigation>
    with TickerProviderStateMixin {
  
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;
  
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _initializeMorphing();
  }
  
  void _initializeMorphing() {
    _morphController = AnimationController(
      duration: GlassTheme.achievementBurst, // 600ms pour morphing
      vsync: this,
    );
    
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: GlassTheme.easeElastic,
    ));
  }
  
  void _handleMorphingTap(int index) {
    if (index == _currentIndex) return;
    
    setState(() {
      _currentIndex = index;
    });
    
    // Animation de morphing
    _morphController.forward().then((_) {
      _morphController.reverse();
    });
    
    // Haptic feedback plus intense
    HapticFeedback.mediumImpact();
    
    if (widget.onTap != null) {
      widget.onTap!(index);
    }
  }
  
  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 90, // Plus haut pour morphing
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
          // Ombre colorée dynamique
          BoxShadow(
            color: widget.items[_currentIndex].color.withOpacity(0.2),
            blurRadius: 35,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: AnimatedBuilder(
            animation: _morphAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1 + _morphAnimation.value * 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3 + _morphAnimation.value * 0.1),
                    width: 1 + _morphAnimation.value,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      widget.items[_currentIndex].color.withOpacity(0.1),
                      Colors.white.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildMorphingItem(item, index);
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildMorphingItem(NavigationItem item, int index) {
    final isSelected = index == _currentIndex;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMorphingTap(index),
          borderRadius: BorderRadius.circular(25),
          child: AnimatedBuilder(
            animation: _morphAnimation,
            builder: (context, child) {
              final morphScale = isSelected ? 1.0 + _morphAnimation.value * 0.2 : 1.0;
              final morphOpacity = isSelected ? 1.0 : 0.6 + _morphAnimation.value * 0.2;
              
              return Transform.scale(
                scale: morphScale,
                child: Container(
                  height: 90,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icône avec morphing effect
                      Container(
                        width: 50,
                        height: 50,
                        decoration: isSelected ? BoxDecoration(
                          color: item.color.withOpacity(0.2 + _morphAnimation.value * 0.1),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withOpacity(0.4),
                              blurRadius: 10 + _morphAnimation.value * 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ) : null,
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: (isSelected ? item.color : Colors.white)
                              .withOpacity(morphOpacity),
                          size: 24 + (isSelected ? _morphAnimation.value * 6 : 0),
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Label avec morphing
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10 + (isSelected ? _morphAnimation.value * 2 : 0),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: (isSelected ? item.color : Colors.white)
                              .withOpacity(morphOpacity),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}