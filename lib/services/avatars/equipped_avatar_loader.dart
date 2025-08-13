import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../providers/riverpod/avatar_state_provider.dart';
import '../../widgets/avatar_display.dart';

final log = Logger('EquippedAvatarLoader');

/// Loads only the equipped avatar from the store, not default ones
class EquippedAvatarLoader extends ConsumerWidget {
  final GlobalKey<AvatarDisplayState>? avatarKey;
  final double width;
  final double height;
  final BoxFit fit;
  final bool autoPlaySequence;
  final Duration? sequenceDelay;
  final VoidCallback? onTap;

  const EquippedAvatarLoader({
    super.key,
    this.avatarKey,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.autoPlaySequence = false,
    this.sequenceDelay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarState = ref.watch(avatarStateProvider);

    return avatarState.when(
      data: (state) {
        final equippedAvatarId = state.equippedAvatarId ?? 'classic_coach';
        log.info('📱 Loading equipped avatar: $equippedAvatarId');
        
        // Only load the equipped avatar, not multiple ones
        return _buildEquippedAvatar(equippedAvatarId);
      },
      loading: () => _buildLoadingPlaceholder(),
      error: (error, stack) {
        log.warning('⚠️ Error loading avatar state: $error');
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildEquippedAvatar(String equippedAvatarId) {
    try {
      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: AvatarDisplay(
            key: avatarKey,
            width: width,
            height: height,
            fit: fit,
            autoPlaySequence: autoPlaySequence,
            sequenceDelay: sequenceDelay ?? const Duration(seconds: 2),
            preferEquipped: true, // Always prioritize equipped avatar
            // AvatarDisplay automatically loads equipped avatar from state
          ),
        ),
      );
    } catch (e) {
      log.warning('⚠️ Error building equipped avatar $equippedAvatarId: $e');
      return _buildErrorPlaceholder();
    }
  }


  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withValues(alpha: 0.3),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red.withValues(alpha: 0.2),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Icon(
        Icons.error_outline,
        color: Colors.red,
        size: width * 0.4,
      ),
    );
  }
}