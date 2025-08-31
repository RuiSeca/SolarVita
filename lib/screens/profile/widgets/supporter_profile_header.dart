import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../models/user/supporter.dart';
import '../../../models/user/privacy_settings.dart';
import '../../../models/user/user_progress.dart';
import '../../../models/health/health_data.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class SupporterProfileHeader extends ConsumerWidget {
  final Supporter supporter;
  final PrivacySettings? privacySettings;
  final int? actualSupporterCount;
  final bool isOnline;
  final UserProgress? supporterProgress;
  final HealthData? supporterHealthData;

  const SupporterProfileHeader({
    super.key,
    required this.supporter,
    this.privacySettings,
    this.actualSupporterCount,
    this.isOnline = false,
    this.supporterProgress,
    this.supporterHealthData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Glassmorphism background
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withAlpha(38),
                      AppColors.primary.withAlpha(13),
                      Colors.white.withAlpha(26),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withAlpha(51),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(26),
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
                                    AppColors.primary.withAlpha(179),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(77),
                                    spreadRadius: 0,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundImage: supporter.photoURL != null
                                    ? CachedNetworkImageProvider(
                                        supporter.photoURL!,
                                      )
                                    : null,
                                backgroundColor: AppTheme.cardColor(context),
                                child: supporter.photoURL == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                            ),
                            // Online Status Indicator
                            if (isOnline)
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
                                        color: Colors.green.withAlpha(128),
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
                                supporter.displayName,
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (supporter.username != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '@${supporter.username}',
                                  style: TextStyle(
                                    color: AppTheme.textColor(
                                      context,
                                    ).withAlpha(153),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              _buildLevelBadge(context),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.eco,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPublicLevelInfo(context),
                                    style: TextStyle(
                                      color: AppTheme.textColor(
                                        context,
                                      ).withAlpha(179),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha(51),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: _buildQuickStat(
                              context,
                              Icons.people_outline,
                              (actualSupporterCount ??
                                      supporter.supportersCount ??
                                      0)
                                  .toString(),
                              tr(context, 'supporters'),
                            ),
                          ),
                          _buildDivider(),
                          Flexible(
                            child: _buildQuickStat(
                              context,
                              Icons.eco_outlined,
                              _getEcoScoreDisplay(context),
                              tr(context, 'eco_score'),
                            ),
                          ),
                          _buildDivider(),
                          Flexible(
                            child: _buildQuickStat(
                              context,
                              Icons.local_fire_department_outlined,
                              _getStreakDisplay(context),
                              tr(context, 'streak'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Profile Menu (Three Dots)
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: () {
                _showSupporterProfileMenu(context, ref, supporter.displayName);
              },
              child: Icon(
                Icons.more_horiz,
                color: AppTheme.textColor(context),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(51),
            AppColors.primary.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(77), width: 1),
      ),
      child: Text(
        _getLevelTitle(context),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
            color: AppTheme.textColor(context).withAlpha(153),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.white.withAlpha(51));
  }

  String _getLevelTitle(BuildContext context) {
    // Could be fetched from supporter data or privacy settings
    return tr(context, 'eco_enthusiast'); // Default for now
  }

  String _getPublicLevelInfo(BuildContext context) {
    // Show level info based on privacy settings
    if (privacySettings?.showEcoScore == true) {
      return tr(context, 'level_3_eco_enthusiast');
    }
    return tr(context, 'health_enthusiast');
  }

  String _getEcoScoreDisplay(BuildContext context) {
    if (privacySettings?.showEcoScore == true && supporter.ecoScore != null) {
      return supporter.ecoScore!;
    }
    return tr(context, 'private');
  }

  String _getStreakDisplay(BuildContext context) {
    if (privacySettings?.showWorkoutStats == true &&
        supporterProgress != null) {
      return supporterProgress!.currentStrikes.toString();
    }
    return tr(context, 'private');
  }

  void _showSupporterProfileMenu(BuildContext context, WidgetRef ref, String displayName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SupporterProfileMenuBottomSheet(
        displayName: displayName,
        supporter: supporter,
      ),
    );
  }
}

class SupporterProfileMenuBottomSheet extends ConsumerStatefulWidget {
  final String displayName;
  final Supporter supporter;
  
  const SupporterProfileMenuBottomSheet({
    super.key,
    required this.displayName,
    required this.supporter,
  });

  @override
  ConsumerState<SupporterProfileMenuBottomSheet> createState() => _SupporterProfileMenuBottomSheetState();
}

class _SupporterProfileMenuBottomSheetState extends ConsumerState<SupporterProfileMenuBottomSheet> {
  late List<String> _interests;

  @override
  void initState() {
    super.initState();
    // Initialize interests from Firebase supporter data
    _interests = widget.supporter.interests.isNotEmpty 
        ? widget.supporter.interests
        : ['Fitness', 'Environment', 'Health'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMenuOption(
                  context,
                  Icons.share_outlined,
                  tr(context, 'share_profile'),
                  tr(context, 'copy_profile_message'),
                  () {
                    Navigator.pop(context);
                    _shareProfile(context);
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuOption(
                  context,
                  Icons.info_outline,
                  tr(context, 'about_user').replaceAll('{name}', widget.displayName),
                  tr(context, 'profile_info_interests'),
                  () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
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
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.withValues(alpha: 0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareProfile(BuildContext context) {
    final shareMessage = tr(context, 'profile_share_message');
    Clipboard.setData(ClipboardData(text: shareMessage));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'profile_copied_clipboard')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr(context, 'about_user').replaceAll('{name}', widget.displayName),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              context,
              Icons.calendar_today,
              tr(context, 'member_since'),
              widget.supporter.createdAt != null 
                  ? DateFormat('MMMM yyyy').format(widget.supporter.createdAt!)
                  : 'January 2024',
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'interests_hobbies'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildInterestsDisplay(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestsDisplay() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interests.map((interest) {
        return Chip(
          label: Text(interest),
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }
}
