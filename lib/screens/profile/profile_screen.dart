import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/modern_stats_row.dart';
import '../../models/settings_item.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/theme_provider.dart';
import 'settings/account/personal_info_screen.dart';
import 'settings/account/notifications_screen.dart';
import 'settings/account/privacy_screen.dart';
import 'settings/preferences/workout_preferences_screen.dart';
import 'settings/preferences/dietary_preferences_screen.dart';
import 'settings/preferences/sustainability_goals_screen.dart';
import 'settings/app/language_screen.dart';
import 'settings/app/help_support_screen.dart';
import 'package:solar_vitas/utils/translation_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context),
              const ModernStatsRow(),
              const SizedBox(height: 24),
              _buildMembershipSection(context),
              _buildAchievementsSection(context),
              _buildAccountSettings(context),
              _buildPreferencesSettings(context),
              _buildAppSettings(context),
              _buildSignOutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, _) {
        final userProfile = userProfileProvider.userProfile;
        final displayName = userProfile?.displayName ?? 'User';
        final email = userProfile?.email ?? '';
        final photoURL = userProfile?.photoURL;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  color: AppTheme.cardColor(context),
                ),
                child: photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          photoURL,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 153),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    Text(
                      tr(context, 'eco_enthusiast'),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 153),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PersonalInfoScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMembershipSection(BuildContext context) {
    // Get the appropriate shadow color based on theme
    final shadowColor = AppTheme.isDarkMode(context)
        ? Colors.black.withValues(alpha: 25)
        : Colors.white.withValues(alpha: 25);

    return _buildSection(
      context,
      title: 'Membership',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF66BB6A), // Lighter green
              Color(0xFF388E3C), // Darker green
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'premium_eco_member'),
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(context, 'valid_until'),
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 51),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: Text(tr(context, 'manage')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'achievements',
      child: SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          children: [
            _buildAchievement(
              context,
              icon: Icons.directions_run,
              label: 'achievement_10k',
              isUnlocked: true,
            ),
            _buildAchievement(
              context,
              icon: Icons.eco,
              label: 'achievement_tree',
              isUnlocked: true,
            ),
            _buildAchievement(
              context,
              icon: Icons.fitness_center,
              label: 'achievement_gym',
              isUnlocked: true,
            ),
            _buildAchievement(
              context,
              icon: Icons.local_dining,
              label: 'achievement_veggie',
              isUnlocked: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievement(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isUnlocked,
  }) {
    final Color iconColor = isUnlocked ? AppColors.gold : Colors.grey;
    final Color backgroundColor = isUnlocked
        ? AppTheme.cardColor(context)
        : AppColors.primary.withValues(alpha: 21);
    final Color textColor = isUnlocked
        ? AppTheme.textColor(context)
        : AppTheme.textColor(context).withValues(alpha: 153);

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, label),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<SettingsItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, title),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: items
                  .map((item) => _buildSettingsItem(context, item))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, SettingsItem item) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => item.onTapScreen(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(context, item.title),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                ),
              ),
            ),
            if (item.value != null)
              Text(
                tr(context, item.value!),
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 153),
                  fontSize: 14,
                ),
              ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textColor(context).withValues(alpha: 153),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'account',
      items: [
        SettingsItem(
          icon: Icons.person,
          title: 'personal_information',
          onTapScreen: (context) => const PersonalInfoScreen(),
        ),
        SettingsItem(
          icon: Icons.notifications,
          title: 'notifications',
          onTapScreen: (context) => const NotificationsScreen(),
        ),
        SettingsItem(
          icon: Icons.privacy_tip,
          title: 'privacy',
          onTapScreen: (context) => const PrivacyScreen(),
        ),
      ],
    );
  }

  Widget _buildPreferencesSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'preferences',
      items: [
        SettingsItem(
          icon: Icons.fitness_center,
          title: 'workout_preferences',
          onTapScreen: (context) => const WorkoutPreferencesScreen(),
        ),
        SettingsItem(
          icon: Icons.restaurant_menu,
          title: 'dietary_preferences',
          onTapScreen: (context) => const DietaryPreferencesScreen(),
        ),
        SettingsItem(
          icon: Icons.eco,
          title: 'sustainability_goals',
          onTapScreen: (context) => const SustainabilityGoalsScreen(),
        ),
      ],
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'app'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildLanguageItem(context),
                _buildThemeItem(context),
                _buildHelpSupportItem(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LanguageScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.language, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(context, 'language'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              tr(context, 'language_value'),
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 153),
                fontSize: 14,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textColor(context).withValues(alpha: 153),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeItem(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.dark_mode, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr(context, 'theme'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.textFieldBackground(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThemeButton(
                      context,
                      icon: Icons.light_mode,
                      label: 'Light',
                      isSelected: themeProvider.isLight,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    ),
                    _buildThemeButton(
                      context,
                      icon: Icons.dark_mode,
                      label: 'Dark',
                      isSelected: themeProvider.isDark,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textColor(context).withValues(alpha: 153),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textColor(context).withValues(alpha: 153),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSupportItem(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.help, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(context, 'help_support'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textColor(context).withValues(alpha: 153),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ElevatedButton(
            onPressed: authProvider.isLoading
                ? null
                : () async {
                    // Store navigator reference before async operation
                    final navigator = Navigator.of(context);

                    // Show confirmation dialog
                    final shouldSignOut = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(tr(context, 'sign_out')),
                        content: Text(tr(context, 'sign_out_confirmation')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(tr(context, 'cancel')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              tr(context, 'sign_out'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    // Use stored navigator reference instead of context
                    if (shouldSignOut == true) {
                      if (!mounted) return;

                      await authProvider.signOut();

                      if (!mounted) return;

                      // Use stored navigator instead of context
                      navigator.pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    tr(context, 'sign_out'),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                    ),
                  ),
          );
        },
      ),
    );
  }
}
