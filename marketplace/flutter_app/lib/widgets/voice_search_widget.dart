import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import '../core/config/app_constants.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';
import '../widgets/particle_background.dart';

/// Comprehensive voice search widget with speech-to-text functionality
class VoiceSearchWidget extends StatefulWidget {
  final Function(String)? onSearchResult;
  final Function()? onSearchStarted;
  final Function()? onSearchStopped;
  final Function(String)? onError;
  final VoidCallback? onClose;
  final bool enableWaveAnimation;
  final bool enableParticleBackground;
  final bool autoStart;
  final int maxDuration;
  final String? language;
  final List<String> supportedLanguages;
  final bool showTranscript;
  final bool enableCommands;

  const VoiceSearchWidget({
    super.key,
    this.onSearchResult,
    this.onSearchStarted,
    this.onSearchStopped,
    this.onError,
    this.onClose,
    this.enableWaveAnimation = true,
    this.enableParticleBackground = true,
    this.autoStart = false,
    this.maxDuration = 30,
    this.language,
    this.supportedLanguages = const ['en-US', 'es-ES', 'fr-FR'],
    this.showTranscript = true,
    this.enableCommands = true,
  });

  @override
  State<VoiceSearchWidget> createState() => _VoiceSearchWidgetState();
}

class _VoiceSearchWidgetState extends State<VoiceSearchWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _fadeController;
  
  VoiceSearchState _currentState = VoiceSearchState.idle;
  String _transcript = '';
  final String _finalTranscript = '';
  double _confidence = 0.0;
  String _selectedLanguage = 'en-US';
  Timer? _timeoutTimer;
  Timer? _confidenceTimer;
  final List<VoiceCommand> _recognizedCommands = [];
  
  // Mock speech recognition for demo purposes
  bool _isListening = false;
  int _listeningDuration = 0;
  
  @override
  void initState() {
    super.initState();
    
    _selectedLanguage = widget.language ?? widget.supportedLanguages.first;
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startListening();
      });
    }
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    _timeoutTimer?.cancel();
    _confidenceTimer?.cancel();
    _stopListening();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Stack(
        children: [
          // Particle background
          if (widget.enableParticleBackground)
            ParticleBackground.subtle(
              child: Container(),
            ),
          
          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeController,
              child: _buildVoiceSearchContent(context),
            ),
          ),
          
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GlassmorphicContainer.button(
              onTap: _handleClose,
              child: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoiceSearchContent(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingL),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                _getStateTitle(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppConstants.spacingXL),
              
              // Voice visualization
              _buildVoiceVisualization(context),
              
              const SizedBox(height: AppConstants.spacingXL),
              
              // Transcript
              if (widget.showTranscript && _transcript.isNotEmpty)
                _buildTranscript(context),
              
              // Language selector
              if (_currentState == VoiceSearchState.idle)
                _buildLanguageSelector(context),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Controls
              _buildControls(context),
              
              const SizedBox(height: AppConstants.spacingM),
              
              // Status text
              _buildStatusText(context),
              
              // Commands help
              if (widget.enableCommands && _currentState == VoiceSearchState.idle)
                _buildCommandsHelp(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVoiceVisualization(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          
          // Pulse animation
          if (_currentState == VoiceSearchState.listening && widget.enableWaveAnimation)
            _buildPulseAnimation(context),
          
          // Wave animation
          if (_currentState == VoiceSearchState.listening && widget.enableWaveAnimation)
            _buildWaveAnimation(context),
          
          // Microphone icon
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getMicrophoneColor(context),
                boxShadow: [
                  BoxShadow(
                    color: _getMicrophoneColor(context).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _getMicrophoneIcon(),
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          
          // Recording indicator
          if (_currentState == VoiceSearchState.listening)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: AppConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Text(
                      'REC',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPulseAnimation(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 200 * (1 + _pulseController.value * 0.2),
          height: 200 * (1 + _pulseController.value * 0.2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(
                0.5 * (1 - _pulseController.value),
              ),
              width: 2,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildWaveAnimation(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 180),
          painter: VoiceWavePainter(
            animationValue: _waveController.value,
            color: Theme.of(context).colorScheme.primary,
            amplitude: _confidence,
          ),
        );
      },
    );
  }
  
  Widget _buildTranscript(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.transcribe,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppConstants.spacingXS),
              Text(
                'Transcript',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_confidence > 0)
                Text(
                  '${(_confidence * 100).round()}% confident',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            _transcript.isEmpty ? 'Start speaking...' : _transcript,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguageSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          items: widget.supportedLanguages.map((language) {
            return DropdownMenuItem(
              value: language,
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(_getLanguageName(language)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedLanguage = value;
              });
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildControls(BuildContext context) {
    switch (_currentState) {
      case VoiceSearchState.idle:
        return ElevatedButton.icon(
          onPressed: _startListening,
          icon: const Icon(Icons.mic),
          label: const Text('Start Voice Search'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 48),
          ),
        );
      
      case VoiceSearchState.listening:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: _stopListening,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
            ElevatedButton.icon(
              onPressed: _processSearch,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
          ],
        );
      
      case VoiceSearchState.processing:
        return const LoadingStates(
          type: LoadingType.spinner,
          size: LoadingSize.small,
          message: 'Processing...',
        );
      
      case VoiceSearchState.error:
        return ElevatedButton.icon(
          onPressed: _startListening,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }
  
  Widget _buildStatusText(BuildContext context) {
    return Text(
      _getStatusText(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }
  
  Widget _buildCommandsHelp(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Voice Commands',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        ...VoiceCommand.defaultCommands.map((command) {
          return ListTile(
            leading: Icon(command.icon, size: 16),
            title: Text(
              '"${command.phrase}"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            subtitle: Text(
              command.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }),
      ],
    );
  }
  
  void _toggleListening() {
    if (_currentState == VoiceSearchState.listening) {
      _stopListening();
    } else {
      _startListening();
    }
  }
  
  void _startListening() {
    setState(() {
      _currentState = VoiceSearchState.listening;
      _transcript = '';
      _confidence = 0.0;
      _listeningDuration = 0;
    });
    
    widget.onSearchStarted?.call();
    
    // Start animations
    _pulseController.repeat();
    _waveController.repeat();
    
    // Start mock speech recognition
    _isListening = true;
    _startMockRecognition();
    
    // Set timeout
    _timeoutTimer = Timer(Duration(seconds: widget.maxDuration), () {
      _stopListening();
    });
  }
  
  void _stopListening() {
    setState(() {
      _currentState = VoiceSearchState.idle;
      _isListening = false;
    });
    
    widget.onSearchStopped?.call();
    
    // Stop animations
    _pulseController.stop();
    _waveController.stop();
    
    _timeoutTimer?.cancel();
    _confidenceTimer?.cancel();
  }
  
  void _processSearch() {
    if (_transcript.isEmpty) return;
    
    setState(() {
      _currentState = VoiceSearchState.processing;
    });
    
    _pulseController.stop();
    _waveController.stop();
    
    // Check for voice commands first
    if (widget.enableCommands) {
      final command = _detectVoiceCommand(_transcript);
      if (command != null) {
        _executeVoiceCommand(command);
        return;
      }
    }
    
    // Process as search query
    Timer(const Duration(seconds: 1), () {
      widget.onSearchResult?.call(_transcript);
      _handleClose();
    });
  }
  
  void _startMockRecognition() {
    // Mock speech recognition with realistic updates
    _confidenceTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      
      _listeningDuration += 200;
      
      // Simulate speech recognition updates
      if (_listeningDuration > 1000 && _listeningDuration < 5000) {
        final mockPhrases = [
          'wireless',
          'wireless headphones',
          'wireless headphones bluetooth',
          'wireless headphones bluetooth noise',
          'wireless headphones bluetooth noise canceling',
        ];
        
        final index = math.min(
          (_listeningDuration - 1000) ~/ 800,
          mockPhrases.length - 1,
        );
        
        setState(() {
          _transcript = mockPhrases[index];
          _confidence = math.min(0.3 + (_listeningDuration / 10000), 0.95);
        });
      }
    });
  }
  
  VoiceCommand? _detectVoiceCommand(String transcript) {
    final lowerTranscript = transcript.toLowerCase();
    
    for (final command in VoiceCommand.defaultCommands) {
      if (lowerTranscript.contains(command.phrase.toLowerCase())) {
        return command;
      }
    }
    
    return null;
  }
  
  void _executeVoiceCommand(VoiceCommand command) {
    setState(() {
      _currentState = VoiceSearchState.processing;
    });
    
    // Execute command after a short delay
    Timer(const Duration(milliseconds: 500), () {
      switch (command.action) {
        case VoiceCommandAction.search:
          widget.onSearchResult?.call(_transcript);
          break;
        case VoiceCommandAction.navigate:
          // Handle navigation commands
          break;
        case VoiceCommandAction.filter:
          // Handle filter commands
          break;
        case VoiceCommandAction.close:
          _handleClose();
          return;
      }
      
      _handleClose();
    });
  }
  
  void _handleClose() {
    _fadeController.reverse().then((_) {
      widget.onClose?.call();
      Navigator.of(context).pop();
    });
  }
  
  String _getStateTitle() {
    switch (_currentState) {
      case VoiceSearchState.idle:
        return 'Voice Search';
      case VoiceSearchState.listening:
        return 'Listening...';
      case VoiceSearchState.processing:
        return 'Processing...';
      case VoiceSearchState.error:
        return 'Error';
    }
  }
  
  String _getStatusText() {
    switch (_currentState) {
      case VoiceSearchState.idle:
        return 'Tap the microphone to start voice search';
      case VoiceSearchState.listening:
        return 'Speak now... (${widget.maxDuration - _listeningDuration ~/ 1000}s remaining)';
      case VoiceSearchState.processing:
        return 'Processing your request...';
      case VoiceSearchState.error:
        return 'Unable to process voice input. Please try again.';
    }
  }
  
  Color _getMicrophoneColor(BuildContext context) {
    switch (_currentState) {
      case VoiceSearchState.idle:
        return Theme.of(context).colorScheme.primary;
      case VoiceSearchState.listening:
        return Colors.red;
      case VoiceSearchState.processing:
        return Theme.of(context).colorScheme.tertiary;
      case VoiceSearchState.error:
        return Theme.of(context).colorScheme.error;
    }
  }
  
  IconData _getMicrophoneIcon() {
    switch (_currentState) {
      case VoiceSearchState.idle:
        return Icons.mic;
      case VoiceSearchState.listening:
        return Icons.mic;
      case VoiceSearchState.processing:
        return Icons.hourglass_top;
      case VoiceSearchState.error:
        return Icons.mic_off;
    }
  }
  
  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en-US':
        return 'English (US)';
      case 'es-ES':
        return 'Español';
      case 'fr-FR':
        return 'Français';
      case 'de-DE':
        return 'Deutsch';
      case 'it-IT':
        return 'Italiano';
      case 'pt-BR':
        return 'Português';
      default:
        return languageCode;
    }
  }
}

/// Voice search states
enum VoiceSearchState {
  idle,
  listening,
  processing,
  error,
}

/// Voice command model
class VoiceCommand {
  final String phrase;
  final String description;
  final VoiceCommandAction action;
  final IconData icon;
  final Map<String, dynamic>? parameters;

  const VoiceCommand({
    required this.phrase,
    required this.description,
    required this.action,
    required this.icon,
    this.parameters,
  });

  static const List<VoiceCommand> defaultCommands = [
    VoiceCommand(
      phrase: 'search for',
      description: 'Search for products',
      action: VoiceCommandAction.search,
      icon: Icons.search,
    ),
    VoiceCommand(
      phrase: 'show me',
      description: 'Show specific products',
      action: VoiceCommandAction.search,
      icon: Icons.visibility,
    ),
    VoiceCommand(
      phrase: 'find',
      description: 'Find products',
      action: VoiceCommandAction.search,
      icon: Icons.find_in_page,
    ),
    VoiceCommand(
      phrase: 'go to cart',
      description: 'Navigate to shopping cart',
      action: VoiceCommandAction.navigate,
      icon: Icons.shopping_cart,
    ),
    VoiceCommand(
      phrase: 'close',
      description: 'Close voice search',
      action: VoiceCommandAction.close,
      icon: Icons.close,
    ),
  ];
}

/// Voice command actions
enum VoiceCommandAction {
  search,
  navigate,
  filter,
  close,
}

/// Custom painter for voice wave animation
class VoiceWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double amplitude;

  VoiceWavePainter({
    required this.animationValue,
    required this.color,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 4;

    // Draw multiple wave circles
    for (int i = 0; i < 3; i++) {
      final phase = (animationValue * 2 * math.pi) + (i * math.pi / 3);
      final waveRadius = baseRadius + (amplitude * 20 * math.sin(phase));
      
      canvas.drawCircle(
        center,
        waveRadius + (i * 10),
        paint..color = color.withOpacity(0.3 - (i * 0.1)),
      );
    }
  }

  @override
  bool shouldRepaint(VoiceWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.amplitude != amplitude;
  }
}