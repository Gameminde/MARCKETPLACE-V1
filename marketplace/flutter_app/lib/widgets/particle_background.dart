import 'dart:math';
import 'package:flutter/material.dart';

import '../core/config/app_constants.dart';
import '../core/theme/dynamic_theme_manager.dart';

/// Comprehensive particle background widget with multiple animation styles,
/// seasonal themes, and performance optimizations
class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final double particleSpeed;
  final double particleSize;
  final ParticleStyle style;
  final Duration animationDuration;
  final bool enableTouchInteraction;
  final bool enableSeasonalTheming;
  final List<Color>? customColors;
  final ParticleShape particleShape;
  final bool enableGlow;
  final double minOpacity;
  final double maxOpacity;
  final bool enableConnections;
  final double connectionDistance;
  final BlendMode blendMode;
  
  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = AppConstants.particleCount,
    this.particleSpeed = AppConstants.particleSpeed,
    this.particleSize = AppConstants.particleSize,
    this.style = ParticleStyle.floating,
    this.animationDuration = const Duration(seconds: 20),
    this.enableTouchInteraction = false,
    this.enableSeasonalTheming = true,
    this.customColors,
    this.particleShape = ParticleShape.circle,
    this.enableGlow = false,
    this.minOpacity = 0.1,
    this.maxOpacity = 0.6,
    this.enableConnections = false,
    this.connectionDistance = 100.0,
    this.blendMode = BlendMode.srcOver,
  });

  /// Factory constructor for seasonal particle background
  factory ParticleBackground.seasonal({
    Key? key,
    required Widget child,
    SeasonalTheme? seasonalTheme,
    int? particleCount,
  }) {
    return ParticleBackground(
      key: key,
      particleCount: particleCount ?? AppConstants.particleCount,
      enableSeasonalTheming: true,
      style: _getSeasonalStyle(seasonalTheme),
      customColors: _getSeasonalColors(seasonalTheme),
      child: child,
    );
  }

  /// Factory constructor for interactive particle background
  factory ParticleBackground.interactive({
    Key? key,
    required Widget child,
    int particleCount = 30,
  }) {
    return ParticleBackground(
      key: key,
      particleCount: particleCount,
      enableTouchInteraction: true,
      style: ParticleStyle.interactive,
      enableConnections: true,
      enableGlow: true,
      child: child,
    );
  }

  /// Factory constructor for subtle particle background
  factory ParticleBackground.subtle({
    Key? key,
    required Widget child,
  }) {
    return ParticleBackground(
      key: key,
      particleCount: 15,
      particleSpeed: 0.3,
      particleSize: 1.5,
      style: ParticleStyle.floating,
      minOpacity: 0.05,
      maxOpacity: 0.2,
      child: child,
    );
  }

  static ParticleStyle _getSeasonalStyle(SeasonalTheme? theme) {
    switch (theme) {
      case SeasonalTheme.winter:
      case SeasonalTheme.christmas:
        return ParticleStyle.snow;
      case SeasonalTheme.autumn:
        return ParticleStyle.leaves;
      case SeasonalTheme.spring:
        return ParticleStyle.petals;
      case SeasonalTheme.halloween:
        return ParticleStyle.spooky;
      default:
        return ParticleStyle.floating;
    }
  }

  static List<Color> _getSeasonalColors(SeasonalTheme? theme) {
    switch (theme) {
      case SeasonalTheme.spring:
        return [Colors.pink.withOpacity(0.4), Colors.green.withOpacity(0.3), Colors.yellow.withOpacity(0.2)];
      case SeasonalTheme.summer:
        return [Colors.blue.withOpacity(0.3), Colors.cyan.withOpacity(0.2), Colors.white.withOpacity(0.4)];
      case SeasonalTheme.autumn:
        return [Colors.orange.withOpacity(0.4), Colors.red.withOpacity(0.3), Colors.brown.withOpacity(0.2)];
      case SeasonalTheme.winter:
      case SeasonalTheme.christmas:
        return [Colors.white.withOpacity(0.6), Colors.blue.withOpacity(0.2), Colors.grey.withOpacity(0.1)];
      case SeasonalTheme.halloween:
        return [Colors.orange.withOpacity(0.5), Colors.purple.withOpacity(0.3), Colors.black.withOpacity(0.2)];
      default:
        return [Colors.white.withOpacity(0.3), Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.1)];
    }
  }

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  late List<Particle> _particles;
  final Random _random = Random();
  Offset? _touchPosition;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
  }

  void _initializeAnimations() {
    _primaryController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat();
    
    _secondaryController = AnimationController(
      duration: Duration(
        milliseconds: (widget.animationDuration.inMilliseconds * 0.7).round(),
      ),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _generateParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        position: Offset(_random.nextDouble(), _random.nextDouble()),
        velocity: _generateVelocity(),
        size: _generateSize(),
        opacity: widget.minOpacity + _random.nextDouble() * (widget.maxOpacity - widget.minOpacity),
        color: _generateColor(),
        rotationSpeed: (_random.nextDouble() - 0.5) * 2,
        pulsePhase: _random.nextDouble() * 2 * pi,
        id: index,
      );
    });
  }

  Offset _generateVelocity() {
    switch (widget.style) {
      case ParticleStyle.snow:
        return Offset(
          (_random.nextDouble() - 0.5) * 0.001,
          _random.nextDouble() * 0.002 + 0.001,
        );
      case ParticleStyle.leaves:
        return Offset(
          (_random.nextDouble() - 0.5) * 0.003,
          _random.nextDouble() * 0.002 + 0.001,
        );
      case ParticleStyle.petals:
        return Offset(
          (_random.nextDouble() - 0.5) * 0.002,
          _random.nextDouble() * 0.0015 + 0.0005,
        );
      case ParticleStyle.floating:
      case ParticleStyle.interactive:
      case ParticleStyle.spooky:
      default:
        return Offset(
          (_random.nextDouble() - 0.5) * widget.particleSpeed * 0.002,
          (_random.nextDouble() - 0.5) * widget.particleSpeed * 0.002,
        );
    }
  }

  double _generateSize() {
    switch (widget.style) {
      case ParticleStyle.snow:
        return _random.nextDouble() * 3 + 1;
      case ParticleStyle.leaves:
        return _random.nextDouble() * 4 + 2;
      case ParticleStyle.petals:
        return _random.nextDouble() * 2.5 + 1.5;
      default:
        return _random.nextDouble() * widget.particleSize + widget.particleSize * 0.5;
    }
  }

  Color _generateColor() {
    if (widget.customColors != null && widget.customColors!.isNotEmpty) {
      return widget.customColors![_random.nextInt(widget.customColors!.length)];
    }
    
    // Default color based on theme
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return Colors.white.withOpacity(0.3);
    } else {
      return Colors.black.withOpacity(0.1);
    }
  }

  void _handleTouchInteraction(Offset position) {
    if (!widget.enableTouchInteraction) return;
    
    setState(() {
      _touchPosition = position;
    });
    
    // Add attraction/repulsion effect
    for (var particle in _particles) {
      final dx = position.dx - particle.position.dx;
      final dy = position.dy - particle.position.dy;
      final distance = sqrt(dx * dx + dy * dy);
      
      if (distance < 0.2) { // Attraction/repulsion zone
        final force = 0.001 / (distance + 0.01);
        particle.velocity = Offset(
          particle.velocity.dx + dx * force * 0.1,
          particle.velocity.dy + dy * force * 0.1,
        );
      }
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget backgroundWidget = AnimatedBuilder(
      animation: Listenable.merge([_primaryController, _secondaryController]),
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            primaryProgress: _primaryController.value,
            secondaryProgress: _secondaryController.value,
            style: widget.style,
            particleShape: widget.particleShape,
            enableGlow: widget.enableGlow,
            enableConnections: widget.enableConnections,
            connectionDistance: widget.connectionDistance,
            touchPosition: _touchPosition,
            blendMode: widget.blendMode,
          ),
          child: child,
        );
      },
      child: widget.child,
    );

    if (widget.enableTouchInteraction) {
      backgroundWidget = GestureDetector(
        onPanUpdate: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPosition = renderBox.globalToLocal(details.globalPosition);
            final normalizedPosition = Offset(
              localPosition.dx / renderBox.size.width,
              localPosition.dy / renderBox.size.height,
            );
            _handleTouchInteraction(normalizedPosition);
          }
        },
        onTapUp: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPosition = renderBox.globalToLocal(details.globalPosition);
            final normalizedPosition = Offset(
              localPosition.dx / renderBox.size.width,
              localPosition.dy / renderBox.size.height,
            );
            _handleTouchInteraction(normalizedPosition);
          }
        },
        child: backgroundWidget,
      );
    }

    return backgroundWidget;
  }
}

/// Particle data class with enhanced properties
class Particle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  Color color;
  double rotationSpeed;
  double pulsePhase;
  int id;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.color,
    required this.rotationSpeed,
    required this.pulsePhase,
    required this.id,
  });
}

/// Particle animation styles
enum ParticleStyle {
  floating,
  snow,
  leaves,
  petals,
  interactive,
  spooky,
}

/// Particle shapes
enum ParticleShape {
  circle,
  square,
  triangle,
  star,
  heart,
}

/// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double primaryProgress;
  final double secondaryProgress;
  final ParticleStyle style;
  final ParticleShape particleShape;
  final bool enableGlow;
  final bool enableConnections;
  final double connectionDistance;
  final Offset? touchPosition;
  final BlendMode blendMode;
  
  ParticlePainter({
    required this.particles,
    required this.primaryProgress,
    required this.secondaryProgress,
    required this.style,
    required this.particleShape,
    required this.enableGlow,
    required this.enableConnections,
    required this.connectionDistance,
    this.touchPosition,
    required this.blendMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update particle positions
    for (var particle in particles) {
      _updateParticlePosition(particle, size);
    }
    
    // Draw connections if enabled
    if (enableConnections) {
      _drawConnections(canvas, size);
    }
    
    // Draw particles
    for (var particle in particles) {
      _drawParticle(canvas, size, particle);
    }
  }
  
  void _updateParticlePosition(Particle particle, Size size) {
    // Update position based on velocity and time
    particle.position = Offset(
      (particle.position.dx + particle.velocity.dx) % 1.0,
      (particle.position.dy + particle.velocity.dy) % 1.0,
    );
    
    // Wrap around screen edges
    if (particle.position.dx < 0) particle.position = Offset(1.0, particle.position.dy);
    if (particle.position.dy < 0) particle.position = Offset(particle.position.dx, 1.0);
    
    // Add style-specific behaviors
    switch (style) {
      case ParticleStyle.snow:
        // Add subtle wind effect
        particle.velocity = Offset(
          particle.velocity.dx + sin(primaryProgress * 2 * pi + particle.id) * 0.0001,
          particle.velocity.dy,
        );
        break;
      case ParticleStyle.leaves:
        // Add swirling motion
        final swirl = sin(primaryProgress * 4 * pi + particle.id) * 0.0005;
        particle.velocity = Offset(
          particle.velocity.dx + swirl,
          particle.velocity.dy,
        );
        break;
      case ParticleStyle.petals:
        // Add gentle floating motion
        particle.velocity = Offset(
          particle.velocity.dx + sin(primaryProgress * 3 * pi + particle.id) * 0.0002,
          particle.velocity.dy + cos(primaryProgress * 2 * pi + particle.id) * 0.0001,
        );
        break;
      default:
        break;
    }
  }
  
  void _drawConnections(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;
    
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        
        final pos1 = Offset(p1.position.dx * size.width, p1.position.dy * size.height);
        final pos2 = Offset(p2.position.dx * size.width, p2.position.dy * size.height);
        
        final distance = (pos1 - pos2).distance;
        
        if (distance < connectionDistance) {
          final opacity = (1.0 - distance / connectionDistance) * 0.2;
          paint.color = Colors.white.withOpacity(opacity);
          canvas.drawLine(pos1, pos2, paint);
        }
      }
    }
  }
  
  void _drawParticle(Canvas canvas, Size size, Particle particle) {
    final position = Offset(
      particle.position.dx * size.width,
      particle.position.dy * size.height,
    );
    
    // Calculate dynamic opacity with pulsing effect
    final pulseEffect = sin(secondaryProgress * 2 * pi + particle.pulsePhase) * 0.2 + 0.8;
    final dynamicOpacity = particle.opacity * pulseEffect;
    
    final paint = Paint()
      ..color = particle.color.withOpacity(dynamicOpacity)
      ..blendMode = blendMode;
    
    // Add glow effect if enabled
    if (enableGlow) {
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(dynamicOpacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      _drawShape(canvas, position, particle.size * 2, glowPaint, particle);
    }
    
    // Draw main particle
    _drawShape(canvas, position, particle.size, paint, particle);
  }
  
  void _drawShape(Canvas canvas, Offset position, double size, Paint paint, Particle particle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(primaryProgress * 2 * pi * particle.rotationSpeed);
    
    switch (particleShape) {
      case ParticleShape.circle:
        canvas.drawCircle(Offset.zero, size, paint);
        break;
      case ParticleShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: size * 2, height: size * 2),
          paint,
        );
        break;
      case ParticleShape.triangle:
        final path = Path()
          ..moveTo(0, -size)
          ..lineTo(-size * 0.866, size * 0.5)
          ..lineTo(size * 0.866, size * 0.5)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case ParticleShape.star:
        _drawStar(canvas, size, paint);
        break;
      case ParticleShape.heart:
        _drawHeart(canvas, size, paint);
        break;
    }
    
    canvas.restore();
  }
  
  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    const points = 5;
    const angle = 2 * pi / points;
    
    for (int i = 0; i < points * 2; i++) {
      final radius = i % 2 == 0 ? size : size * 0.4;
      final x = radius * cos(i * angle / 2 - pi / 2);
      final y = radius * sin(i * angle / 2 - pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    path.moveTo(0, size * 0.3);
    
    // Left curve
    path.cubicTo(-size * 0.5, -size * 0.3, -size, -size * 0.1, -size * 0.5, size * 0.3);
    path.lineTo(0, size);
    
    // Right curve
    path.lineTo(size * 0.5, size * 0.3);
    path.cubicTo(size, -size * 0.1, size * 0.5, -size * 0.3, 0, size * 0.3);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return primaryProgress != oldDelegate.primaryProgress ||
           secondaryProgress != oldDelegate.secondaryProgress ||
           touchPosition != oldDelegate.touchPosition;
  }
}
