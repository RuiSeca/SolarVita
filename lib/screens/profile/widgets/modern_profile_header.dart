import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/user_profile_provider.dart';
import '../../../providers/riverpod/user_progress_provider.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import '../settings_main_screen.dart';
import 'dart:ui';

class ModernProfileHeader extends ConsumerWidget {
  const ModernProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    
    return userProfileAsync.when(
      data: (userProfile) => Builder(
      builder: (context) {
        final displayName = userProfile?.displayName ?? 'User';
        final photoURL = userProfile?.photoURL;
        
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
                                    backgroundImage: photoURL != null ? CachedNetworkImageProvider(photoURL) : null,
                                    backgroundColor: AppTheme.cardColor(context),
                                    child: photoURL == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: AppColors.primary,
                                          )
                                        : null,
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
                                      Text(
                                        'Level ${ref.watch(currentLevelProvider)} ${ref.watch(levelTitleProvider)}',
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
                                  '${userProfile?.supportersCount ?? 0}',
                                  'Supporters',
                                ),
                              ),
                              _buildDivider(),
                              Flexible(
                                child: _buildQuickStat(
                                  context,
                                  Icons.eco_outlined,
                                  '2.4kg',
                                  'CO₂ Saved',
                                ),
                              ),
                              _buildDivider(),
                              Flexible(
                                child: _buildQuickStat(
                                  context,
                                  Icons.local_fire_department_outlined,
                                  '${ref.watch(currentStrikesProvider)}',
                                  'Day Streak',
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
                      color: Colors.white.withAlpha(38),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(77),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
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
    ),
    loading: () => Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
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
}