import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/riverpod/auth_provider.dart';
import '../../providers/riverpod/theme_provider.dart';
import 'settings/account/personal_info_screen.dart';
import 'settings/account/notifications_screen.dart';
import 'settings/account/privacy_screen.dart';
import 'settings/preferences/workout_preferences_screen.dart';
import 'settings/preferences/dietary_preferences_screen.dart';
import 'settings/preferences/sustainability_goals_screen.dart';
import 'settings/app/language_screen.dart';
import 'settings/app/help_support_screen.dart';
import '../../utils/translation_helper.dart';

class SettingsMainScreen extends ConsumerWidget {
  const SettingsMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Settings',
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
            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
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
              icon: isDark 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
              title: tr(context, 'theme'),
              subtitle: tr(context, 'switch_light_dark_mode'),
              onTap: () => themeNotifier.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (value) => themeNotifier.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light
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
            MaterialPageRoute(
              builder: (context) => const HelpSupportScreen(),
            ),
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
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
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
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: AppTheme.textColor(context).withAlpha(153),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMembershipSection(BuildContext context) {
    final shadowColor = AppTheme.isDarkMode(context)
        ? Colors.black.withAlpha(25)
        : Colors.white.withAlpha(25);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Membership',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
                          color: AppColors.white.withAlpha(51),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}