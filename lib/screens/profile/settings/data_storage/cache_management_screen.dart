import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';

class CacheManagementScreen extends ConsumerStatefulWidget {
  const CacheManagementScreen({super.key});

  @override
  ConsumerState<CacheManagementScreen> createState() => _CacheManagementScreenState();
}

class _CacheManagementScreenState extends ConsumerState<CacheManagementScreen> {
  Map<String, int>? _cacheData;
  bool _isLoading = true;
  bool _autoCleanCache = true;
  int _cacheRetentionDays = 7;

  @override
  void initState() {
    super.initState();
    _calculateCacheUsage();
  }

  Future<void> _calculateCacheUsage() async {
    setState(() => _isLoading = true);
    
    try {
      final cacheData = await _getCacheUsage();
      if (mounted) {
        setState(() {
          _cacheData = cacheData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, int>> _getCacheUsage() async {
    // Simulate cache calculation
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Mock cache data for demonstration
    return {
      'image_cache': 28 * 1024 * 1024, // 28 MB
      'video_cache': 45 * 1024 * 1024, // 45 MB
      'api_cache': 12 * 1024 * 1024, // 12 MB
      'thumbnail_cache': 8 * 1024 * 1024, // 8 MB
      'webview_cache': 15 * 1024 * 1024, // 15 MB
      'temp_downloads': 22 * 1024 * 1024, // 22 MB
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  int get _totalCacheSize => _cacheData?.values.fold<int>(0, (sum, size) => sum + size) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'cache_management'),
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
            icon: Icon(Icons.refresh, color: AppTheme.textColor(context)),
            onPressed: _calculateCacheUsage,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCacheOverviewCard(),
                  const SizedBox(height: 24),
                  _buildCacheSettings(),
                  const SizedBox(height: 24),
                  _buildCacheCategories(),
                  const SizedBox(height: 24),
                  _buildCacheActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildCacheOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange,
            Colors.orange.withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cleaning_services, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                tr(context, 'total_cache_size'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatBytes(_totalCacheSize),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'cache_description'),
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showClearAllCacheDialog(),
            icon: const Icon(Icons.delete_sweep, size: 20),
            label: Text(tr(context, 'clear_all_cache')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'cache_settings'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitchTile(
          title: tr(context, 'auto_clean_cache'),
          subtitle: tr(context, 'automatically_clean_old_cache'),
          value: _autoCleanCache,
          onChanged: (value) => setState(() => _autoCleanCache = value),
          icon: Icons.auto_delete,
        ),
        const SizedBox(height: 16),
        _buildRetentionSetting(),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
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
              color: AppTheme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
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
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
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

  Widget _buildRetentionSetting() {
    return GestureDetector(
      onTap: _autoCleanCache ? _showRetentionDialog : null,
      child: Container(
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
                color: _autoCleanCache
                    ? AppTheme.primaryColor.withAlpha(26)
                    : Colors.grey.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.schedule,
                color: _autoCleanCache ? AppTheme.primaryColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'cache_retention_period'),
                    style: TextStyle(
                      color: _autoCleanCache
                          ? AppTheme.textColor(context)
                          : AppTheme.textColor(context).withAlpha(128),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _autoCleanCache
                        ? '${tr(context, 'keep_cache_for')} $_cacheRetentionDays ${tr(context, 'days')}'
                        : tr(context, 'auto_clean_disabled'),
                    style: TextStyle(
                      color: _autoCleanCache
                          ? AppTheme.textColor(context).withAlpha(179)
                          : AppTheme.textColor(context).withAlpha(102),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (_autoCleanCache)
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

  Widget _buildCacheCategories() {
    if (_cacheData == null) return const SizedBox.shrink();
    
    final categories = [
      {
        'key': 'image_cache',
        'title': tr(context, 'image_cache'),
        'description': tr(context, 'cached_exercise_images'),
        'icon': Icons.image,
        'color': Colors.blue,
      },
      {
        'key': 'video_cache',
        'title': tr(context, 'video_cache'),
        'description': tr(context, 'cached_workout_videos'),
        'icon': Icons.video_library,
        'color': Colors.red,
      },
      {
        'key': 'api_cache',
        'title': tr(context, 'api_cache'),
        'description': tr(context, 'cached_api_responses'),
        'icon': Icons.api,
        'color': Colors.green,
      },
      {
        'key': 'thumbnail_cache',
        'title': tr(context, 'thumbnail_cache'),
        'description': tr(context, 'cached_thumbnails'),
        'icon': Icons.photo_size_select_small,
        'color': Colors.orange,
      },
      {
        'key': 'webview_cache',
        'title': tr(context, 'webview_cache'),
        'description': tr(context, 'cached_web_content'),
        'icon': Icons.web,
        'color': Colors.purple,
      },
      {
        'key': 'temp_downloads',
        'title': tr(context, 'temp_downloads'),
        'description': tr(context, 'temporary_downloaded_files'),
        'icon': Icons.download,
        'color': Colors.teal,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'cache_by_category'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...categories.map((category) {
          final size = _cacheData![category['key']] ?? 0;
          final percentage = (_totalCacheSize > 0) ? (size / _totalCacheSize) : 0.0;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                    color: (category['color'] as Color).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
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
                              category['title'] as String,
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _formatBytes(size),
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['description'] as String,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppTheme.primaryColor.withAlpha(26),
                        valueColor: AlwaysStoppedAnimation(category['color'] as Color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _clearSpecificCache(category['key'] as String, category['title'] as String),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCacheActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'cache_actions'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          title: tr(context, 'optimize_cache'),
          subtitle: tr(context, 'remove_unused_cache_files'),
          icon: Icons.tune,
          color: Colors.blue,
          onTap: _optimizeCache,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          title: tr(context, 'reset_cache_settings'),
          subtitle: tr(context, 'restore_default_cache_settings'),
          icon: Icons.settings_backup_restore,
          color: Colors.orange,
          onTap: _resetCacheSettings,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                ],
              ),
            ),
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

  void _showClearAllCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'clear_all_cache')),
        content: Text(tr(context, 'clear_all_cache_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, 'clear_all')),
          ),
        ],
      ),
    );
  }

  void _showRetentionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'cache_retention_period')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int days in [1, 3, 7, 14, 30])
              ListTile(
                title: Text('$days ${tr(context, 'days')}'),
                leading: Icon(
                  _cacheRetentionDays == days ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: _cacheRetentionDays == days ? AppTheme.primaryColor : Colors.grey,
                ),
                onTap: () {
                  setState(() => _cacheRetentionDays = days);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
        ],
      ),
    );
  }

  void _clearSpecificCache(String cacheKey, String cacheName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${tr(context, 'clear')} $cacheName'),
        content: Text('${tr(context, 'clear_specific_cache_confirmation')} $cacheName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _cacheData?[cacheKey] = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$cacheName ${tr(context, 'cleared_successfully')}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, 'clear')),
          ),
        ],
      ),
    );
  }

  void _clearAllCache() {
    setState(() {
      _cacheData?.updateAll((key, value) => 0);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'all_cache_cleared_successfully')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _optimizeCache() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(tr(context, 'optimizing_cache')),
          ],
        ),
      ),
    );

    // Simulate optimization
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.pop(context);
      
      // Simulate cache reduction after optimization
      setState(() {
        _cacheData?.updateAll((key, value) => (value * 0.7).round());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'cache_optimization_completed')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetCacheSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'reset_cache_settings')),
        content: Text(tr(context, 'reset_cache_settings_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _autoCleanCache = true;
                _cacheRetentionDays = 7;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr(context, 'cache_settings_reset')),
                  backgroundColor: Colors.green,
                ),
              );
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
}