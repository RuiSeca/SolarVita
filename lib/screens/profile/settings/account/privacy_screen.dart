// lib/screens/profile/settings/account/privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/common/lottie_loading_widget.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  // Privacy settings state
  bool _dataCollection = true;
  bool _analyticsTracking = true;
  bool _marketingEmails = false;
  bool _crashReporting = true;
  bool _locationTracking = false;
  bool _biometricAuth = false;
  bool _appLock = false;
  bool _hideAppInRecents = false;

  // Data retention period (in months)
  int _dataRetentionPeriod = 12;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dataCollection = prefs.getBool('data_collection') ?? true;
      _analyticsTracking = prefs.getBool('analytics_tracking') ?? true;
      _marketingEmails = prefs.getBool('marketing_emails') ?? false;
      _crashReporting = prefs.getBool('crash_reporting') ?? true;
      _locationTracking = prefs.getBool('location_tracking') ?? false;
      _biometricAuth = prefs.getBool('biometric_auth') ?? false;
      _appLock = prefs.getBool('app_lock') ?? false;
      _hideAppInRecents = prefs.getBool('hide_app_in_recents') ?? false;
      _dataRetentionPeriod = prefs.getInt('data_retention_period') ?? 12;
    });
  }

  Future<void> _savePrivacySetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveDataRetentionPeriod(int months) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('data_retention_period', months);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          tr(context, 'privacy'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataPrivacySection(),
            const SizedBox(height: 24),
            _buildSecuritySection(),
            const SizedBox(height: 24),
            _buildDataManagementSection(),
            const SizedBox(height: 24),
            _buildLegalSection(),
            const SizedBox(height: 32),
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPrivacySection() {
    return _buildSection(
      context,
      title: tr(context, 'data_privacy'),
      subtitle: tr(context, 'control_how_data_collected'),
      children: [
        _buildSwitchTile(
          context,
          title: tr(context, 'data_collection'),
          subtitle: tr(context, 'allow_app_collect_usage_data'),
          value: _dataCollection,
          onChanged: (value) {
            setState(() => _dataCollection = value);
            _savePrivacySetting('data_collection', value);
          },
          icon: Icons.data_usage,
        ),
        _buildSwitchTile(
          context,
          title: tr(context, 'analytics_tracking'),
          subtitle: tr(context, 'help_improve_app_performance'),
          value: _analyticsTracking,
          onChanged: (value) {
            setState(() => _analyticsTracking = value);
            _savePrivacySetting('analytics_tracking', value);
          },
          icon: Icons.analytics,
        ),
        _buildSwitchTile(
          context,
          title: tr(context, 'crash_reporting'),
          subtitle: tr(context, 'automatically_send_crash_reports'),
          value: _crashReporting,
          onChanged: (value) {
            setState(() => _crashReporting = value);
            _savePrivacySetting('crash_reporting', value);
          },
          icon: Icons.bug_report,
        ),
        _buildSwitchTile(
          context,
          title: tr(context, 'location_tracking'),
          subtitle: tr(context, 'allow_location_based_features'),
          value: _locationTracking,
          onChanged: (value) {
            setState(() => _locationTracking = value);
            _savePrivacySetting('location_tracking', value);
          },
          icon: Icons.location_on,
        ),
        _buildSwitchTile(
          context,
          title: tr(context, 'marketing_emails'),
          subtitle: tr(context, 'receive_promotional_emails'),
          value: _marketingEmails,
          onChanged: (value) {
            setState(() => _marketingEmails = value);
            _savePrivacySetting('marketing_emails', value);
          },
          icon: Icons.email,
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      context,
      title: tr(context, 'security_privacy'),
      subtitle: tr(context, 'protect_your_account_data'),
      children: [
        _buildSwitchTile(
          context,
          title: tr(context, 'biometric_authentication'),
          subtitle: tr(context, 'use_fingerprint_face_unlock'),
          value: _biometricAuth,
          onChanged: (value) {
            setState(() => _biometricAuth = value);
            _savePrivacySetting('biometric_auth', value);
          },
          icon: Icons.fingerprint,
        ),
        _buildSwitchTile(
          context,
          title: tr(context, 'app_lock'),
          subtitle: tr(context, 'require_authentication_open_app'),
          value: _appLock,
          onChanged: (value) {
            setState(() => _appLock = value);
            _savePrivacySetting('app_lock', value);
          },
          icon: Icons.lock,
        ),
        _buildSwitchTile(
          context,
          title: tr(context, 'hide_app_recents'),
          subtitle: tr(context, 'blur_app_background_app_switcher'),
          value: _hideAppInRecents,
          onChanged: (value) {
            setState(() => _hideAppInRecents = value);
            _savePrivacySetting('hide_app_in_recents', value);
          },
          icon: Icons.visibility_off,
        ),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    return _buildSection(
      context,
      title: tr(context, 'data_management'),
      subtitle: tr(context, 'manage_your_stored_data'),
      children: [
        _buildDataRetentionTile(),
        _buildActionTile(
          context,
          title: tr(context, 'download_my_data'),
          subtitle: tr(context, 'export_copy_personal_data'),
          icon: Icons.download,
          onTap: _showDownloadDataDialog,
        ),
        _buildActionTile(
          context,
          title: tr(context, 'clear_app_data'),
          subtitle: tr(context, 'remove_cached_temporary_data'),
          icon: Icons.cleaning_services,
          onTap: _showClearDataDialog,
        ),
      ],
    );
  }

  Widget _buildDataRetentionTile() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.schedule,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        tr(context, 'data_retention_period'),
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        tr(context, 'how_long_keep_data'),
        style: TextStyle(
          color: AppTheme.textColor(context).withAlpha(179),
          fontSize: 14,
        ),
      ),
      trailing: DropdownButton<int>(
        value: _dataRetentionPeriod,
        onChanged: (value) {
          if (value != null) {
            setState(() => _dataRetentionPeriod = value);
            _saveDataRetentionPeriod(value);
          }
        },
        items: [3, 6, 12, 24, 36]
            .map((months) => DropdownMenuItem(
                  value: months,
                  child: Text(
                    tr(context, 'months_count')
                        .replaceAll('{count}', '$months'),
                    style: TextStyle(color: AppTheme.textColor(context)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLegalSection() {
    return _buildSection(
      context,
      title: tr(context, 'legal_information'),
      subtitle: tr(context, 'privacy_policies_terms'),
      children: [
        _buildActionTile(
          context,
          title: tr(context, 'privacy_policy'),
          subtitle: tr(context, 'read_privacy_policy'),
          icon: Icons.policy,
          onTap: () => _openUrl('https://solarvita.com/privacy'),
        ),
        _buildActionTile(
          context,
          title: tr(context, 'terms_service'),
          subtitle: tr(context, 'read_terms_service'),
          icon: Icons.description,
          onTap: () => _openUrl('https://solarvita.com/terms'),
        ),
        _buildActionTile(
          context,
          title: tr(context, 'gdpr_rights'),
          subtitle: tr(context, 'learn_about_rights'),
          icon: Icons.gavel,
          onTap: () => _showGDPRRightsDialog(),
        ),
        _buildActionTile(
          context,
          title: tr(context, 'contact_privacy_team'),
          subtitle: tr(context, 'questions_about_privacy'),
          icon: Icons.support_agent,
          onTap: () => _openUrl('mailto:privacy@solarvita.com'),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                tr(context, 'danger_zone'),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr(context, 'danger_zone_description'),
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showDeleteAccountDialog,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: Text(
                tr(context, 'delete_account'),
                style: const TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Column(
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
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(179),
            fontSize: 14,
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
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      secondary: Container(
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
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
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
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.textColor(context).withAlpha(153),
      ),
      onTap: onTap,
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'could_not_open_link'))),
        );
      }
    }
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'download_my_data'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          tr(context, 'download_data_explanation'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiateDataDownload();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              tr(context, 'request_download'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'clear_app_data'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          tr(context, 'clear_data_warning'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAppData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              tr(context, 'clear_data'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showGDPRRightsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'your_gdpr_rights'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGDPRRight(tr(context, 'right_to_access'),
                  tr(context, 'right_to_access_desc')),
              _buildGDPRRight(tr(context, 'right_to_rectification'),
                  tr(context, 'right_to_rectification_desc')),
              _buildGDPRRight(tr(context, 'right_to_erasure'),
                  tr(context, 'right_to_erasure_desc')),
              _buildGDPRRight(tr(context, 'right_to_portability'),
                  tr(context, 'right_to_portability_desc')),
              _buildGDPRRight(tr(context, 'right_to_object'),
                  tr(context, 'right_to_object_desc')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'close')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openUrl(
                  'mailto:privacy@solarvita.com?subject=GDPR Rights Request');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              tr(context, 'contact_us'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGDPRRight(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'delete_account'),
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          tr(context, 'delete_account_warning'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              tr(context, 'delete_permanently'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateDataDownload() async {
    // Implement data download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'data_download_initiated')),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _clearAppData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep essential settings but clear cached data
      final essentialKeys = ['language', 'theme_mode'];
      final allKeys = prefs.getKeys();

      for (String key in allKeys) {
        if (!essentialKeys.contains(key)) {
          await prefs.remove(key);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'app_data_cleared')),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_clearing_data')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          content: Row(
            children: [
              const LottieLoadingWidget(),
              const SizedBox(width: 16),
              Text(
                tr(context, 'deleting_account'),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            ],
          ),
        ),
      );

      // Here you would implement account deletion
      // For now, we'll just sign out
      await authProvider.signOut();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_deleting_account')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
