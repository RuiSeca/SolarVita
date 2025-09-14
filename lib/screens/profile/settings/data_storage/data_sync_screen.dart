import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';

enum SyncStatus { synced, syncing, failed, offline }

class DataSyncScreen extends ConsumerStatefulWidget {
  const DataSyncScreen({super.key});

  @override
  ConsumerState<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends ConsumerState<DataSyncScreen> {
  bool _autoSync = true;
  bool _syncOnWifiOnly = true;
  bool _syncExerciseData = true;
  bool _syncProgressData = true;
  bool _syncRoutines = true;
  bool _syncPreferences = false;
  
  SyncStatus _currentSyncStatus = SyncStatus.synced;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _lastSyncTime = DateTime.now().subtract(const Duration(hours: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'data_sync'),
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
        actions: [
          IconButton(
            icon: Icon(
              _isSyncing ? Icons.sync_disabled : Icons.sync,
              color: _isSyncing ? Colors.grey : AppTheme.textColor(context),
            ),
            onPressed: _isSyncing ? null : _performManualSync,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyncStatusCard(),
            const SizedBox(height: 24),
            _buildSyncSettings(),
            const SizedBox(height: 24),
            _buildDataCategories(),
            const SizedBox(height: 24),
            _buildSyncActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_currentSyncStatus) {
      case SyncStatus.synced:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done;
        statusText = tr(context, 'data_synced');
        break;
      case SyncStatus.syncing:
        statusColor = Colors.blue;
        statusIcon = Icons.cloud_sync;
        statusText = tr(context, 'syncing_data');
        break;
      case SyncStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.cloud_off;
        statusText = tr(context, 'sync_failed');
        break;
      case SyncStatus.offline:
        statusColor = Colors.grey;
        statusIcon = Icons.cloud_off;
        statusText = tr(context, 'offline');
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_lastSyncTime != null && _currentSyncStatus != SyncStatus.syncing)
                      Text(
                        '${tr(context, 'last_sync')}: ${_formatLastSyncTime()}',
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentSyncStatus == SyncStatus.syncing) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: statusColor.withAlpha(51),
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'syncing_in_progress'),
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(179),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'sync_settings'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitchTile(
          title: tr(context, 'auto_sync'),
          subtitle: tr(context, 'automatically_sync_data'),
          value: _autoSync,
          onChanged: (value) => setState(() => _autoSync = value),
          icon: Icons.sync,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: tr(context, 'wifi_only_sync'),
          subtitle: tr(context, 'sync_only_on_wifi'),
          value: _syncOnWifiOnly,
          onChanged: (value) => setState(() => _syncOnWifiOnly = value),
          icon: Icons.wifi,
          enabled: _autoSync,
        ),
      ],
    );
  }

  Widget _buildDataCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'data_to_sync'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDataCategoryTile(
          title: tr(context, 'exercise_data'),
          subtitle: tr(context, 'workout_logs_and_history'),
          value: _syncExerciseData,
          onChanged: (value) => setState(() => _syncExerciseData = value),
          icon: Icons.fitness_center,
          size: tr(context, 'size_45_mb'),
        ),
        const SizedBox(height: 8),
        _buildDataCategoryTile(
          title: tr(context, 'progress_data'),
          subtitle: tr(context, 'achievements_and_milestones'),
          value: _syncProgressData,
          onChanged: (value) => setState(() => _syncProgressData = value),
          icon: Icons.trending_up,
          size: tr(context, 'size_8_mb'),
        ),
        const SizedBox(height: 8),
        _buildDataCategoryTile(
          title: tr(context, 'workout_routines'),
          subtitle: tr(context, 'custom_routines_and_templates'),
          value: _syncRoutines,
          onChanged: (value) => setState(() => _syncRoutines = value),
          icon: Icons.list_alt,
          size: tr(context, 'size_12_mb'),
        ),
        const SizedBox(height: 8),
        _buildDataCategoryTile(
          title: tr(context, 'app_preferences'),
          subtitle: tr(context, 'settings_and_customization'),
          value: _syncPreferences,
          onChanged: (value) => setState(() => _syncPreferences = value),
          icon: Icons.settings,
          size: tr(context, 'size_2_mb'),
        ),
      ],
    );
  }

  Widget _buildSyncActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'sync_actions'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          title: tr(context, 'force_sync_now'),
          subtitle: tr(context, 'manually_sync_all_data'),
          icon: Icons.cloud_sync,
          color: Colors.blue,
          onTap: _performManualSync,
          enabled: !_isSyncing,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          title: tr(context, 'reset_sync_data'),
          subtitle: tr(context, 'clear_and_re_sync_all_data'),
          icon: Icons.refresh,
          color: Colors.orange,
          onTap: _showResetSyncDialog,
          enabled: !_isSyncing,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          title: tr(context, 'export_data'),
          subtitle: tr(context, 'download_copy_of_your_data'),
          icon: Icons.download,
          color: Colors.green,
          onTap: _exportData,
          enabled: !_isSyncing,
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(26),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: enabled
                  ? AppTheme.primaryColor.withAlpha(26)
                  : Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled ? AppTheme.primaryColor : Colors.grey,
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
                  style: TextStyle(
                    color: enabled
                        ? AppTheme.textColor(context)
                        : AppTheme.textColor(context).withAlpha(128),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: enabled
                        ? AppTheme.textColor(context).withAlpha(179)
                        : AppTheme.textColor(context).withAlpha(102),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withAlpha(128),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCategoryTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required String size,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(26),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.primaryColor.withAlpha(26)
                  : Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? AppTheme.primaryColor : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      size,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(179),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withAlpha(128),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withAlpha(26),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: enabled ? color.withAlpha(26) : Colors.grey.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: enabled ? color : Colors.grey,
                size: 24,
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
                      color: enabled
                          ? AppTheme.textColor(context)
                          : AppTheme.textColor(context).withAlpha(128),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: enabled
                          ? AppTheme.textColor(context).withAlpha(179)
                          : AppTheme.textColor(context).withAlpha(102),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textColor(context).withAlpha(128),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  String _formatLastSyncTime() {
    if (_lastSyncTime == null) return tr(context, 'never');
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inMinutes < 1) {
      return tr(context, 'just_now');
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} ${tr(context, 'minutes_ago')}';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ${tr(context, 'hours_ago')}';
    } else {
      return '${difference.inDays} ${tr(context, 'days_ago')}';
    }
  }

  void _performManualSync() async {
    setState(() {
      _isSyncing = true;
      _currentSyncStatus = SyncStatus.syncing;
    });

    // Simulate sync process
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    
    setState(() {
      _isSyncing = false;
      _currentSyncStatus = SyncStatus.synced;
      _lastSyncTime = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'sync_completed_successfully')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showResetSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'reset_sync_data')),
        content: Text(tr(context, 'reset_sync_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSyncData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, 'reset')),
          ),
        ],
      ),
    );
  }

  void _resetSyncData() async {
    setState(() {
      _isSyncing = true;
      _currentSyncStatus = SyncStatus.syncing;
    });

    // Simulate reset and re-sync process
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;
    
    setState(() {
      _isSyncing = false;
      _currentSyncStatus = SyncStatus.synced;
      _lastSyncTime = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'sync_data_reset_successfully')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'export_data')),
        content: Text(tr(context, 'export_data_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr(context, 'data_export_started')),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, 'export')),
          ),
        ],
      ),
    );
  }
}