import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;

import '../core/config/app_constants.dart';
import '../models/product.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';
import '../widgets/particle_background.dart';

/// Comprehensive barcode scanner widget for product identification
class BarcodeScannerWidget extends StatefulWidget {
  final Function(String, Product?)? onBarcodeScanned;
  final Function(String)? onBarcodeDetected;
  final Function(String)? onError;
  final VoidCallback? onClose;
  final bool enableFlashlight;
  final bool enableGallery;
  final bool enableManualEntry;
  final bool showInstructions;
  final bool enableVibration;
  final bool enableSound;
  final List<BarcodeFormat> supportedFormats;
  final Duration scanDelay;
  final bool continuousScanning;

  const BarcodeScannerWidget({
    super.key,
    this.onBarcodeScanned,
    this.onBarcodeDetected,
    this.onError,
    this.onClose,
    this.enableFlashlight = true,
    this.enableGallery = true,
    this.enableManualEntry = true,
    this.showInstructions = true,
    this.enableVibration = true,
    this.enableSound = true,
    this.supportedFormats = const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upca,
      BarcodeFormat.upce,
      BarcodeFormat.qr,
    ],
    this.scanDelay = const Duration(milliseconds: 500),
    this.continuousScanning = false,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget>
    with TickerProviderStateMixin {
  late AnimationController _scanlineController;
  late AnimationController _cornerController;
  late AnimationController _fadeController;
  
  BarcodeScannerState _currentState = BarcodeScannerState.scanning;
  bool _isFlashlightOn = false;
  String? _scannedBarcode;
  Product? _foundProduct;
  String? _errorMessage;
  Timer? _scanTimer;
  
  @override
  void initState() {
    super.initState();
    
    _scanlineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _cornerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _startScanning();
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _scanlineController.dispose();
    _cornerController.dispose();
    _fadeController.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview (mock)
          _buildCameraPreview(context),
          
          // Scanner overlay
          _buildScannerOverlay(context),
          
          // Top controls
          _buildTopControls(context),
          
          // Bottom controls
          _buildBottomControls(context),
          
          // Result overlay
          if (_currentState == BarcodeScannerState.success ||
              _currentState == BarcodeScannerState.error)
            _buildResultOverlay(context),
        ],
      ),
    );
  }
  
  Widget _buildCameraPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a1a),
            Color(0xFF2a2a2a),
            Color(0xFF1a1a1a),
          ],
        ),
      ),
      child: ParticleBackground.subtle(
        child: Container(),
      ),
    );
  }
  
  Widget _buildScannerOverlay(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        child: Stack(
          children: [
            // Scanner frame
            CustomPaint(
              size: const Size(280, 280),
              painter: ScannerFramePainter(
                cornerAnimation: _cornerController,
                isActive: _currentState == BarcodeScannerState.scanning,
              ),
            ),
            
            // Scanning line
            if (_currentState == BarcodeScannerState.scanning)
              AnimatedBuilder(
                animation: _scanlineController,
                builder: (context, child) {
                  return Positioned(
                    left: 20,
                    right: 20,
                    top: 20 + (240 * _scanlineController.value),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Theme.of(context).colorScheme.primary,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            
            // Corner indicators
            _buildCornerIndicators(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCornerIndicators(BuildContext context) {
    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 10,
          left: 10,
          child: _buildCornerIndicator(context, Alignment.topLeft),
        ),
        // Top-right
        Positioned(
          top: 10,
          right: 10,
          child: _buildCornerIndicator(context, Alignment.topRight),
        ),
        // Bottom-left
        Positioned(
          bottom: 10,
          left: 10,
          child: _buildCornerIndicator(context, Alignment.bottomLeft),
        ),
        // Bottom-right
        Positioned(
          bottom: 10,
          right: 10,
          child: _buildCornerIndicator(context, Alignment.bottomRight),
        ),
      ],
    );
  }
  
  Widget _buildCornerIndicator(BuildContext context, Alignment alignment) {
    return AnimatedBuilder(
      animation: _cornerController,
      builder: (context, child) {
        return Container(
          width: 30,
          height: 30,
          child: CustomPaint(
            painter: CornerIndicatorPainter(
              alignment: alignment,
              color: Theme.of(context).colorScheme.primary,
              animationValue: _cornerController.value,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTopControls(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            GlassmorphicContainer.button(
              onTap: _handleClose,
              child: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
            
            // Title
            Text(
              'Scan Barcode',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Flashlight toggle
            if (widget.enableFlashlight)
              GlassmorphicContainer.button(
                onTap: _toggleFlashlight,
                child: Icon(
                  _isFlashlightOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashlightOn ? Colors.yellow : Colors.white,
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomControls(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: AppConstants.spacingM,
          right: AppConstants.spacingM,
          top: AppConstants.spacingM,
          bottom: AppConstants.spacingM + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instructions
            if (widget.showInstructions && _currentState == BarcodeScannerState.scanning)
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                ),
                child: Text(
                  'Position the barcode within the frame and hold steady',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                if (widget.enableGallery)
                  _buildActionButton(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    _openGallery,
                  ),
                
                // Manual entry button
                if (widget.enableManualEntry)
                  _buildActionButton(
                    context,
                    Icons.keyboard,
                    'Manual',
                    _openManualEntry,
                  ),
                
                // Help button
                _buildActionButton(
                  context,
                  Icons.help_outline,
                  'Help',
                  _showHelp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GlassmorphicContainer.button(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: FadeTransition(
          opacity: _fadeController,
          child: Container(
            margin: const EdgeInsets.all(AppConstants.spacingL),
            child: GlassmorphicContainer.card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: _currentState == BarcodeScannerState.success
                    ? _buildSuccessContent(context)
                    : _buildErrorContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSuccessContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 32,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingL),
        
        // Title
        Text(
          'Product Found!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingM),
        
        // Barcode
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                _scannedBarcode ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingL),
        
        // Product info
        if (_foundProduct != null) ...[
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(
                  _getCategoryIcon(_foundProduct!.category),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _foundProduct!.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${_foundProduct!.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
        ],
        
        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _continueScanningIfEnabled,
                child: const Text('Scan Again'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onBarcodeScanned?.call(_scannedBarcode!, _foundProduct);
                  _handleClose();
                },
                child: const Text('View Product'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildErrorContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Error icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 32,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingL),
        
        // Title
        Text(
          'Product Not Found',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingM),
        
        // Error message
        Text(
          _errorMessage ?? 'The scanned barcode was not found in our database.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppConstants.spacingL),
        
        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _continueScanningIfEnabled,
                child: const Text('Try Again'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: ElevatedButton(
                onPressed: _openManualEntry,
                child: const Text('Manual Search'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _startScanning() {
    setState(() {
      _currentState = BarcodeScannerState.scanning;
    });
    
    _scanlineController.repeat();
    _cornerController.repeat(reverse: true);
    
    // Simulate barcode detection after a delay
    _scanTimer = Timer(const Duration(seconds: 3), () {
      _simulateBarcodeDetection();
    });
  }
  
  void _simulateBarcodeDetection() {
    final mockBarcodes = [
      '1234567890123', // EAN-13
      '123456789012',  // UPC-A
      '12345678',      // EAN-8
    ];
    
    final randomBarcode = mockBarcodes[math.Random().nextInt(mockBarcodes.length)];
    
    _onBarcodeDetected(randomBarcode);
  }
  
  void _onBarcodeDetected(String barcode) {
    if (widget.enableVibration) {
      HapticFeedback.mediumImpact();
    }
    
    widget.onBarcodeDetected?.call(barcode);
    
    setState(() {
      _scannedBarcode = barcode;
      _currentState = BarcodeScannerState.processing;
    });
    
    _scanlineController.stop();
    _cornerController.stop();
    
    // Simulate product lookup
    Timer(const Duration(seconds: 1), () {
      _lookupProduct(barcode);
    });
  }
  
  void _lookupProduct(String barcode) {
    // Mock product lookup
    final random = math.Random();
    final isProductFound = random.nextBool();
    
    if (isProductFound) {
      // Return a mock product
      setState(() {
        _foundProduct = MockProducts.trendingProducts[random.nextInt(MockProducts.trendingProducts.length)];
        _currentState = BarcodeScannerState.success;
      });
    } else {
      setState(() {
        _errorMessage = 'Barcode $barcode not found in our product database.';
        _currentState = BarcodeScannerState.error;
      });
      widget.onError?.call(_errorMessage!);
    }
  }
  
  void _toggleFlashlight() {
    setState(() {
      _isFlashlightOn = !_isFlashlightOn;
    });
    
    // In a real implementation, you would control the camera flash here
  }
  
  void _openGallery() {
    // In a real implementation, you would open the photo gallery here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery feature would open photo library to scan barcode from image'),
      ),
    );
  }
  
  void _openManualEntry() {
    showDialog(
      context: context,
      builder: (context) => _ManualBarcodeEntryDialog(
        onBarcodeEntered: (barcode) {
          Navigator.pop(context);
          _onBarcodeDetected(barcode);
        },
      ),
    );
  }
  
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcode Scanner Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tips for better scanning:'),
            const SizedBox(height: 8),
            const Text('• Hold the device steady'),
            const Text('• Ensure good lighting'),
            const Text('• Keep barcode within the frame'),
            const Text('• Clean the camera lens'),
            const Text('• Try different angles if needed'),
            const SizedBox(height: 16),
            Text(
              'Supported formats: ${widget.supportedFormats.map((f) => f.name).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
  
  void _continueScanningIfEnabled() {
    if (widget.continuousScanning) {
      _startScanning();
    } else {
      _handleClose();
    }
  }
  
  void _handleClose() {
    _fadeController.reverse().then((_) {
      widget.onClose?.call();
      Navigator.of(context).pop();
    });
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fashion':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices;
      case 'computers':
        return Icons.laptop;
      case 'beauty':
        return Icons.palette;
      case 'sports':
        return Icons.sports;
      case 'home':
        return Icons.home;
      case 'books':
        return Icons.book;
      default:
        return Icons.shopping_bag;
    }
  }
}

/// Manual barcode entry dialog
class _ManualBarcodeEntryDialog extends StatefulWidget {
  final Function(String) onBarcodeEntered;

  const _ManualBarcodeEntryDialog({
    required this.onBarcodeEntered,
  });

  @override
  State<_ManualBarcodeEntryDialog> createState() => _ManualBarcodeEntryDialogState();
}

class _ManualBarcodeEntryDialogState extends State<_ManualBarcodeEntryDialog> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Barcode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Type or paste the barcode number:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Barcode',
              hintText: 'e.g., 1234567890123',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final barcode = _controller.text.trim();
            if (barcode.isNotEmpty) {
              widget.onBarcodeEntered(barcode);
            }
          },
          child: const Text('Search'),
        ),
      ],
    );
  }
}

/// Barcode scanner states
enum BarcodeScannerState {
  scanning,
  processing,
  success,
  error,
}

/// Supported barcode formats
enum BarcodeFormat {
  ean13,
  ean8,
  upca,
  upce,
  qr,
  code128,
  code39,
  pdf417,
}

/// Scanner frame painter
class ScannerFramePainter extends CustomPainter {
  final AnimationController cornerAnimation;
  final bool isActive;

  ScannerFramePainter({
    required this.cornerAnimation,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? Colors.green : Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;
    final animatedLength = cornerLength * cornerAnimation.value;

    // Draw corner brackets
    _drawCorner(canvas, paint, Offset.zero, animatedLength, true, true);
    _drawCorner(canvas, paint, Offset(size.width, 0), animatedLength, false, true);
    _drawCorner(canvas, paint, Offset(0, size.height), animatedLength, true, false);
    _drawCorner(canvas, paint, Offset(size.width, size.height), animatedLength, false, false);
  }

  void _drawCorner(Canvas canvas, Paint paint, Offset corner, double length, bool left, bool top) {
    final path = Path();
    
    if (left && top) {
      path.moveTo(corner.dx, corner.dy + length);
      path.lineTo(corner.dx, corner.dy);
      path.lineTo(corner.dx + length, corner.dy);
    } else if (!left && top) {
      path.moveTo(corner.dx - length, corner.dy);
      path.lineTo(corner.dx, corner.dy);
      path.lineTo(corner.dx, corner.dy + length);
    } else if (left && !top) {
      path.moveTo(corner.dx + length, corner.dy);
      path.lineTo(corner.dx, corner.dy);
      path.lineTo(corner.dx, corner.dy - length);
    } else {
      path.moveTo(corner.dx, corner.dy - length);
      path.lineTo(corner.dx, corner.dy);
      path.lineTo(corner.dx - length, corner.dy);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ScannerFramePainter oldDelegate) {
    return oldDelegate.cornerAnimation.value != cornerAnimation.value ||
           oldDelegate.isActive != isActive;
  }
}

/// Corner indicator painter
class CornerIndicatorPainter extends CustomPainter {
  final Alignment alignment;
  final Color color;
  final double animationValue;

  CornerIndicatorPainter({
    required this.alignment,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(animationValue)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final length = 15.0;
    final path = Path();

    if (alignment == Alignment.topLeft) {
      path.moveTo(0, length);
      path.lineTo(0, 0);
      path.lineTo(length, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(size.width - length, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, length);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(length, size.height);
      path.lineTo(0, size.height);
      path.lineTo(0, size.height - length);
    } else if (alignment == Alignment.bottomRight) {
      path.moveTo(size.width, size.height - length);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width - length, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CornerIndicatorPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}