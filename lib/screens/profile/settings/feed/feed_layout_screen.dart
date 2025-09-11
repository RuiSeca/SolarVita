import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../../../../providers/riverpod/feed_layout_provider.dart';

class FeedLayoutScreen extends ConsumerWidget {
  const FeedLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'feed_settings'),
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
            _buildPostDensitySection(context, ref),
            _buildContentDisplaySection(context, ref),
            _buildFeedBehaviorSection(context, ref),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }


  Widget _buildPostDensitySection(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(feedLayoutProvider);
    final notifier = ref.read(feedLayoutProvider.notifier);

    return _buildSection(
      context,
      title: tr(context, 'post_density'),
      subtitle: tr(context, 'adjust_post_spacing'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildDensityOption(
              context,
              title: tr(context, 'compact'),
              icon: Icons.compress,
              isSelected: preferences.postDensity == PostDensity.compact,
              onTap: () => notifier.setPostDensity(PostDensity.compact),
            ),
            const Divider(height: 1),
            _buildDensityOption(
              context,
              title: tr(context, 'normal'),
              icon: Icons.view_agenda,
              isSelected: preferences.postDensity == PostDensity.normal,
              onTap: () => notifier.setPostDensity(PostDensity.normal),
            ),
            const Divider(height: 1),
            _buildDensityOption(
              context,
              title: tr(context, 'comfortable'),
              icon: Icons.expand,
              isSelected: preferences.postDensity == PostDensity.comfortable,
              onTap: () => notifier.setPostDensity(PostDensity.comfortable),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentDisplaySection(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(feedLayoutProvider);
    final notifier = ref.read(feedLayoutProvider.notifier);

    return _buildSection(
      context,
      title: tr(context, 'content_display'),
      subtitle: tr(context, 'customize_post_elements'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildToggleOption(
              context,
              title: tr(context, 'show_timestamps'),
              icon: Icons.access_time,
              value: preferences.showTimestamps,
              onChanged: (value) => notifier.setShowTimestamps(value),
            ),
            const Divider(height: 1),
            _buildToggleOption(
              context,
              title: tr(context, 'show_engagement_counts'),
              icon: Icons.favorite_border,
              value: preferences.showEngagementCounts,
              onChanged: (value) => notifier.setShowEngagementCounts(value),
            ),
            const Divider(height: 1),
            _buildToggleOption(
              context,
              title: tr(context, 'show_profile_pictures'),
              icon: Icons.account_circle,
              value: preferences.showProfilePictures,
              onChanged: (value) => notifier.setShowProfilePictures(value),
            ),
            const Divider(height: 1),
            _buildToggleOption(
              context,
              title: tr(context, 'show_post_previews'),
              icon: Icons.preview,
              value: preferences.showPostPreviews,
              onChanged: (value) => notifier.setShowPostPreviews(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedBehaviorSection(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(feedLayoutProvider);
    final notifier = ref.read(feedLayoutProvider.notifier);

    return _buildSection(
      context,
      title: tr(context, 'feed_behavior'),
      subtitle: tr(context, 'control_automatic_actions'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildToggleOption(
              context,
              title: tr(context, 'auto_play_videos'),
              icon: Icons.play_arrow,
              value: preferences.autoPlayVideos,
              onChanged: (value) => notifier.setAutoPlayVideos(value),
            ),
            const Divider(height: 1),
            _buildToggleOption(
              context,
              title: tr(context, 'auto_expand_images'),
              icon: Icons.image,
              value: preferences.autoExpandImages,
              onChanged: (value) => notifier.setAutoExpandImages(value),
            ),
            const Divider(height: 1),
            _buildToggleOption(
              context,
              title: tr(context, 'auto_load_more'),
              icon: Icons.refresh,
              value: preferences.autoLoadMore,
              onChanged: (value) => notifier.setAutoLoadMore(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 16),
        ],
      ),
    );
  }


  Widget _buildDensityOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withAlpha(26)
              : AppTheme.textColor(context).withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppTheme.textColor(context),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value 
              ? AppColors.primary.withAlpha(26)
              : AppTheme.textColor(context).withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: value ? AppColors.primary : AppTheme.textColor(context),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}