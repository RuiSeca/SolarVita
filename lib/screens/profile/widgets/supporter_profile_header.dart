import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../models/supporter.dart';
import '../../../models/privacy_settings.dart';
import '../../../models/user_progress.dart';
import '../../../models/health_data.dart';
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
                                    ? CachedNetworkImageProvider(supporter.photoURL!) 
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
                                    color: AppTheme.textColor(context).withAlpha(153),
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
                                    _getPublicLevelInfo(),
                                    style: TextStyle(
                                      color: AppTheme.textColor(context).withAlpha(179),
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
                              (actualSupporterCount ?? supporter.supportersCount ?? 0).toString(),
                              'Supporters',
                            ),
                          ),
                          _buildDivider(),
                          Flexible(
                            child: _buildQuickStat(
                              context,
                              Icons.eco_outlined,
                              _getEcoScoreDisplay(),
                              'Eco Score',
                            ),
                          ),
                          _buildDivider(),
                          Flexible(
                            child: _buildQuickStat(
                              context,
                              Icons.local_fire_department_outlined,
                              _getStreakDisplay(),
                              'Streak',
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
        ],
      ),
    );
  }

  Widget _buildLevelBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(51),
            AppColors.primary.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withAlpha(77),
          width: 1,
        ),
      ),
      child: Text(
        _getLevelTitle(),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
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
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withAlpha(51),
    );
  }

  String _getLevelTitle() {
    // Could be fetched from supporter data or privacy settings
    return 'Eco Enthusiast'; // Default for now
  }

  String _getPublicLevelInfo() {
    // Show level info based on privacy settings
    if (privacySettings?.showEcoScore == true) {
      return 'Level 3 Eco Enthusiast';
    }
    return 'Health Enthusiast';
  }

  String _getEcoScoreDisplay() {
    if (privacySettings?.showEcoScore == true && supporter.ecoScore != null) {
      return supporter.ecoScore!;
    }
    return 'Private';
  }

  String _getStreakDisplay() {
    if (privacySettings?.showWorkoutStats == true && supporterProgress != null) {
      return supporterProgress!.currentStrikes.toString();
    }
    return 'Private';
  }
}