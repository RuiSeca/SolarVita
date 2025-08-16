import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../services/firebase/firebase_avatar_service.dart';
import '../models/firebase/firebase_avatar.dart';

final log = Logger('AddSolarCoachFirebase');

/// Debug screen to add solar_coach to Firebase with correct animation structure
class AddSolarCoachFirebase extends ConsumerStatefulWidget {
  const AddSolarCoachFirebase({super.key});

  @override
  ConsumerState<AddSolarCoachFirebase> createState() => _AddSolarCoachFirebaseState();
}

class _AddSolarCoachFirebaseState extends ConsumerState<AddSolarCoachFirebase> {
  bool _isAdding = false;
  String _status = 'Ready to add solar_coach to Firebase';
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logs.add('${DateTime.now().toIso8601String()}: Solar Coach Firebase Adder initialized');
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

  Future<void> _addSolarCoachToFirebase() async {
    if (_isAdding) return;

    setState(() {
      _isAdding = true;
      _status = 'Adding solar_coach to Firebase...';
    });

    _addLog('🚀 Starting solar_coach Firebase addition');

    try {
      // Initialize Firebase Avatar Service
      _addLog('📡 Initializing Firebase Avatar Service');
      final avatarService = FirebaseAvatarService();
      await avatarService.initialize();
      _addLog('✅ Firebase Avatar Service initialized');

      // Create solar_coach avatar with correct animation structure
      _addLog('🌞 Creating solar_coach with actual file structure');
      final solarCoach = FirebaseAvatar(
        avatarId: 'solar_coach',
        name: 'Solar Coach',
        description: 'Radiant energy coach that harnesses the power of the sun. Features the TURTLE GOSHT artboard with flying and click animations.',
        rivAssetPath: 'assets/rive/solar.riv',
        availableAnimations: [
          'ClICK 5',    // Index 0
          'ClICK 4',    // Index 1  
          'ClICK 3',    // Index 2
          'ClICK 2',    // Index 3
          'ClICK 1',    // Index 4
          'SECOND FLY', // Index 5
          'FIRST FLY',  // Index 6
        ],
        customProperties: {
          'hasComplexSequence': true,
          'supportsTeleport': false,
          'hasCustomization': false,
          'artboardName': 'TURTLE GOSHT',
          'artboardSize': {'width': 1450.0, 'height': 1080.0},
          'sequenceOrder': ['FIRST FLY', 'ClICK 1', 'ClICK 2', 'ClICK 3'],
          'animationMapping': {
            'idle': 'FIRST FLY',
            'jump': 'ClICK 1',
            'run': 'ClICK 2', 
            'attack': 'ClICK 3',
          },
          'animationIndexes': {
            'ClICK 5': 0,
            'ClICK 4': 1,
            'ClICK 3': 2,
            'ClICK 2': 3,
            'ClICK 1': 4,
            'SECOND FLY': 5,
            'FIRST FLY': 6,
          },
          'totalAnimations': 8, // Including State Machine 1
          'hasStateMachine': true,
          'stateMachineName': 'State Machine 1',
          'theme': 'solar_energy',
        },
        price: 100, // Affordable solar coach
        rarity: 'rare',
        isPurchasable: true,
        requiredAchievements: [],
        releaseDate: DateTime(2024, 8, 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _addLog('🔍 Checking if solar_coach already exists in Firestore');
      try {
        // Try to update first (in case document exists)
        await avatarService.updateAvatar(solarCoach);
        _addLog('🔄 Solar Coach updated successfully in Firestore');
      } catch (updateError) {
        if (updateError.toString().contains('not-found')) {
          _addLog('📝 Document not found, creating new solar_coach');
          await avatarService.addAvatar(solarCoach);
          _addLog('✅ Solar Coach created successfully in Firestore');
        } else {
          // If it's a different error, rethrow it
          rethrow;
        }
      }

      _addLog('🧹 Cleaning up resources');
      await avatarService.dispose();
      
      _addLog('🎉 Solar Coach Firebase addition completed successfully!');
      _addLog('📋 Animation structure documented for: TURTLE GOSHT artboard');
      _addLog('🎬 Primary animations: FIRST FLY, ClICK 1, ClICK 2, ClICK 3');
      
      setState(() {
        _status = 'Solar Coach added to Firebase successfully!';
        _isAdding = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solar Coach added to Firebase successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e, stackTrace) {
      _addLog('❌ Error adding solar_coach to Firebase: $e');
      _addLog('📚 Stack trace: $stackTrace');
      
      setState(() {
        _status = 'Error: $e';
        _isAdding = false;
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

  Future<void> _checkFirebaseConnection() async {
    _addLog('🔍 Testing Firebase connection');
    
    try {
      final avatarService = FirebaseAvatarService();
      await avatarService.initialize();
      
      _addLog('✅ Firebase connection successful');
      _addLog('ℹ️ Ready to add solar_coach to Firestore');
      
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
        title: const Text('Add Solar Coach to Firebase'),
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
                            _isAdding ? Icons.cloud_upload : Icons.wb_sunny,
                            color: _isAdding ? Colors.orange : Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Firebase Status',
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
                          color: _isAdding ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isAdding) ...[ 
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
                      onPressed: _isAdding ? null : _addSolarCoachToFirebase,
                      icon: const Icon(Icons.add_to_photos),
                      label: const Text('Add Solar Coach'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _checkFirebaseConnection,
                    icon: const Icon(Icons.wifi_find),
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
                        '• Adds solar_coach to Firestore with correct animation structure\n'
                        '• Documents TURTLE GOSHT artboard (1450x1080)\n'
                        '• Maps animations: FIRST FLY (idle), ClICK 1-3 (actions)\n'
                        '• Sets up proper Firebase avatar data for the app\n'
                        '• Includes animation indexes and metadata for safe access',
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