import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/supporter_circle.dart';
import '../../services/community/enhanced_social_service.dart';
import '../../utils/translation_helper.dart';
import '../../theme/app_theme.dart';
import 'create_supporter_circle_screen.dart';
import 'supporter_circle_detail_screen.dart';

class SupporterCirclesScreen extends ConsumerStatefulWidget {
  const SupporterCirclesScreen({super.key});

  @override
  ConsumerState<SupporterCirclesScreen> createState() => _SupporterCirclesScreenState();
}

class _SupporterCirclesScreenState extends ConsumerState<SupporterCirclesScreen>
    with TickerProviderStateMixin {
  final EnhancedSocialService _socialService = EnhancedSocialService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          tr(context, 'supporter_circles'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          tabs: [
            Tab(text: tr(context, 'my_circles')),
            Tab(text: tr(context, 'discover')),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: theme.primaryColor,
            ),
            onPressed: () => _navigateToCreateCircle(),
            tooltip: tr(context, 'create_circle'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCirclesTab(isDarkMode),
          _buildDiscoverTab(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildMyCirclesTab(bool isDarkMode) {
    return StreamBuilder<List<SupporterCircle>>(
      stream: _socialService.getUserSupporterCircles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'error_loading_circles'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        final circles = snapshot.data ?? [];

        if (circles.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: circles.length,
          itemBuilder: (context, index) {
            return _buildCircleCard(circles[index], isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildDiscoverTab(bool isDarkMode) {
    return StreamBuilder<List<SupporterCircle>>(
      stream: _socialService.discoverSupporterCircles(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(tr(context, 'error_loading_circles')),
          );
        }

        final circles = snapshot.data ?? [];

        if (circles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.explore_off,
                  size: 48,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'no_circles_to_discover'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: circles.length,
          itemBuilder: (context, index) {
            return _buildCircleCard(circles[index], isDarkMode, isDiscovery: true);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              tr(context, 'no_circles_yet'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'circles_empty_description'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateCircle(),
              icon: const Icon(Icons.add),
              label: Text(tr(context, 'create_first_circle')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleCard(SupporterCircle circle, bool isDarkMode, {bool isDiscovery = false}) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.05),
            Colors.white.withValues(alpha: isDarkMode ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDarkMode ? 0.2 : 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCircleDetail(circle),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Circle avatar/icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCircleTypeColor(circle.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCircleTypeColor(circle.type).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getCircleTypeIcon(circle.type),
                        color: _getCircleTypeColor(circle.type),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            circle.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            circle.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (circle.privacy == CirclePrivacy.private)
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Member count
                    _buildStatChip(
                      icon: Icons.people_outline,
                      label: '${circle.memberCount}',
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    // Circle type
                    _buildStatChip(
                      icon: _getCircleTypeIcon(circle.type),
                      label: _getCircleTypeName(circle.type),
                      color: _getCircleTypeColor(circle.type),
                    ),
                    const Spacer(),
                    if (isDiscovery)
                      ElevatedButton(
                        onPressed: () => _joinCircle(circle),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                          foregroundColor: theme.primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(tr(context, 'join')),
                      ),
                  ],
                ),
                if (circle.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: circle.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.primaryColor,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCircleTypeColor(CircleType type) {
    switch (type) {
      case CircleType.fitness:
        return Colors.orange;
      case CircleType.nutrition:
        return Colors.green;
      case CircleType.sustainability:
        return Colors.teal;
      case CircleType.family:
        return Colors.pink;
      case CircleType.professional:
        return Colors.blue;
      case CircleType.support:
        return Colors.purple;
    }
  }

  IconData _getCircleTypeIcon(CircleType type) {
    switch (type) {
      case CircleType.fitness:
        return Icons.fitness_center;
      case CircleType.nutrition:
        return Icons.restaurant;
      case CircleType.sustainability:
        return Icons.eco;
      case CircleType.family:
        return Icons.family_restroom;
      case CircleType.professional:
        return Icons.work_outline;
      case CircleType.support:
        return Icons.favorite_outline;
    }
  }

  String _getCircleTypeName(CircleType type) {
    switch (type) {
      case CircleType.fitness:
        return tr(context, 'fitness');
      case CircleType.nutrition:
        return tr(context, 'nutrition');
      case CircleType.sustainability:
        return tr(context, 'sustainability');
      case CircleType.family:
        return tr(context, 'family');
      case CircleType.professional:
        return tr(context, 'professional');
      case CircleType.support:
        return tr(context, 'support');
    }
  }

  void _navigateToCreateCircle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateSupporterCircleScreen(),
      ),
    );
  }

  void _navigateToCircleDetail(SupporterCircle circle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SupporterCircleDetailScreen(circle: circle),
      ),
    );
  }

  Future<void> _joinCircle(SupporterCircle circle) async {
    try {
      await _socialService.joinSupporterCircle(circle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'joined_circle_successfully')),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join circle: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}