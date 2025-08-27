import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../theme/glass_theme.dart';

/// Système de particules 3D natif Flutter
/// Inspiré du ParticleSystem de glassify-forge mais optimisé pour mobile
class ParticleSystemWidget extends StatefulWidget {
  final int particleCount;
  final List<Color> colors;
  final double speed;
  final double size;
  final String className;
  
  const ParticleSystemWidget({
    super.key,
    this.particleCount = 100, // Réduit pour mobile
    this.colors = GlassTheme.luxuryPalette,
    this.speed = 1.0,
    this.size = 2.0,
    this.className = "absolute inset-0 -z-20",
  });

  @override
  State<ParticleSystemWidget> createState() => _ParticleSystemWidgetState();
}

class _ParticleSystemWidgetState extends State<ParticleSystemWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late List<Particle> _particles;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _generateParticles();
  }
  
  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }
  
  void _generateParticles() {
    final random = math.Random();
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        z: random.nextDouble(),
        color: widget.colors[random.nextInt(widget.colors.length)],
        size: widget.size + random.nextDouble() * 2,
        speedX: (random.nextDouble() - 0.5) * widget.speed * 0.02,
        speedY: (random.nextDouble() - 0.5) * widget.speed * 0.02,
        speedZ: (random.nextDouble() - 0.5) * widget.speed * 0.01,
        phase: random.nextDouble() * math.pi * 2,
      );
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlePainter(
              particles: _particles,
              animationValue: _animationController.value,
              colors: widget.colors,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Classe représentant une particule individuelle
class Particle {
  double x, y, z;
  final Color color;
  final double size;
  final double speedX, speedY, speedZ;
  final double phase;
  
  Particle({
    required this.x,
    required this.y,
    required this.z,
    required this.color,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.speedZ,
    required this.phase,
  });
  
  /// Met à jour la position de la particule
  void update(double time) {
    // Mouvement de base
    x += speedX;
    y += speedY;
    z += speedZ;
    
    // Mouvement sinusoïdal pour effet organique
    y += math.sin(time * 2 + phase) * 0.001;
    x += math.cos(time * 1.5 + phase) * 0.0005;
    
    // Rebond sur les bords
    if (x < 0 || x > 1) x = math.max(0, math.min(1, x));
    if (y < 0 || y > 1) y = math.max(0, math.min(1, y));
    if (z < 0 || z > 1) z = math.max(0, math.min(1, z));
  }
}

/// Painter personnalisé pour dessiner les particules
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final List<Color> colors;
  
  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.colors,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final time = animationValue * 20; // 20 secondes de cycle
    
    for (final particle in particles) {
      // Mise à jour de la position
      particle.update(time);
      
      // Calcul de la position 3D projetée
      final perspective = 1000.0;
      final projectedX = (particle.x * size.width) + 
          (particle.z - 0.5) * 50; // Effet de profondeur
      final projectedY = (particle.y * size.height) + 
          (particle.z - 0.5) * 30;
      
      // Calcul de la taille avec perspective
      final perspectiveSize = particle.size * (1 + particle.z * 0.5);
      
      // Calcul de l'opacité avec profondeur
      final opacity = (0.3 + particle.z * 0.7) * 
          (0.8 + math.sin(time + particle.phase) * 0.2);
      
      // Création du paint avec effet glow
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, perspectiveSize * 0.5);
      
      // Dessin de la particule avec effet glow
      canvas.drawCircle(
        Offset(projectedX, projectedY),
        perspectiveSize,
        paint,
      );
      
      // Effet de traînée pour les particules rapides
      if (particle.speedX.abs() > 0.01 || particle.speedY.abs() > 0.01) {
        final trailPaint = Paint()
          ..color = particle.color.withOpacity(opacity * 0.3)
          ..strokeWidth = perspectiveSize * 0.5
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(
          Offset(projectedX, projectedY),
          Offset(
            projectedX - particle.speedX * 1000,
            projectedY - particle.speedY * 1000,
          ),
          trailPaint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Widget de particules optimisé pour performance
class OptimizedParticleSystem extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double intensity;
  
  const OptimizedParticleSystem({
    super.key,
    required this.child,
    this.enabled = true,
    this.intensity = 1.0,
  });

  @override
  State<OptimizedParticleSystem> createState() => _OptimizedParticleSystemState();
}

class _OptimizedParticleSystemState extends State<OptimizedParticleSystem> {
  bool _isLowEndDevice = false;
  
  @override
  void initState() {
    super.initState();
    _checkDeviceCapabilities();
  }
  
  void _checkDeviceCapabilities() {
    // Détection simple des capacités du device
    // En production, utiliser device_info_plus pour plus de précision
    setState(() {
      _isLowEndDevice = false; // Placeholder
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _isLowEndDevice) {
      // Fallback pour devices faibles : gradient statique
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlassTheme.luxuryPrimary.withOpacity(0.1),
              GlassTheme.trustSecondary.withOpacity(0.1),
              GlassTheme.actionAccent.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: widget.child,
      );
    }
    
    return Stack(
      children: [
        // Système de particules
        ParticleSystemWidget(
          particleCount: (_isLowEndDevice ? 50 : 100 * widget.intensity).round(),
          speed: widget.intensity,
        ),
        // Contenu principal
        widget.child,
      ],
    );
  }
}

/// Extension pour faciliter l'utilisation
extension ParticleSystemExtension on Widget {
  /// Ajoute un système de particules en arrière-plan
  Widget withParticles({
    bool enabled = true,
    double intensity = 1.0,
  }) {
    return OptimizedParticleSystem(
      enabled: enabled,
      intensity: intensity,
      child: this,
    );
  }
}