import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/auth_provider.dart';
import '../../../providers/riverpod/theme_provider.dart';
import 'account/personal_info_screen.dart';
import 'account/notifications_screen.dart';
import 'account/privacy_screen.dart';
import 'preferences/workout_preferences_screen.dart';
import 'preferences/dietary_preferences_screen.dart';
import 'preferences/sustainability_goals_screen.dart';
import 'app/language_screen.dart';
import 'app/help_support_screen.dart';
import '../../../utils/translation_helper.dart';

class SettingsMainScreen extends ConsumerWidget {
  const SettingsMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'settings'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildMembershipSection(context),
            _buildAccountSettings(context),
            _buildPreferencesSettings(context),
            _buildAppSettings(context),
            _buildSignOutButton(context, ref),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return _buildSection(
      context,
      title: tr(context, 'account'),
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.person,
          title: tr(context, 'personal_information'),
          subtitle: tr(context, 'edit_profile_details'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
          ),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.notifications,
          title: tr(context, 'notifications'),
          subtitle: tr(context, 'manage_notification_preferences'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          ),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.privacy_tip,
          title: tr(context, 'privacy'),
          subtitle: tr(context, 'privacy_security_settings'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacyScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSettings(BuildContext context) {
    return _buildSection(
      context,
      title: tr(context, 'preferences'),
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.fitness_center,
          title: tr(context, 'workout_preferences'),
          subtitle: tr(context, 'customize_workout_settings'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WorkoutPreferencesScreen(),
            ),
          ),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.restaurant,
          title: tr(context, 'dietary_preferences'),
          subtitle: tr(context, 'manage_diet_restrictions'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DietaryPreferencesScreen(),
            ),
          ),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.eco,
          title: tr(context, 'sustainability_goals'),
          subtitle: tr(context, 'set_environmental_targets'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SustainabilityGoalsScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return _buildSection(
      context,
      title: tr(context, 'app'),
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.language,
          title: tr(context, 'language'),
          subtitle: tr(context, 'change_app_language'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LanguageScreen()),
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final themeMode = ref.watch(themeNotifierProvider);
            final themeNotifier = ref.read(themeNotifierProvider.notifier);
            final isDark = themeMode == ThemeMode.dark;

            return _buildSettingsTile(
              context,
              icon: isDark ? Icons.light_mode : Icons.dark_mode,
              title: tr(context, 'theme'),
              subtitle: tr(context, 'switch_light_dark_mode'),
              onTap: () => themeNotifier.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (value) => themeNotifier.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                ),
                activeColor: AppColors.primary,
              ),
            );
          },
        ),
        _buildSettingsTile(
          context,
          icon: Icons.help,
          title: tr(context, 'help_support'),
          subtitle: tr(context, 'get_help_contact_support'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showSignOutDialog(context, ref),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: Text(
            tr(context, 'sign_out'),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
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
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'sign_out'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          tr(context, 'sign_out_confirmation'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final authNotifier = ref.read(authNotifierProvider.notifier);
              await authNotifier.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              tr(context, 'sign_out'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textColor(context).withAlpha(179),
          fontSize: 14,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: AppTheme.textColor(context).withAlpha(153),
          ),
      onTap: onTap,
    );
  }

  Widget _buildMembershipSection(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'membership'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1B5E20), // Dark green
                        const Color(0xFF2E7D32), // Medium green
                        const Color(0xFF388E3C), // Lighter green
                      ]
                    : [
                        const Color(0xFF66BB6A), // Light green
                        const Color(0xFF4CAF50), // Medium green
                        const Color(0xFF388E3C), // Dark green
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: Colors.amber,
                              size: 28,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tr(context, 'active_status'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr(context, 'premium_eco_member'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tr(context, 'valid_until'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber.shade300,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tr(context, 'premium_benefits'),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr(context, 'unlimited_access'),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to membership management
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              tr(context, 'manage'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
