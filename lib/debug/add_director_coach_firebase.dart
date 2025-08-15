import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firebase/firebase_avatar.dart';
import '../providers/firebase/firebase_avatar_provider.dart';

/// Debug utility to manually add director_coach to Firebase
class AddDirectorCoachFirebase extends ConsumerStatefulWidget {
  const AddDirectorCoachFirebase({super.key});

  @override
  ConsumerState<AddDirectorCoachFirebase> createState() => _AddDirectorCoachFirebaseState();
}

class _AddDirectorCoachFirebaseState extends ConsumerState<AddDirectorCoachFirebase> {
  String _status = 'Ready to add Director Coach to Firebase';
  bool _isLoading = false;

  Future<void> _createAllDefaultAvatars() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating all default avatars using Firebase Avatar Service...';
    });

    try {
      final avatarService = ref.read(firebaseAvatarServiceProvider);
      await avatarService.forceCreateDefaultAvatars();
      
      setState(() {
        _status = '✅ All default avatars created successfully!\n\n'
                 'This includes:\n'
                 '- mummy_coach\n'
                 '- quantum_coach\n'
                 '- director_coach\n\n'
                 'Check the avatar store to see all available avatars.';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Error creating default avatars:\n\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addDirectorCoachToFirebase() async {
    setState(() {
      _isLoading = true;
      _status = 'Adding Director Coach to Firebase...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Check if director_coach already exists
      final existingDoc = await firestore.collection('avatars').doc('director_coach').get();
      
      if (existingDoc.exists) {
        setState(() {
          _status = '⚠️ Director Coach already exists in Firebase!\n\nExisting data:\n${existingDoc.data()}';
          _isLoading = false;
        });
        return;
      }
      
      // Create director_coach avatar data with correct SMITriggers
      final directorCoach = FirebaseAvatar(
        avatarId: 'director_coach',
        name: 'Director Coach',
        description: 'Charismatic fitness director with Hollywood style. Commands your workout like an epic movie scene. Features full customization and professional animations.',
        rivAssetPath: 'assets/rive/director_coach.riv',
        availableAnimations: ['starAct_Touch', 'Act_Touch', 'Act_1', 'back_in', 'win', 'jump'], // Actual SMITriggers
        customProperties: {
          'hasComplexSequence': true,
          'supportsTeleport': false,
          'hasCustomization': true, // Enable customization system
          'customizationTypes': ['eyes', 'face', 'skin', 'clothing', 'accessories', 'hair'],
          'sequenceOrder': ['starAct_Touch', 'jump', 'Act_Touch', 'Act_1', 'win'], // Use actual triggers
          'useStateMachine': true, // Uses State Machine 1 for advanced features
          'theme': 'movie_director',
          'eyeColors': 10, // eye 0 through eye 9
          'stateMachineInputs': {
            'triggers': ['starAct_Touch', 'Act_Touch', 'Act_1', 'back_in', 'win', 'jump'],
            'booleans': ['jumpright_check', 'home', 'flower_check'],
            'numbers': ['stateaction', 'flower_state']
          },
        },
        price: 0, // Free for testing
        rarity: 'legendary', // Upgraded to legendary due to customization features
        isPurchasable: true,
        requiredAchievements: [],
        releaseDate: DateTime(2024, 8, 14),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Add to Firestore
      await firestore
          .collection('avatars')
          .doc('director_coach')
          .set(directorCoach.toFirestore());
      
      // Verify it was added
      final verificationDoc = await firestore.collection('avatars').doc('director_coach').get();
      
      if (verificationDoc.exists) {
        final data = verificationDoc.data() as Map<String, dynamic>;
        setState(() {
          _status = '✅ Director Coach added successfully!\n\n'
                   'Avatar ID: director_coach\n'
                   'Name: ${data['name']}\n'
                   'Price: ${data['price']} (Free)\n'
                   'Animations: ${(data['availableAnimations'] as List).join(', ')}\n'
                   'Created: ${DateTime.now().toLocal()}\n\n'
                   'The avatar should now appear in the avatar store!';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = '❌ Verification failed: Avatar not found after creation';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      setState(() {
        _status = '❌ Error adding Director Coach to Firebase:\n\n$e\n\n'
                 'Make sure you have proper Firebase permissions.';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkExistingAvatars() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking existing avatars in Firebase...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('avatars').get();
      
      final avatars = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        avatars.add('${doc.id}: ${data['name']} (${data['price']} coins)');
      }
      
      setState(() {
        _status = '📋 Current avatars in Firebase (${avatars.length} total):\n\n'
                 '${avatars.join('\n')}\n\n'
                 '${avatars.any((a) => a.contains('director_coach')) ? '✅ Director Coach already exists' : '❌ Director Coach not found'}';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Error checking avatars: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Director Coach to Firebase'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.movie,
                      size: 48,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Director Coach Firebase Utility',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add the Director Coach avatar to your Firebase avatars collection',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkExistingAvatars,
              icon: const Icon(Icons.search),
              label: const Text('Check Existing Avatars'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createAllDefaultAvatars,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Create All Default Avatars'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _addDirectorCoachToFirebase,
              icon: const Icon(Icons.add),
              label: const Text('Add Director Coach Only'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status Display
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Processing...'),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          _status,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}