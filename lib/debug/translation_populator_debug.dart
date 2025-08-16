import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../utils/populate_avatar_translations.dart';
import '../services/translation/firebase_translation_service.dart';

final log = Logger('TranslationPopulatorDebug');

/// Debug screen for populating Firebase with avatar translations
class TranslationPopulatorDebug extends ConsumerStatefulWidget {
  const TranslationPopulatorDebug({super.key});

  @override
  ConsumerState<TranslationPopulatorDebug> createState() => _TranslationPopulatorDebugState();
}

class _TranslationPopulatorDebugState extends ConsumerState<TranslationPopulatorDebug> {
  bool _isPopulating = false;
  String _status = 'Ready to populate avatar translations';
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logs.add('${DateTime.now().toIso8601String()}: Translation Populator Debug initialized');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _populateTranslations() async {
    if (_isPopulating) return;

    setState(() {
      _isPopulating = true;
      _status = 'Populating avatar translations...';
    });

    _addLog('🚀 Starting avatar translation population');

    try {
      // Initialize Firebase Translation Service
      _addLog('📡 Initializing Firebase Translation Service');
      final translationService = FirebaseTranslationService();
      await translationService.initialize();
      _addLog('✅ Firebase Translation Service initialized');

      // Create populator and run
      _addLog('🌐 Creating translation populator');
      final populator = AvatarTranslationPopulator(translationService);
      
      _addLog('📝 Populating all avatar translations to Firestore');
      await populator.populateAllAvatarTranslations();
      
      _addLog('🧹 Cleaning up resources');
      await translationService.dispose();
      
      _addLog('🎉 Avatar translations populated successfully!');
      
      setState(() {
        _status = 'Translation population completed successfully!';
        _isPopulating = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar translations populated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e, stackTrace) {
      _addLog('❌ Error populating translations: $e');
      _addLog('📚 Stack trace: $stackTrace');
      
      setState(() {
        _status = 'Error: $e';
        _isPopulating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _testFirebaseConnection() async {
    _addLog('🔍 Testing Firebase connection');
    
    try {
      final translationService = FirebaseTranslationService();
      await translationService.initialize();
      _addLog('✅ Firebase connection successful');
      await translationService.dispose();
    } catch (e) {
      _addLog('❌ Firebase connection failed: $e');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _logs.add('${DateTime.now().toIso8601String()}: Logs cleared');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Translation Populator'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isPopulating ? Icons.sync : Icons.translate,
                            color: _isPopulating ? Colors.orange : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Translation Status',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _status,
                        style: TextStyle(
                          color: _isPopulating ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isPopulating) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPopulating ? null : _populateTranslations,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Populate Translations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _testFirebaseConnection,
                    icon: const Icon(Icons.wifi_outlined),
                    label: const Text('Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Logs Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Debug Logs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearLogs,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              
              // Logs List
              Expanded(
                child: Card(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: _logs.isEmpty
                        ? const Center(
                            child: Text(
                              'No logs yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              final isError = log.contains('❌');
                              final isSuccess = log.contains('✅') || log.contains('🎉');
                              final isWarning = log.contains('⚠️');
                              
                              Color textColor = Colors.black87;
                              if (isError) {
                                textColor = Colors.red[700]!;
                              } else if (isSuccess) {
                                textColor = Colors.green[700]!;
                              } else if (isWarning) {
                                textColor = Colors.orange[700]!;
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'What this does:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Populates Firestore with localized avatar data\n'
                        '• Includes names, descriptions, personality, and specialty\n'
                        '• Supports 11 languages: EN, DE, ES, FR, HI, IT, JA, KO, PT, RU, ZH\n'
                        '• Only needs to be run once per deployment',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          height: 1.4,
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}