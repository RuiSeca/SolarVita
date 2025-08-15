import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firebase/firebase_avatar.dart';

/// Debug utility to update quantum_coach animations in Firebase
class UpdateQuantumCoachFirebase extends ConsumerStatefulWidget {
  const UpdateQuantumCoachFirebase({super.key});

  @override
  ConsumerState<UpdateQuantumCoachFirebase> createState() => _UpdateQuantumCoachFirebaseState();
}

class _UpdateQuantumCoachFirebaseState extends ConsumerState<UpdateQuantumCoachFirebase> {
  String _status = 'Ready to update Quantum Coach animations';
  bool _isLoading = false;

  Future<void> _updateQuantumCoachAnimations() async {
    setState(() {
      _isLoading = true;
      _status = 'Updating Quantum Coach animations in Firebase...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Check if quantum_coach exists
      final existingDoc = await firestore.collection('avatars').doc('quantum_coach').get();
      
      if (!existingDoc.exists) {
        setState(() {
          _status = '❌ Quantum Coach does not exist in Firebase!\nCreate it first using the default avatars creation.';
          _isLoading = false;
        });
        return;
      }
      
      // Update quantum_coach with correct SMITriggers
      await firestore.collection('avatars').doc('quantum_coach').update({
        'availableAnimations': [
          'starAct_Touch',
          'Act_Touch',
          'Act_1', 
          'back_in',
          'win',
          'jump'
        ],
        'customProperties.sequenceOrder': [
          'starAct_Touch',
          'jump',
          'Act_Touch',
          'Act_1', 
          'win'
        ],
        'customProperties.availableAnimations': [
          'starAct_Touch',
          'Act_Touch',
          'Act_1',
          'back_in',
          'win', 
          'jump'
        ],
        'customProperties.useStateMachine': true,
        'customProperties.stateMachineInputs': {
          'triggers': ['starAct_Touch', 'Act_Touch', 'Act_1', 'back_in', 'win', 'jump'],
          'booleans': ['jumpright_check', 'home', 'flower_check'],
          'numbers': ['stateaction', 'flower_state']
        },
        'description': 'Advanced AI coach with quantum customization capabilities. Teleports between activities with style.',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _status = '✅ Quantum Coach animations updated successfully!\n\n'
                 'Updated data:\n'
                 '• Removed invalid "Idle" animation\n'
                 '• Added correct SMITriggers: starAct_Touch, Act_Touch, Act_1, back_in, win, jump\n'
                 '• Set starAct_Touch as default animation\n'
                 '• Added state machine input definitions\n\n'
                 'Quantum Coach now uses the same trigger system as Director Coach!';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Error updating Quantum Coach:\n\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createQuantumCoachFromScratch() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating Quantum Coach from scratch...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Create quantum_coach avatar data with correct SMITriggers
      final quantumCoach = FirebaseAvatar(
        avatarId: 'quantum_coach',
        name: 'Quantum Coach',
        description: 'Advanced AI coach with quantum customization capabilities. Teleports between activities with style.',
        rivAssetPath: 'assets/rive/quantum_coach.riv',
        availableAnimations: ['starAct_Touch', 'Act_Touch', 'Act_1', 'back_in', 'win', 'jump'], // Actual SMITriggers
        customProperties: {
          'hasComplexSequence': true,
          'supportsTeleport': true,
          'hasCustomization': true,
          'customizationTypes': ['eyes', 'face', 'skin', 'clothing', 'accessories'],
          'sequenceOrder': ['starAct_Touch', 'jump', 'Act_Touch', 'Act_1', 'win'], // Use actual triggers
          'useStateMachine': true,
          'stateMachineInputs': {
            'triggers': ['starAct_Touch', 'Act_Touch', 'Act_1', 'back_in', 'win', 'jump'],
            'booleans': ['jumpright_check', 'home', 'flower_check'],
            'numbers': ['stateaction', 'flower_state']
          },
        },
        price: 0, // Temporarily free while currency system is being developed
        rarity: 'legendary',
        isPurchasable: true,
        requiredAchievements: [], // Made free for demo purposes
        releaseDate: DateTime(2024, 6, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Add to Firestore (overwrite if exists)
      await firestore
          .collection('avatars')
          .doc('quantum_coach')
          .set(quantumCoach.toFirestore());
      
      setState(() {
        _status = '✅ Quantum Coach created successfully!\n\n'
                 'Avatar Features:\n'
                 '• Correct SMITriggers: starAct_Touch, Act_Touch, Act_1, back_in, win, jump\n'
                 '• Advanced customization system enabled\n'
                 '• State machine inputs properly defined\n'
                 '• Same animation system as Director Coach\n\n'
                 'Both avatars now use consistent trigger systems!';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Error creating Quantum Coach:\n\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50] ?? Colors.purple.withValues(alpha: 0.1),
      appBar: AppBar(
        title: const Text('Update Quantum Coach'),
        backgroundColor: Colors.purple[600] ?? Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: 80,
                color: Colors.purple[600] ?? Colors.purple,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Quantum Coach Firebase Update',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800] ?? Colors.purple,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Update quantum_coach to use correct SMITriggers',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.purple[700] ?? Colors.purple,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Update Animations Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateQuantumCoachAnimations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600] ?? Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Animations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Create from Scratch Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createQuantumCoachFromScratch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[600] ?? Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create from Scratch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Status Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple[200] ?? Colors.purple,
                    width: 1,
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple[800] ?? Colors.purple,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Back Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Back to Maintenance',
                  style: TextStyle(
                    color: Colors.purple[600] ?? Colors.purple,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}