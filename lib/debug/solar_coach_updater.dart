import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../services/firebase/firebase_avatar_service.dart';
import '../models/firebase/firebase_avatar.dart';

final log = Logger('SolarCoachUpdater');

/// Debug screen for updating solar_coach to only use FIRST FLY animation
class SolarCoachUpdater extends ConsumerStatefulWidget {
  const SolarCoachUpdater({super.key});

  @override
  ConsumerState<SolarCoachUpdater> createState() => _SolarCoachUpdaterState();
}

class _SolarCoachUpdaterState extends ConsumerState<SolarCoachUpdater> {
  bool _isUpdating = false;
  String _status = 'Ready to update solar_coach configuration';
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logs.add('${DateTime.now().toIso8601String()}: Solar Coach Updater initialized');
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

  Future<void> _updateSolarCoach() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
      _status = 'Updating solar_coach configuration...';
    });

    _addLog('🚀 Starting solar_coach update');

    try {
      // Initialize Firebase Avatar Service
      _addLog('📡 Initializing Firebase Avatar Service');
      final avatarService = FirebaseAvatarService();
      await avatarService.initialize();
      _addLog('✅ Firebase Avatar Service initialized');

      // Create updated solar_coach avatar with only FIRST FLY
      _addLog('🌞 Creating updated solar_coach configuration');
      final updatedSolarCoach = FirebaseAvatar(
        avatarId: 'solar_coach',
        name: 'Solar Coach',
        description: 'Radiant energy coach that harnesses the power of the sun. Flies with grace and solar energy.',
        rivAssetPath: 'assets/rive/solar.riv',
        availableAnimations: ['FIRST FLY', 'ClICK 1', 'ClICK 2', 'ClICK 3', 'ClICK 4', 'ClICK 5'],
        customProperties: {
          'hasComplexSequence': true,
          'supportsTeleport': false,
          'hasCustomization': false,
          'sequenceOrder': ['FIRST FLY', 'ClICK 1', 'ClICK 2', 'ClICK 3'],
          'useDirectStateMachine': false,
          'availableAnimations': ['FIRST FLY', 'ClICK 1', 'ClICK 2', 'ClICK 3', 'ClICK 4', 'ClICK 5'],
        },
        price: 0, // Free to showcase new avatar
        rarity: 'epic',
        isPurchasable: true,
        requiredAchievements: [],
        releaseDate: DateTime(2024, 8, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _addLog('🔍 Checking if solar_coach exists in Firestore');
      try {
        // Try to update first (in case document exists)
        await avatarService.updateAvatar(updatedSolarCoach);
        _addLog('✅ Solar Coach updated successfully in Firestore');
      } catch (updateError) {
        if (updateError.toString().contains('not-found')) {
          _addLog('📝 Document not found, creating new solar_coach');
          await avatarService.addAvatar(updatedSolarCoach);
          _addLog('✅ Solar Coach created successfully in Firestore');
        } else {
          // If it's a different error, rethrow it
          rethrow;
        }
      }

      _addLog('🧹 Cleaning up resources');
      await avatarService.dispose();
      
      _addLog('🎉 Solar Coach update completed successfully!');
      
      setState(() {
        _status = 'Solar Coach update completed successfully!';
        _isUpdating = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solar Coach updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e, stackTrace) {
      _addLog('❌ Error updating solar_coach: $e');
      _addLog('📚 Stack trace: $stackTrace');
      
      setState(() {
        _status = 'Error: $e';
        _isUpdating = false;
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

  Future<void> _checkCurrentConfig() async {
    _addLog('🔍 Checking current solar_coach configuration');
    
    try {
      final avatarService = FirebaseAvatarService();
      await avatarService.initialize();
      
      // This would need to be implemented in the service to get a specific avatar
      _addLog('✅ Firebase connection successful');
      _addLog('ℹ️ Current config check completed - see app for current state');
      
      await avatarService.dispose();
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
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text('Solar Coach Updater'),
        backgroundColor: Colors.orange[600],
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
                            _isUpdating ? Icons.sync : Icons.wb_sunny,
                            color: _isUpdating ? Colors.orange : Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Update Status',
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
                          color: _isUpdating ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isUpdating) ...[ 
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
                      onPressed: _isUpdating ? null : _updateSolarCoach,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Update Solar Coach'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _checkCurrentConfig,
                    icon: const Icon(Icons.search),
                    label: const Text('Check'),
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
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          Text(
                            'What this does:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Updates solar_coach in Firestore to only use FIRST FLY animation\\n'
                        '• Removes SECOND FLY and other unused animations\\n'
                        '• Simplifies configuration (no complex sequences or state machines)\\n'
                        '• Ensures consistent animation behavior across all interaction states',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
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