import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/app_initialization_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start background initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppInitializationService().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AppInitializationService>(
        builder: (context, initService, child) {
          // Navigate to home when initialization is complete
          if (initService.isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Simple logo/title
                const Icon(
                  Icons.shopping_bag,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Marketplace Algeria',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Loading indicator
                if (initService.isInitializing) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialisation...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
                
                // Error handling
                if (initService.error != null) ...[
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur d\'initialisation',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => initService.initialize(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}