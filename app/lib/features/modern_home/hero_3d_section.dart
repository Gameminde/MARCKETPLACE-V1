import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../core/theme/glass_theme.dart';
import '../../models/user.dart';

/// Hero Section 3D avec parallax multi-couches
/// Basé sur les spécifications de HeroSection.tsx de glassify-forge
class Hero3DSection extends StatefulWidget {
  final double parallaxOffset;
  final User? user;
  final VoidCallback? onSearchTap;
  
  const Hero3DSection({
    super.key,
    required this.parallaxOffset,
    this.user,
    this.onSearchTap,
  });

  @override
  State<Hero3DSection> createState() => _Hero3DSectionState();
}

class _Hero3DSectionState extends State<Hero3DSection>
    with TickerProviderStateMixin {
  
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    // Animation de flottement pour éléments 3D
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    // Animation de pulsation pour CTA
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Animation d'entrée pour texte
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Flottement sinusoïdal
    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    // Pulsation pour bouton CTA
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Opacité du texte
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    // Slide du texte
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 0.8, curve: GlassTheme.easeBack),
    ));
  }
  
  void _startAnimations() {
    _floatingController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _textController.forward();
  }
  
  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenHeight * 0.7, // 70% de la hauteur d'écran
      width: double.infinity,
      child: Stack(
        children: [
          // Layer 1: Background Particles (Z-Index: -200)
          _buildBackgroundLayer(),
          
          // Layer 2: Geometric Shapes (Z-Index: -100)
          _buildGeometricLayer(),
          
          // Layer 3: Content Principal (Z-Index: 0)
          _buildContentLayer(),
          
          // Layer 4: Floating Elements (Z-Index: 100)
          _buildFloatingLayer(),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundLayer() {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, widget.parallaxOffset * -50), // Parallax lent
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GlassTheme.luxuryPrimary.withOpacity(0.8),
                GlassTheme.trustSecondary.withOpacity(0.6),
                GlassTheme.actionAccent.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: ParallaxParticlesPainter(
              offset: widget.parallaxOffset,
              colors: GlassTheme.luxuryPalette,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
  
  Widget _buildGeometricLayer() {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, widget.parallaxOffset * -30), // Parallax moyen
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return CustomPaint(
              painter: GeometricShapesPainter(
                floatingOffset: _floatingAnimation.value,
                parallaxOffset: widget.parallaxOffset,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildContentLayer() {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, widget.parallaxOffset * -10), // Parallax rapide
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message de bienvenue personnalisé
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: _buildWelcomeMessage(),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Titre principal avec effet gradient
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: _buildMainTitle(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Sous-titre avec animations
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: _buildSubtitle(),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Boutons CTA avec animations
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: _buildCTAButtons(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFloatingLayer() {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, widget.parallaxOffset * 20), // Parallax inverse
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return CustomPaint(
              painter: FloatingElementsPainter(
                floatingOffset: _floatingAnimation.value,
                time: _floatingController.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildWelcomeMessage() {
    final user = widget.user;
    return Text(
      user != null 
          ? 'Welcome back, ${user.firstName}! 👋'
          : 'Welcome to the Future! 🚀',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.w500,
      ),
    );
  }
  
  Widget _buildMainTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Colors.white,
          GlassTheme.actionAccent,
          GlassTheme.energyWarning,
        ],
      ).createShader(bounds),
      child: Text(
        'Experience the\nMarketplace\nRevolution',
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
  
  Widget _buildSubtitle() {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white.withOpacity(0.8),
          height: 1.4,
        ),
        children: [
          const TextSpan(text: 'Discover amazing products with '),
          TextSpan(
            text: '3D interactions',
            style: TextStyle(
              color: GlassTheme.actionAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: ', '),
          TextSpan(
            text: 'AI-powered discovery',
            style: TextStyle(
              color: GlassTheme.trustSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: ', and '),
          TextSpan(
            text: 'glassmorphism design',
            style: TextStyle(
              color: GlassTheme.luxuryPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
  
  Widget _buildCTAButtons() {
    return Row(
      children: [
        // Bouton principal avec pulsation
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GlassTheme.luxuryPrimary,
                      GlassTheme.trustSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: GlassTheme.luxuryPrimary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSearchTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Start Shopping',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(width: 16),
        
        // Bouton secondaire avec glassmorphisme
        Container(
          decoration: GlassTheme.createGlassDecoration(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Navigation vers découverte
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Text(
                      'Explore',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter pour particules de parallax
class ParallaxParticlesPainter extends CustomPainter {
  final double offset;
  final List<Color> colors;
  
  ParallaxParticlesPainter({
    required this.offset,
    required this.colors,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Seed fixe pour consistance
    
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height + offset * 50;
      final color = colors[i % colors.length];
      final radius = 1.0 + random.nextDouble() * 3.0;
      
      final paint = Paint()
        ..color = color.withOpacity(0.3 + offset * 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(ParallaxParticlesPainter oldDelegate) {
    return oldDelegate.offset != offset;
  }
}

/// Painter pour formes géométriques
class GeometricShapesPainter extends CustomPainter {
  final double floatingOffset;
  final double parallaxOffset;
  
  GeometricShapesPainter({
    required this.floatingOffset,
    required this.parallaxOffset,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Cercle flottant
    canvas.drawCircle(
      Offset(
        size.width * 0.8,
        size.height * 0.3 + floatingOffset + parallaxOffset * 20,
      ),
      50,
      paint,
    );
    
    // Rectangle avec rotation
    canvas.save();
    canvas.translate(
      size.width * 0.2,
      size.height * 0.7 + floatingOffset * 0.5 + parallaxOffset * 15,
    );
    canvas.rotate(parallaxOffset * 0.5);
    canvas.drawRect(
      const Rect.fromLTWH(-30, -30, 60, 60),
      paint,
    );
    canvas.restore();
    
    // Triangle
    final trianglePath = Path();
    final triangleCenter = Offset(
      size.width * 0.1,
      size.height * 0.2 + floatingOffset * 0.8 + parallaxOffset * 25,
    );
    trianglePath.moveTo(triangleCenter.dx, triangleCenter.dy - 25);
    trianglePath.lineTo(triangleCenter.dx - 25, triangleCenter.dy + 25);
    trianglePath.lineTo(triangleCenter.dx + 25, triangleCenter.dy + 25);
    trianglePath.close();
    canvas.drawPath(trianglePath, paint);
  }
  
  @override
  bool shouldRepaint(GeometricShapesPainter oldDelegate) {
    return oldDelegate.floatingOffset != floatingOffset ||
           oldDelegate.parallaxOffset != parallaxOffset;
  }
}

/// Painter pour éléments flottants
class FloatingElementsPainter extends CustomPainter {
  final double floatingOffset;
  final double time;
  
  FloatingElementsPainter({
    required this.floatingOffset,
    required this.time,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GlassTheme.actionAccent.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    // Éléments flottants avec mouvement sinusoïdal
    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.2 + i * 0.15) + 
                math.sin(time * 2 + i) * 20;
      final y = size.height * (0.1 + i * 0.2) + 
                floatingOffset + 
                math.cos(time * 1.5 + i) * 15;
      
      canvas.drawCircle(
        Offset(x, y),
        3 + math.sin(time * 3 + i) * 2,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(FloatingElementsPainter oldDelegate) {
    return oldDelegate.floatingOffset != floatingOffset ||
           oldDelegate.time != time;
  }
}