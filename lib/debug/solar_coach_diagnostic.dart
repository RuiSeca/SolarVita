import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase/firebase_avatar_provider.dart';
import '../config/avatar_animations_config.dart';

/// Diagnostic tool to check solar_coach Firebase state and ownership
class SolarCoachDiagnostic extends ConsumerStatefulWidget {
  const SolarCoachDiagnostic({super.key});

  @override
  ConsumerState<SolarCoachDiagnostic> createState() => _SolarCoachDiagnosticState();
}

class _SolarCoachDiagnosticState extends ConsumerState<SolarCoachDiagnostic> {
  @override
  Widget build(BuildContext context) {
    final avatarState = ref.watch(firebaseAvatarStateProvider);
    final availableAvatars = ref.watch(availableAvatarsProvider);
    final ownerships = ref.watch(userAvatarOwnershipsProvider);
    final equippedAvatar = ref.watch(equippedAvatarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Coach Diagnostic'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('🌞 SOLAR COACH CONFIGURATION', [
              'Avatar ID: solar_coach',
              'Asset Path: ${AvatarAnimationsConfig.getConfig('solar_coach')?.rivAssetPath ?? 'NOT FOUND'}',
              'Has Customization: ${AvatarAnimationsConfig.getConfig('solar_coach')?.customProperties?['hasCustomization'] ?? 'NOT SET'}',
              'Animation Stages: ${AvatarAnimationsConfig.getConfig('solar_coach')?.animations.keys.join(', ') ?? 'NONE'}',
            ]),
            
            const SizedBox(height: 20),
            
            _buildSection('🔥 FIREBASE AVATAR STATE', [
              avatarState.when(
                data: (state) => 'Equipped Avatar ID: ${state?.equippedAvatarId ?? 'NULL'}',
                loading: () => 'Loading avatar state...',
                error: (e, _) => 'ERROR: $e',
              ),
              avatarState.when(
                data: (state) => 'Has State: ${state != null}',
                loading: () => 'Loading...',
                error: (e, _) => 'ERROR loading state',
              ),
            ]),
            
            const SizedBox(height: 20),
            
            _buildSection('📋 AVAILABLE AVATARS', [
              availableAvatars.when(
                data: (avatars) {
                  final solarCoach = avatars.where((a) => a.avatarId == 'solar_coach').toList();
                  return 'Solar Coach in Firebase: ${solarCoach.isNotEmpty ? 'YES' : 'NO'}';
                },
                loading: () => 'Loading available avatars...',
                error: (e, _) => 'ERROR: $e',
              ),
              availableAvatars.when(
                data: (avatars) => 'Total Avatars: ${avatars.length}',
                loading: () => 'Loading...',
                error: (e, _) => 'ERROR',
              ),
              availableAvatars.when(
                data: (avatars) => 'Avatar IDs: ${avatars.map((a) => a.avatarId).join(', ')}',
                loading: () => 'Loading...',
                error: (e, _) => 'ERROR',
              ),
            ]),
            
            const SizedBox(height: 20),
            
            _buildSection('🎭 OWNERSHIP STATUS', [
              ownerships.when(
                data: (ownershipList) {
                  final solarOwnership = ownershipList.where((o) => o.avatarId == 'solar_coach').toList();
                  return 'Solar Coach Owned: ${solarOwnership.isNotEmpty ? 'YES' : 'NO'}';
                },
                loading: () => 'Loading ownerships...',
                error: (e, _) => 'ERROR: $e',
              ),
              ownerships.when(
                data: (ownershipList) => 'Total Owned: ${ownershipList.length}',
                loading: () => 'Loading...',
                error: (e, _) => 'ERROR',
              ),
              ownerships.when(
                data: (ownershipList) => 'Owned IDs: ${ownershipList.map((o) => o.avatarId).join(', ')}',
                loading: () => 'Loading...',
                error: (e, _) => 'ERROR',
              ),
            ]),
            
            const SizedBox(height: 20),
            
            _buildSection('⭐ EQUIPPED AVATAR', [
              'Equipped Avatar: ${equippedAvatar?.avatarId ?? 'NULL'}',
              'Equipped Name: ${equippedAvatar?.name ?? 'NULL'}',
            ]),
            
            const SizedBox(height: 20),
            
            _buildSection('🔧 DIAGNOSTIC ACTIONS', []),
            
            ElevatedButton(
              onPressed: () => _equipSolarCoach(),
              child: const Text('🌞 Try Equip Solar Coach'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () => _equipMummyCoach(),
              child: const Text('🧟 Equip Mummy Coach (Safe)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _equipSolarCoach() async {
    try {
      final service = ref.read(firebaseAvatarServiceProvider);
      await service.equipAvatar('solar_coach');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attempted to equip solar_coach')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error equipping solar_coach: $e')),
        );
      }
    }
  }

  Future<void> _equipMummyCoach() async {
    try {
      final service = ref.read(firebaseAvatarServiceProvider);
      await service.equipAvatar('mummy_coach');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipped mummy_coach (safe fallback)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error equipping mummy_coach: $e')),
        );
      }
    }
  }

  Widget _buildSection(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontFamily: 'monospace',
              ),
            ),
          )),
        ],
      ),
    );
  }
}