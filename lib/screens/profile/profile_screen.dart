import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/optimized_profile_widgets.dart';
import 'widgets/reorderable_profile_content.dart';
import '../../theme/app_theme.dart';
import '../../providers/riverpod/user_profile_provider.dart';
import '../../providers/riverpod/user_progress_provider.dart';
import '../../providers/riverpod/health_data_provider.dart';
import '../../providers/riverpod/profile_layout_provider.dart';
import '../../services/database/social_service.dart';
import '../../services/chat/data_sync_service.dart';
import '../../models/user/supporter.dart';
import 'supporter/supporter_requests_screen.dart';
import '../health/meals/meal_plan_screen.dart';
import '../../utils/translation_helper.dart';
import '../../providers/riverpod/scroll_controller_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

    // Delay data sync by 1 second to let UI load first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _syncCurrentDataToFirebase();
            _autoSyncSupporterCount();
          }
        });
      }
    });
  }

  void _initializeCachedStream() {
    _supporterRequestsStream = _socialService.getPendingSupporterRequests();
  }



  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshData() async {
    try {
      // First, sync supporter count to ensure accuracy (silent background sync)
      await _autoSyncSupporterCount();

      // Small delay to prevent jarring refresh
      await Future.delayed(const Duration(milliseconds: 100));

      // Refresh other data in parallel to speed things up
      await Future.wait([
        ref.read(userProgressNotifierProvider.notifier).refresh(),
        ref.read(healthDataNotifierProvider.notifier).syncHealthData(),
        _syncCurrentDataToFirebase(),
      ]);

      // Refresh supporter requests cache
      _initializeCachedStream();
    } catch (e) {
      // Don't block refresh on individual failures
      debugPrint('Refresh error: $e');
    }
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

  Future<void> _autoSyncSupporterCount() async {
    try {
      final wasFixed = await _socialService.autoSyncSupporterCount();
      if (wasFixed) {
        // Silently refresh the user profile without triggering loading state
        await ref
            .read(userProfileNotifierProvider.notifier)
            .silentRefreshSupporterCount();
      }
    } catch (e) {
      // Silent fail for auto-sync
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    
    // Get scroll controller directly in build method
    final scrollController = ref.read(scrollControllerNotifierProvider.notifier).getController('profile');

    final isEditMode = ref.watch(profileEditModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        bottom: false, // Allow content to flow behind nav bar
        child: Stack(
          children: [
            userProfileAsync.when(
              data: (userProfile) => RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: isEditMode 
                      ? const ClampingScrollPhysics()
                      : const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIXED HEADER SECTION - Not reorderable
                      const OptimizedProfileHeader(),
                      
                      // FIXED SUPPORTER REQUESTS - Not reorderable  
                      _SupporterRequestNotification(
                        stream: _supporterRequestsStream!,
                      ),
                      
                      // REORDERABLE CONTENT SECTION
                      const ReorderableProfileContent(),
                      
                      // Bottom padding
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
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

            // EDIT MODE OVERLAY
            const EditModeOverlay(),
          ],
        ),
      ),
      // FLOATING ACTION BUTTON FOR EDIT MODE
      floatingActionButton: const EditModeFAB(),
    );
  }
}

class _SupporterRequestNotification extends StatefulWidget {
  const _SupporterRequestNotification({required this.stream});

  final Stream<List<SupporterRequest>> stream;

  @override
  State<_SupporterRequestNotification> createState() =>
      _SupporterRequestNotificationState();
}

class _SupporterRequestNotificationState
    extends State<_SupporterRequestNotification> {
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
                            : tr(
                                context,
                                'you_have_supporter_requests',
                              ).replaceAll('{count}', count.toString()),
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

class _TodaysMealWidget extends ConsumerStatefulWidget {
  const _TodaysMealWidget();

  @override
  ConsumerState<_TodaysMealWidget> createState() => _TodaysMealWidgetState();
}

class _TodaysMealWidgetState extends ConsumerState<_TodaysMealWidget> {
  Map<String, List<Map<String, dynamic>>> _todaysMeals = {};
  bool _isLoading = true;
  int _totalMeals = 0;
  double _totalCalories = 0;

  @override
  void initState() {
    super.initState();
    _loadTodaysMeals();
  }

  Future<void> _loadTodaysMeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWeeklyData = prefs.getString('weeklyMealData');
      
      if (savedWeeklyData != null) {
        final decodedData = json.decode(savedWeeklyData);
        final today = DateTime.now();
        final todayIndex = today.weekday - 1; // Convert to 0-6 index
        final todayKey = todayIndex.toString();
        
        if (decodedData[todayKey] != null) {
          final todayData = decodedData[todayKey] as Map<String, dynamic>;
          
          setState(() {
            _todaysMeals = {};
            _totalMeals = 0;
            _totalCalories = 0;
            
            todayData.forEach((mealTime, meals) {
              if (meals is List) {
                final mealsList = meals.map((meal) => Map<String, dynamic>.from(meal)).toList();
                // Filter out suggested meals for counting
                final regularMeals = mealsList.where((meal) => meal['isSuggested'] != true).toList();
                
                _todaysMeals[mealTime] = regularMeals;
                _totalMeals += regularMeals.length;
                
                // Calculate calories for regular meals only
                for (var meal in regularMeals) {
                  final calories = double.tryParse(
                    meal['nutritionFacts']?['calories']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
                  ) ?? 0;
                  _totalCalories += calories;
                }
              }
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading today\'s meals: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getAllMealsForToday() {
    List<Map<String, dynamic>> allMeals = [];
    _todaysMeals.forEach((mealTime, meals) {
      for (var meal in meals) {
        allMeals.add({...meal, 'mealTime': mealTime});
      }
    });
    return allMeals;
  }

  Widget _buildMealImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.restaurant, size: 20, color: Colors.grey),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppTheme.cardColor(context),
            child: const Icon(Icons.restaurant, size: 20, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_totalMeals == 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealPlanScreen(),
                ),
              ).then((_) => _loadTodaysMeals()); // Refresh when coming back
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withAlpha(76),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'no_meals_planned_today'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(context, 'tap_to_add_meals'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final allMeals = _getAllMealsForToday();
    final displayMeals = allMeals.take(3).toList(); // Show max 3 meals
    final hasMoreMeals = allMeals.length > 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MealPlanScreen(),
              ),
            ).then((_) => _loadTodaysMeals()); // Refresh when coming back
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withAlpha(76),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(context, 'todays_meals'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_totalMeals ${_totalMeals == 1 ? 'meal' : 'meals'} • ${_totalCalories.toInt()} kcal',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.green,
                    ),
                  ],
                ),
                if (displayMeals.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...displayMeals.map((meal) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _buildMealImage(meal['imagePath']),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal['titleKey'] ?? meal['name'] ?? 'Unnamed Meal',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${tr(context, meal['mealTime'])} • ${meal['nutritionFacts']?['calories'] ?? '0'} kcal',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green.withAlpha(179),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (hasMoreMeals)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${allMeals.length - 3} more meals',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.withAlpha(153),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
