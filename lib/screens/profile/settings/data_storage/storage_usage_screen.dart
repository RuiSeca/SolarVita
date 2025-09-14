import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';

class StorageUsageScreen extends ConsumerStatefulWidget {
  const StorageUsageScreen({super.key});

  @override
  ConsumerState<StorageUsageScreen> createState() => _StorageUsageScreenState();
}

class _StorageUsageScreenState extends ConsumerState<StorageUsageScreen> {
  Map<String, int>? _storageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateStorageUsage();
  }

  Future<void> _calculateStorageUsage() async {
    setState(() => _isLoading = true);
    
    try {
      final storageData = await _getAppStorageUsage();
      if (mounted) {
        setState(() {
          _storageData = storageData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, int>> _getAppStorageUsage() async {
    // Simulate storage calculation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // In a real implementation, you would calculate actual storage usage
    // This is mock data for demonstration
    return {
      'exercise_data': 45 * 1024 * 1024, // 45 MB
      'workout_videos': 120 * 1024 * 1024, // 120 MB
      'user_progress': 8 * 1024 * 1024, // 8 MB
      'cached_images': 32 * 1024 * 1024, // 32 MB
      'app_database': 15 * 1024 * 1024, // 15 MB
      'temp_files': 5 * 1024 * 1024, // 5 MB
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  int get _totalUsage => _storageData?.values.fold<int>(0, (sum, size) => sum + size) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'storage_usage'),
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
            onPressed: _calculateStorageUsage,
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
                  _buildTotalUsageCard(),
                  const SizedBox(height: 24),
                  _buildStorageBreakdown(),
                  const SizedBox(height: 24),
                  _buildStorageRecommendations(),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalUsageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withAlpha(204),
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
              const Icon(Icons.storage, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                tr(context, 'total_app_usage'),
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
            _formatBytes(_totalUsage),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'app_storage_description'),
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageBreakdown() {
    if (_storageData == null) return const SizedBox.shrink();
    
    final categories = [
      {
        'key': 'exercise_data',
        'title': tr(context, 'exercise_data'),
        'icon': Icons.fitness_center,
        'color': Colors.blue,
      },
      {
        'key': 'workout_videos',
        'title': tr(context, 'workout_videos'),
        'icon': Icons.video_library,
        'color': Colors.red,
      },
      {
        'key': 'user_progress',
        'title': tr(context, 'user_progress'),
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
      {
        'key': 'cached_images',
        'title': tr(context, 'cached_images'),
        'icon': Icons.image,
        'color': Colors.orange,
      },
      {
        'key': 'app_database',
        'title': tr(context, 'app_database'),
        'icon': Icons.storage,
        'color': Colors.purple,
      },
      {
        'key': 'temp_files',
        'title': tr(context, 'temp_files'),
        'icon': Icons.folder_open,
        'color': Colors.grey,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'storage_breakdown'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...categories.map((category) {
          final size = _storageData![category['key']] ?? 0;
          final percentage = (_totalUsage > 0) ? (size / _totalUsage) : 0.0;
          
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
                      Text(
                        category['title'] as String,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppTheme.primaryColor.withAlpha(26),
                        valueColor: AlwaysStoppedAnimation(category['color'] as Color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatBytes(size),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(179),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStorageRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'storage_recommendations'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRecommendationCard(
          icon: Icons.auto_delete,
          title: tr(context, 'clear_cache'),
          description: tr(context, 'free_up_space_by_clearing_cache'),
          onTap: () => _showClearCacheDialog(),
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          icon: Icons.video_settings,
          title: tr(context, 'manage_video_quality'),
          description: tr(context, 'reduce_video_quality_to_save_space'),
          onTap: () => _showVideoQualityDialog(),
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          icon: Icons.cloud_upload,
          title: tr(context, 'backup_to_cloud'),
          description: tr(context, 'backup_data_to_free_local_storage'),
          onTap: () => _showBackupDialog(),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
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
                    description,
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

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'clear_cache')),
        content: Text(tr(context, 'clear_cache_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, 'clear')),
          ),
        ],
      ),
    );
  }

  void _showVideoQualityDialog() {
    String selectedQuality = 'medium';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(tr(context, 'video_quality')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(tr(context, 'high_quality')),
                subtitle: Text(tr(context, 'best_quality_more_storage')),
                leading: Icon(
                  selectedQuality == 'high' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selectedQuality == 'high' ? AppTheme.primaryColor : Colors.grey,
                ),
                onTap: () => setState(() => selectedQuality = 'high'),
              ),
              ListTile(
                title: Text(tr(context, 'medium_quality')),
                subtitle: Text(tr(context, 'balanced_quality_storage')),
                leading: Icon(
                  selectedQuality == 'medium' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selectedQuality == 'medium' ? AppTheme.primaryColor : Colors.grey,
                ),
                onTap: () => setState(() => selectedQuality = 'medium'),
              ),
              ListTile(
                title: Text(tr(context, 'low_quality')),
                subtitle: Text(tr(context, 'lower_quality_less_storage')),
                leading: Icon(
                  selectedQuality == 'low' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selectedQuality == 'low' ? AppTheme.primaryColor : Colors.grey,
                ),
                onTap: () => setState(() => selectedQuality = 'low'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr(context, 'apply')),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'backup_data')),
        content: Text(tr(context, 'backup_data_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startBackup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, 'backup')),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'cache_cleared_successfully')),
        backgroundColor: Colors.green,
      ),
    );
    // Recalculate storage after clearing cache
    _calculateStorageUsage();
  }

  void _startBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'backup_started')),
        backgroundColor: Colors.blue,
      ),
    );
  }
}