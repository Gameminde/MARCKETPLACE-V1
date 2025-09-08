import 'package:flutter/material.dart';

import '../widgets/voice_search_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/particle_background.dart';
import '../widgets/glassmorphic_container.dart';
import '../core/config/app_constants.dart';

/// Demo screen showcasing VoiceSearch functionality
class VoiceSearchDemoScreen extends StatefulWidget {
  const VoiceSearchDemoScreen({super.key});

  @override
  State<VoiceSearchDemoScreen> createState() => _VoiceSearchDemoScreenState();
}

class _VoiceSearchDemoScreenState extends State<VoiceSearchDemoScreen> {
  String? _lastSearchResult;
  List<String> _searchHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.detail(
        title: 'Voice Search Demo',
      ),
      body: ParticleBackground.subtle(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voice Search Button
              Center(
                child: GlassmorphicContainer.card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Text(
                          'Voice Search',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        Text(
                          'Tap to start voice search with speech-to-text',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.spacingL),
                        ElevatedButton.icon(
                          onPressed: _startVoiceSearch,
                          icon: const Icon(Icons.mic),
                          label: const Text('Start Voice Search'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Last Search Result
              if (_lastSearchResult != null)
                GlassmorphicContainer.card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Text(
                              'Last Search Result',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppConstants.spacingM),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '"$_lastSearchResult"',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Search History
              if (_searchHistory.isNotEmpty)
                GlassmorphicContainer.card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: AppConstants.spacingS),
                                Text(
                                  'Voice Search History',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchHistory.clear();
                                });
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        ..._searchHistory.reversed.take(5).map((search) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
                            child: ListTile(
                              leading: const Icon(Icons.mic, size: 20),
                              title: Text(search),
                              trailing: IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  // Trigger search with this query
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Searching for: $search'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  _lastSearchResult = search;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Features Info
              GlassmorphicContainer.card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Search Features',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildFeatureItem(
                        context,
                        Icons.transcribe,
                        'Real-time Transcription',
                        'See your speech converted to text in real-time',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.language,
                        'Multi-language Support',
                        'Support for English, Spanish, French, and more',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.voice_over_off,
                        'Voice Commands',
                        'Use natural voice commands like "search for" or "show me"',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.graphic_eq,
                        'Voice Visualization',
                        'Beautiful wave animations while listening',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.noise_control_off,
                        'Noise Handling',
                        'Advanced noise filtering for better recognition',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Demo Instructions
              GlassmorphicContainer.card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Text(
                            'How to Use',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildInstructionStep(context, '1', 'Tap the "Start Voice Search" button'),
                      _buildInstructionStep(context, '2', 'Grant microphone permission if prompted'),
                      _buildInstructionStep(context, '3', 'Speak clearly into your device'),
                      _buildInstructionStep(context, '4', 'Watch the real-time transcription'),
                      _buildInstructionStep(context, '5', 'Tap "Search" or say "search" to execute'),
                      const SizedBox(height: AppConstants.spacingM),
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Expanded(
                              child: Text(
                                'Try saying: "wireless headphones", "show me laptops", or "search for running shoes"',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstructionStep(BuildContext context, String step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              instruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  void _startVoiceSearch() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceSearchWidget(
        enableWaveAnimation: true,
        enableParticleBackground: true,
        showTranscript: true,
        enableCommands: true,
        supportedLanguages: const ['en-US', 'es-ES', 'fr-FR', 'de-DE'],
        onSearchResult: (result) {
          setState(() {
            _lastSearchResult = result;
            _searchHistory.add(result);
            // Keep only last 10 searches
            if (_searchHistory.length > 10) {
              _searchHistory.removeAt(0);
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice search result: $result'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onSearchStarted: () {
          // Handle search started
        },
        onSearchStopped: () {
          // Handle search stopped
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice search error: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        onClose: () {
          // Handle close
        },
      ),
    );
  }
}