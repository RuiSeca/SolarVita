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
import 'preferences/personal_intent_preferences_screen.dart';
import 'app/language_screen.dart';
import 'app/help_support_screen.dart';
import 'feed/feed_layout_screen.dart';
import 'data_storage/data_sync_screen.dart';
import 'data_storage/storage_usage_screen.dart';
import 'data_storage/cache_management_screen.dart';
import 'app/about_app_screen.dart';
import 'app/contact_us_screen.dart';
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
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildMembershipSection(context),
            const SizedBox(height: 8),
            _buildAccountSettings(context),
            _buildDisplayAccessibilitySettings(context),
            _buildFeedContentSettings(context),
            _buildNotificationsSettings(context),
            _buildDataStorageSettings(context),
            _buildAboutSupportSettings(context),
            const SizedBox(height: 8),
            _buildSignOutButton(context, ref),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    final accountItems = [
      {
        'icon': Icons.person_outline_rounded,
        'title': tr(context, 'personal_information'),
        'subtitle': tr(context, 'edit_profile_details'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
        ),
      },
      {
        'icon': Icons.security_rounded,
        'title': tr(context, 'privacy'),
        'subtitle': tr(context, 'privacy_security_settings'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrivacyScreen()),
        ),
      },
    ];

    return _buildSection(
      context,
      title: tr(context, 'account'),
      children: accountItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildSettingsTile(
          context,
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          onTap: item['onTap'] as VoidCallback,
          isFirst: index == 0,
          isLast: index == accountItems.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildDisplayAccessibilitySettings(BuildContext context) {
    return _buildSection(
      context,
      title: tr(context, 'display_accessibility'),
      children: [
        Consumer(
          builder: (context, ref, child) {
            final themeMode = ref.watch(themeNotifierProvider);
            final themeNotifier = ref.read(themeNotifierProvider.notifier);
            final isDark = themeMode == ThemeMode.dark;

            return _buildSettingsTile(
              context,
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: tr(context, 'theme'),
              subtitle: tr(context, 'switch_light_dark_mode'),
              onTap: () => themeNotifier.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              ),
              isFirst: true,
              trailing: Switch(
                value: isDark,
                onChanged: (value) => themeNotifier.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                ),
                activeThumbColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          },
        ),
        _buildSettingsTile(
          context,
          icon: Icons.language_rounded,
          title: tr(context, 'language'),
          subtitle: tr(context, 'change_app_language'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LanguageScreen()),
          ),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildFeedContentSettings(BuildContext context) {
    final feedItems = [
      {
        'icon': Icons.psychology_rounded,
        'title': tr(context, 'personal_intents'),
        'subtitle': tr(context, 'customize_dashboard_experience'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PersonalIntentPreferencesScreen(),
          ),
        ),
      },
      {
        'icon': Icons.feed_rounded,
        'title': tr(context, 'feed'),
        'subtitle': tr(context, 'feed_settings'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FeedLayoutScreen()),
        ),
      },
      {
        'icon': Icons.fitness_center_rounded,
        'title': tr(context, 'workout_preferences'),
        'subtitle': tr(context, 'customize_workout_settings'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkoutPreferencesScreen(),
          ),
        ),
      },
      {
        'icon': Icons.restaurant_rounded,
        'title': tr(context, 'dietary_preferences'),
        'subtitle': tr(context, 'manage_diet_restrictions'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DietaryPreferencesScreen(),
          ),
        ),
      },
      {
        'icon': Icons.eco_rounded,
        'title': tr(context, 'sustainability_goals'),
        'subtitle': tr(context, 'set_environmental_targets'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SustainabilityGoalsScreen(),
          ),
        ),
      },
    ];

    return _buildSection(
      context,
      title: tr(context, 'feed_content'),
      children: feedItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildSettingsTile(
          context,
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          onTap: item['onTap'] as VoidCallback,
          isFirst: index == 0,
          isLast: index == feedItems.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildNotificationsSettings(BuildContext context) {
    return _buildSection(
      context,
      title: tr(context, 'notifications'),
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.notifications_rounded,
          title: tr(context, 'notifications'),
          subtitle: tr(context, 'manage_notification_preferences'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          ),
          isFirst: true,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildDataStorageSettings(BuildContext context) {
    final storageItems = [
      {
        'icon': Icons.sync_rounded,
        'title': tr(context, 'data_sync'),
        'subtitle': tr(context, 'manage_data_synchronization'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DataSyncScreen()),
        ),
      },
      {
        'icon': Icons.storage_rounded,
        'title': tr(context, 'storage_usage'),
        'subtitle': tr(context, 'view_app_storage_usage'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StorageUsageScreen()),
        ),
      },
      {
        'icon': Icons.cleaning_services_rounded,
        'title': tr(context, 'cache_management'),
        'subtitle': tr(context, 'manage_app_cache'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CacheManagementScreen()),
        ),
      },
    ];

    return _buildSection(
      context,
      title: tr(context, 'data_storage'),
      children: storageItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildSettingsTile(
          context,
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          onTap: item['onTap'] as VoidCallback,
          isFirst: index == 0,
          isLast: index == storageItems.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildAboutSupportSettings(BuildContext context) {
    final aboutItems = [
      {
        'icon': Icons.info_rounded,
        'title': tr(context, 'about_app'),
        'subtitle': tr(context, 'learn_about_solar_vita'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutAppScreen()),
        ),
      },
      {
        'icon': Icons.help_rounded,
        'title': tr(context, 'help_support'),
        'subtitle': tr(context, 'get_help_contact_support'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
        ),
      },
      {
        'icon': Icons.contact_support_rounded,
        'title': tr(context, 'contact_us'),
        'subtitle': tr(context, 'get_in_touch_with_us'),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ContactUsScreen()),
        ),
      },
    ];

    return _buildSection(
      context,
      title: tr(context, 'about_support'),
      children: aboutItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildSettingsTile(
          context,
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          onTap: item['onTap'] as VoidCallback,
          isFirst: index == 0,
          isLast: index == aboutItems.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: OutlinedButton.icon(
          onPressed: () => _showSignOutDialog(context, ref),
          icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
          label: Text(
            tr(context, 'sign_out'),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.withValues(alpha: 0.3), width: 1.5),
            backgroundColor: Colors.red.withValues(alpha: 0.04),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.isDarkMode(context) 
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.08),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              tr(context, 'sign_out'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          tr(context, 'sign_out_confirmation'),
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              tr(context, 'cancel'),
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              tr(context, 'sign_out'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
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
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: !isLast ? Border(
              bottom: BorderSide(
                color: AppTheme.textColor(context).withValues(alpha: 0.08),
                width: 0.5,
              ),
            ) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon, 
                  color: AppColors.primary, 
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textColor(context).withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipSection(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        const Color(0xFF1B5E20),
                        const Color(0xFF2E7D32),
                        const Color(0xFF388E3C),
                      ]
                    : [
                        const Color(0xFF66BB6A),
                        const Color(0xFF4CAF50),
                        const Color(0xFF388E3C),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  spreadRadius: 0,
                  blurRadius: 40,
                  offset: const Offset(0, 16),
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
