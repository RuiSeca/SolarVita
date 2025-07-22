import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/modern_profile_header.dart';
import 'widgets/modern_action_grid.dart';
import 'widgets/modern_achievements_section.dart';
import 'widgets/modern_weekly_summary.dart';
import 'widgets/daily_goals_progress_widget.dart';
import '../../theme/app_theme.dart';
import '../../providers/riverpod/user_profile_provider.dart';
import '../../providers/riverpod/user_progress_provider.dart';
import '../../providers/riverpod/health_data_provider.dart';
import '../../services/social_service.dart';
import '../../services/data_sync_service.dart';
import '../../models/supporter.dart';
import 'supporter_requests_screen.dart';
import '../../utils/translation_helper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final SocialService _socialService = SocialService();
  Stream<List<SupporterRequest>>? _supporterRequestsStream;

  @override
  void initState() {
    super.initState();
    _initializeCachedStream();
    
    // Sync data to Firebase when profile loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCurrentDataToFirebase();
    });
  }

  void _initializeCachedStream() {
    _supporterRequestsStream = _socialService.getPendingSupporterRequests();
  }

  Future<void> _refreshData() async {
    // Refresh both user progress and health data
    await Future.wait([
      ref.read(userProgressNotifierProvider.notifier).refresh(),
      ref.read(healthDataNotifierProvider.notifier).syncHealthData(),
    ]);
    
    // Invalidate providers for refresh
    
    // Sync current data to Firebase so supporters can see it
    await _syncCurrentDataToFirebase();
    
    // Refresh supporter requests cache
    _initializeCachedStream();
  }

  Future<void> _syncCurrentDataToFirebase() async {
    try {
      final userProfile = ref.read(userProfileNotifierProvider).value;
      final userProgress = ref.read(userProgressNotifierProvider).value;
      final healthData = ref.read(healthDataNotifierProvider).value;
      
      if (userProfile != null && userProgress != null && healthData != null) {
        await DataSyncService().syncAllUserData(
          progress: userProgress,
          healthData: healthData,
          displayName: userProfile.displayName,
          avatarUrl: userProfile.photoURL,
          supporterCount: userProfile.supportersCount,
        );
      }
    } catch (e) {
      // Don't block UI on sync failures
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: userProfileAsync.when(
          data: (userProfile) => RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ModernProfileHeader(),
                _SupporterRequestNotification(stream: _supporterRequestsStream!),
                const SizedBox(height: 8),
                const DailyGoalsProgressWidget(),
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
                  tr(context, 'error_loading_profile'),
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
                  child: Text(tr(context, 'retry')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _SupporterRequestNotification extends StatefulWidget {
  const _SupporterRequestNotification({required this.stream});
  
  final Stream<List<SupporterRequest>> stream;

  @override
  State<_SupporterRequestNotification> createState() => _SupporterRequestNotificationState();
}

class _SupporterRequestNotificationState extends State<_SupporterRequestNotification> {
  List<SupporterRequest>? _cachedRequests;
  DateTime? _lastUpdate;
  
  // Cache duration - only update every 30 seconds to reduce rebuilds
  static const _cacheDuration = Duration(seconds: 30);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SupporterRequest>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        final now = DateTime.now();
        
        // Use cached data if it's recent and valid
        if (_cachedRequests != null && 
            _lastUpdate != null && 
            now.difference(_lastUpdate!) < _cacheDuration) {
          final pendingRequests = _cachedRequests!;
          
          if (pendingRequests.isEmpty) {
            return const SizedBox.shrink();
          }
          return _SupporterRequestCard(count: pendingRequests.length);
        }
        
        // Update cache with new data
        if (snapshot.hasData && snapshot.data != null) {
          _cachedRequests = snapshot.data!;
          _lastUpdate = now;
        }
        
        final pendingRequests = snapshot.data ?? _cachedRequests ?? [];
        
        if (pendingRequests.isEmpty) {
          return const SizedBox.shrink();
        }

        return _SupporterRequestCard(count: pendingRequests.length);
      },
    );
  }
}

class _SupporterRequestCard extends StatelessWidget {
  const _SupporterRequestCard({required this.count});
  
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                            ? tr(context, 'you_have_one_supporter_request')
                            : tr(context, 'you_have_supporter_requests').replaceAll('{count}', count.toString()),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr(context, 'tap_to_view_and_respond'),
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
  }
}
