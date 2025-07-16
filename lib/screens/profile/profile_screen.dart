import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/modern_profile_header.dart';
import 'widgets/modern_action_grid.dart';
import 'widgets/modern_achievements_section.dart';
import 'widgets/modern_weekly_summary.dart';
import '../../theme/app_theme.dart';
import '../../providers/riverpod/user_profile_provider.dart';
import '../../services/social_service.dart';
import '../../models/supporter.dart';
import 'supporter_requests_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final SocialService _socialService = SocialService();

  @override
  void initState() {
    super.initState();
    // Removed refreshSupporterCount() call to prevent navigation reset
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: userProfileAsync.when(
          data: (userProfile) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ModernProfileHeader(),
                _buildSupporterRequestNotification(context),
                const SizedBox(height: 8),
                const ModernWeeklySummary(),
                const SizedBox(height: 24),
                const ModernActionGrid(),
                const SizedBox(height: 24),
                const ModernAchievementsSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(userProfileNotifierProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupporterRequestNotification(BuildContext context) {
    return StreamBuilder<List<SupporterRequest>>(
      stream: _socialService.getPendingSupporterRequests(),
      builder: (context, snapshot) {
        final pendingRequests = snapshot.data ?? [];
        
        if (pendingRequests.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final count = pendingRequests.length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupporterRequestsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withAlpha(76),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 20,
                          ),
                          if (count > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  count > 9 ? '9+' : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            count == 1 
                                ? 'You have 1 supporter request'
                                : 'You have $count supporter requests',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to view and respond',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


}
