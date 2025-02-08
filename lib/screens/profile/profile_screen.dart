import 'package:flutter/material.dart';
import 'widgets/modern_stats_row.dart';
import '../../models/settings_item.dart';
import '../../theme/app_theme.dart';
import 'settings/account/personal_info_screen.dart';
import 'settings/account/notifications_screen.dart';
import 'settings/account/privacy_screen.dart';
import 'settings/preferences/workout_preferences_screen.dart';
import 'settings/preferences/dietary_preferences_screen.dart';
import 'settings/preferences/sustainability_goals_screen.dart';
import 'settings/app/language_screen.dart';
import 'settings/app/theme_screen.dart';
import 'settings/app/help_support_screen.dart';
import 'package:solar_vitas/screens/login/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            child: const Icon(
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
                  'John Doe',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Eco Enthusiast',
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
            onPressed: () {},
          ),
        ],
      ),
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
                  const Text(
                    'Premium Eco Member',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valid until Dec 2024',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 204),
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
              child: const Text('Manage'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Achievements',
      child: SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          children: [
            _buildAchievement(
              context,
              icon: Icons.directions_run,
              label: '10K Steps',
              isUnlocked: true,
            ),
            _buildAchievement(
              context,
              icon: Icons.eco,
              label: 'Tree Planter',
              isUnlocked: true,
            ),
            _buildAchievement(
              context,
              icon: Icons.fitness_center,
              label: 'Gym Guru',
              isUnlocked: true,
            ),
            _buildAchievement(
              context,
              icon: Icons.local_dining,
              label: 'Veggie Week',
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
    final Color iconColor = isUnlocked ? AppColors.primary : Colors.grey;
    final Color backgroundColor = isUnlocked
        ? AppColors.primary.withValues(alpha: 51)
        : AppTheme.cardColor(context);
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
            label,
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
            title,
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
                item.title,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                ),
              ),
            ),
            if (item.value != null)
              Text(
                item.value!,
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
      title: 'Account',
      items: [
        SettingsItem(
          icon: Icons.person,
          title: 'Personal Information',
          onTapScreen: (context) => const PersonalInfoScreen(),
        ),
        SettingsItem(
          icon: Icons.notifications,
          title: 'Notifications',
          onTapScreen: (context) => const NotificationsScreen(),
        ),
        SettingsItem(
          icon: Icons.privacy_tip,
          title: 'Privacy',
          onTapScreen: (context) => const PrivacyScreen(),
        ),
      ],
    );
  }

  Widget _buildPreferencesSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'Preferences',
      items: [
        SettingsItem(
          icon: Icons.fitness_center,
          title: 'Workout Preferences',
          onTapScreen: (context) => const WorkoutPreferencesScreen(),
        ),
        SettingsItem(
          icon: Icons.restaurant_menu,
          title: 'Dietary Preferences',
          onTapScreen: (context) => const DietaryPreferencesScreen(),
        ),
        SettingsItem(
          icon: Icons.eco,
          title: 'Sustainability Goals',
          onTapScreen: (context) => const SustainabilityGoalsScreen(),
        ),
      ],
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'App',
      items: [
        SettingsItem(
          icon: Icons.language,
          title: 'Language',
          value: 'English',
          onTapScreen: (context) => const LanguageScreen(),
        ),
        SettingsItem(
          icon: Icons.dark_mode,
          title: 'Theme',
          value: AppTheme.isDarkMode(context) ? 'Dark' : 'Light',
          onTapScreen: (context) => const ThemeScreen(),
        ),
        SettingsItem(
          icon: Icons.help,
          title: 'Help & Support',
          onTapScreen: (context) => const HelpSupportScreen(),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
