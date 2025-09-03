import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/user_profile_provider.dart';
import '../../../providers/riverpod/user_progress_provider.dart';
import '../../../providers/riverpod/eco_provider.dart';
import '../../../utils/translation_helper.dart';
import '../settings/settings_main_screen.dart';
import '../../../providers/riverpod/profile_layout_provider.dart';
import '../../../models/user/user_profile.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../supporter/supporters_list_screen.dart';
import 'highlights_settings_screen.dart';

/// Modern profile header widget with user information and stats
class ModernProfileHeader extends ConsumerWidget {
  const ModernProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider);

    return userProfileAsync.when(
      data: (userProfile) {
        final displayName = userProfile?.displayName ?? 'User';
        final photoURL = userProfile?.photoURL;

        return Container(
          margin: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // Optimized background (removed BackdropFilter for performance)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile Info Row
                    Row(
                      children: [
                        // Enhanced Avatar with Status Ring
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    spreadRadius: 0,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: photoURL != null
                                  ? Container(
                                      width: 70,
                                      height: 70,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: photoURL,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 140,
                                          memCacheHeight: 140,
                                          placeholder: (context, url) =>
                                              Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.cardColor(
                                                    context,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.cardColor(
                                                    context,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 35,
                                      backgroundColor: AppTheme.cardColor(
                                        context,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: AppColors.primary,
                                      ),
                                    ),
                            ),
                            // Online Status Indicator
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withValues(
                                        alpha: 0.5,
                                      ),
                                      spreadRadius: 0,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),

                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.2),
                                      AppColors.primary.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tr(context, 'eco_enthusiast'),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.eco,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final progressAsync = ref.watch(userProgressNotifierProvider);
                                      return Text(
                                        progressAsync.when(
                                          data: (progress) => '${tr(context, 'level_number').replaceAll('{level}', progress.currentLevel.toString())} ${progress.levelTitle(context)}',
                                          loading: () => '${tr(context, 'level_number').replaceAll('{level}', ref.watch(currentLevelProvider).toString())} Loading...',
                                          error: (_, __) => '${tr(context, 'level_number').replaceAll('{level}', ref.watch(currentLevelProvider).toString())} Error',
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.textColor(
                                            context,
                                          ).withValues(alpha: 0.7),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Stats Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SupportersListScreen(),
                                  ),
                                );
                              },
                              child: _buildQuickStat(
                                context,
                                Icons.people_outline,
                                '${userProfile?.supportersCount ?? 0}',
                                tr(context, 'supporters_count'),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          Flexible(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final isShowingToday = ref.watch(ecoWidgetViewStateProvider);
                                
                                if (isShowingToday) {
                                  // Show today's CO₂ saved
                                  final todaysCarbon = ref.watch(todaysCarbonSavedProvider);
                                  return todaysCarbon.when(
                                    data: (carbon) => _buildQuickStat(
                                      context,
                                      Icons.eco_outlined,
                                      '${carbon.toStringAsFixed(1)}kg',
                                      tr(context, 'co2_saved'),
                                    ),
                                    loading: () => _buildQuickStat(
                                      context,
                                      Icons.eco_outlined,
                                      '--',
                                      tr(context, 'co2_saved'),
                                    ),
                                    error: (_, __) => _buildQuickStat(
                                      context,
                                      Icons.eco_outlined,
                                      '0.0kg',
                                      tr(context, 'co2_saved'),
                                    ),
                                  );
                                } else {
                                  // Show all-time CO₂ saved
                                  final ecoMetrics = ref.watch(userEcoMetricsProvider);
                                  return ecoMetrics.when(
                                    data: (metrics) => _buildQuickStat(
                                      context,
                                      Icons.eco_outlined,
                                      '${metrics.totalCarbonSaved.toStringAsFixed(1)}kg',
                                      tr(context, 'co2_saved'),
                                    ),
                                    loading: () => _buildQuickStat(
                                      context,
                                      Icons.eco_outlined,
                                      '--',
                                      tr(context, 'co2_saved'),
                                    ),
                                    error: (_, __) => _buildQuickStat(
                                      context,
                                      Icons.eco_outlined,
                                      '0.0kg',
                                      tr(context, 'co2_saved'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          _buildDivider(),
                          Flexible(
                            child: _buildQuickStat(
                              context,
                              Icons.local_fire_department_outlined,
                              '${ref.watch(dayStreakProvider)}',  // Changed to dayStreakProvider
                              tr(context, 'day_streak'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Menu (Three Dots)
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    _showProfileMenu(context, ref, displayName);
                  },
                  child: Icon(
                    Icons.more_horiz,
                    color: AppTheme.textColor(context),
                    size: 24,
                  ),
                ),
              ),

              // Settings Button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsMainScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: AppTheme.textColor(context),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 32,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref, String displayName) {
    final userProfileAsync = ref.read(userProfileNotifierProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => ProfileMenuBottomSheet(
        displayName: displayName,
        userProfile: userProfileAsync.value,
      ),
    );
  }
}

/// Clean, modern about section with proper Firebase integration
class UserAboutBottomSheet extends ConsumerStatefulWidget {
  final UserProfile? userProfile;
  final String displayName;

  const UserAboutBottomSheet({
    super.key,
    required this.userProfile,
    required this.displayName,
  });

  @override
  ConsumerState<UserAboutBottomSheet> createState() => _UserAboutBottomSheetState();
}

class _UserAboutBottomSheetState extends ConsumerState<UserAboutBottomSheet>
    with SingleTickerProviderStateMixin {
  late List<String> _interests;
  bool _isEditingInterests = false;
  bool _isEditingBio = false;
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _interests = List<String>.from(widget.userProfile?.interests ?? []);
    _bioController.text = widget.userProfile?.bio ?? '';
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _interestController.dispose();
    _bioController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final joinDate = widget.userProfile?.createdAt != null
        ? DateFormat('MMMM yyyy').format(widget.userProfile!.createdAt)
        : DateFormat('MMMM yyyy').format(DateTime.now());

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            margin: const EdgeInsets.only(top: 60),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Simple handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Simple header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(context, 'about_user').replaceAll('{name}', widget.displayName),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Clean content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simple member since
                        _buildSimpleInfoRow(
                          context,
                          tr(context, 'member_since'),
                          joinDate,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Bio Section
                        _buildBioSection(context),
                        
                        const SizedBox(height: 32),
                        
                        // Interests Section
                        _buildInterestsSection(context),
                        
                        if (widget.userProfile != null) ...[
                          const SizedBox(height: 32),
                          _buildStatsSection(context),
                        ],
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'bio'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isEditingBio = !_isEditingBio;
                  if (!_isEditingBio) {
                    _saveBioToFirebase();
                  }
                });
              },
              child: Icon(
                _isEditingBio ? Icons.close : Icons.edit_outlined,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isEditingBio)
          Column(
            children: [
              TextField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  hintText: tr(context, 'bio_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _bioController.text = widget.userProfile?.bio ?? '';
                        _isEditingBio = false;
                      });
                    },
                    child: Text(tr(context, 'cancel')),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      _saveBioToFirebase();
                      setState(() {
                        _isEditingBio = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(tr(context, 'save')),
                  ),
                ],
              ),
            ],
          )
        else
          GestureDetector(
            onTap: () => setState(() => _isEditingBio = true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _bioController.text.isEmpty
                    ? tr(context, 'no_bio_yet')
                    : _bioController.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _bioController.text.isEmpty
                      ? Colors.grey.withValues(alpha: 0.6)
                      : AppTheme.textColor(context),
                  fontStyle: _bioController.text.isEmpty 
                      ? FontStyle.italic 
                      : FontStyle.normal,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInterestsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'interests_hobbies'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isEditingInterests = !_isEditingInterests;
                  if (!_isEditingInterests) {
                    _interestController.clear();
                  }
                });
              },
              child: Icon(
                _isEditingInterests
                    ? Icons.check
                    : _interests.isEmpty
                        ? Icons.add
                        : Icons.edit_outlined,
                size: 20,
                color: _isEditingInterests ? Colors.green : AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isEditingInterests)
          Column(
            children: [
              TextField(
                controller: _interestController,
                decoration: InputDecoration(
                  hintText: tr(context, 'add_interest_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    onPressed: () => _addInterest(_interestController.text),
                  ),
                ),
                onSubmitted: _addInterest,
              ),
              if (_interests.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInterestsDisplay(),
              ],
            ],
          )
        else if (_interests.isEmpty)
          GestureDetector(
            onTap: () => setState(() => _isEditingInterests = true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.interests_outlined,
                    size: 32,
                    color: Colors.grey.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'no_interests_yet'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _buildInterestsDisplay(),
      ],
    );
  }

  Widget _buildInterestsDisplay() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                interest,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (_isEditingInterests) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removeInterest(interest),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final profile = widget.userProfile!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'activity_stats'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSimpleStatRow(
                tr(context, 'supporters'),
                '${profile.supportersCount}',
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildSimpleStatRow(
                tr(context, 'posts'),
                '${profile.postsCount}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _addInterest(String interest) {
    if (interest.trim().isNotEmpty && !_interests.contains(interest.trim())) {
      HapticFeedback.lightImpact();
      setState(() {
        _interests.add(interest.trim());
        _interestController.clear();
      });
      _saveInterestsToFirebase();
    } else if (interest.trim().isNotEmpty) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'interest_already_exists')),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeInterest(String interest) {
    HapticFeedback.lightImpact();
    setState(() {
      _interests.remove(interest);
    });
    _saveInterestsToFirebase();
  }

  Future<void> _saveInterestsToFirebase() async {
    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      await userProfileService.updateUserInterests(_interests);
    } catch (e) {
      debugPrint('Error saving interests: $e');
    }
  }

  Future<void> _saveBioToFirebase() async {
    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      await userProfileService.updateUserProfileFields(bio: _bioController.text.trim());
    } catch (e) {
      debugPrint('Error saving bio: $e');
    }
  }
}

/// Modern bottom sheet for profile menu options
class ProfileMenuBottomSheet extends ConsumerStatefulWidget {
  const ProfileMenuBottomSheet({
    super.key, 
    required this.displayName,
    this.userProfile,
  });

  final String displayName;
  final UserProfile? userProfile;

  @override
  ConsumerState<ProfileMenuBottomSheet> createState() => _ProfileMenuBottomSheetState();
}

class _ProfileMenuBottomSheetState extends ConsumerState<ProfileMenuBottomSheet> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu Options
                _buildMenuOption(
                  context,
                  Icons.edit_outlined,
                  tr(context, 'edit_layout'),
                  tr(context, 'customize_profile_layout'),
                  () {
                    Navigator.pop(context);
                    ref.read(profileLayoutNotifierProvider.notifier).enterEditMode();
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildMenuOption(
                  context,
                  Icons.copy_outlined,
                  tr(context, 'share_profile'),
                  tr(context, 'copy_profile_message'),
                  () {
                    Navigator.pop(context);
                    _shareProfile(context);
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildMenuOption(
                  context,
                  Icons.person_outlined,
                  tr(context, 'about_user').replaceAll('{name}', widget.displayName),
                  tr(context, 'profile_info_interests'),
                  () => _showAboutSection(context),
                  showArrow: true,
                ),
                
                const SizedBox(height: 16),
                
                _buildMenuOption(
                  context,
                  Icons.collections_outlined,
                  tr(context, 'highlights_settings'),
                  tr(context, 'manage_hidden_permanent_highlights'),
                  () => _showHighlightsSettings(context),
                  showArrow: true,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool showArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  void _shareProfile(BuildContext context) {
    final shareText = tr(context, 'profile_share_message');
    
    Clipboard.setData(ClipboardData(text: shareText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              tr(context, 'profile_copied_clipboard'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAboutSection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => UserAboutBottomSheet(
        userProfile: widget.userProfile,
        displayName: widget.displayName,
      ),
    );
  }

  void _showHighlightsSettings(BuildContext context) {
    Navigator.pop(context); // Close current bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HighlightsSettingsScreen(),
      ),
    );
  }

}
