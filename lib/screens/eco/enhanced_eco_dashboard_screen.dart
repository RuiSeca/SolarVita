import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/eco/enhanced_eco_metrics.dart';
import '../../models/eco/eco_achievement.dart';
import '../../services/eco/enhanced_eco_service.dart';
import '../../utils/translation_helper.dart';
import '../../theme/app_theme.dart';

class EnhancedEcoDashboardScreen extends ConsumerStatefulWidget {
  const EnhancedEcoDashboardScreen({super.key});

  @override
  ConsumerState<EnhancedEcoDashboardScreen> createState() => _EnhancedEcoDashboardScreenState();
}

class _EnhancedEcoDashboardScreenState extends ConsumerState<EnhancedEcoDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final EnhancedEcoService _ecoService = EnhancedEcoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: Column(
        children: [
          // Header with tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  tr(context, 'eco_impact_dashboard'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: theme.primaryColor,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: tr(context, 'overview')),
                    Tab(text: tr(context, 'achievements')),
                    Tab(text: tr(context, 'insights')),
                    Tab(text: tr(context, 'leaderboard')),
                  ],
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAchievementsTab(),
                _buildInsightsTab(),
                _buildLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return StreamBuilder<EnhancedEcoMetrics>(
      stream: _ecoService.getUserEnhancedMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final metrics = snapshot.data ?? EnhancedEcoMetrics.empty('');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Level and XP Card
              _buildLevelCard(metrics.levelSystem),
              const SizedBox(height: 16),

              // Key Stats Grid
              _buildStatsGrid(metrics),
              const SizedBox(height: 16),

              // Impact Visualization
              _buildImpactChart(metrics),
              const SizedBox(height: 16),

              // Category Breakdown
              _buildCategoryBreakdown(metrics),
              const SizedBox(height: 16),

              // Recent Milestones
              _buildRecentMilestones(metrics.milestones),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelCard(EcoLevelSystem levelSystem) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            levelSystem.levelColor.withValues(alpha: 0.3),
            levelSystem.levelColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: levelSystem.levelColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: levelSystem.levelColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.eco,
                  color: levelSystem.levelColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${levelSystem.level}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: levelSystem.levelColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      levelSystem.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: levelSystem.levelColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${levelSystem.currentXP}/${levelSystem.xpForNextLevel} XP',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: levelSystem.levelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: levelSystem.progressPercentage,
            backgroundColor: levelSystem.levelColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(levelSystem.levelColor),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(EnhancedEcoMetrics metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          title: tr(context, 'carbon_saved'),
          value: '${metrics.totalCarbonSaved.toStringAsFixed(1)} kg',
          subtitle: '${metrics.treesSaved} trees equivalent',
          icon: Icons.cloud_off,
          color: Colors.green,
        ),
        _buildStatCard(
          title: tr(context, 'current_streak'),
          value: '${metrics.currentStreak} days',
          subtitle: 'Longest: ${metrics.longestStreak} days',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: tr(context, 'eco_score'),
          value: '${metrics.ecoScore}/100',
          subtitle: metrics.globalRank,
          icon: Icons.star,
          color: Colors.amber,
        ),
        _buildStatCard(
          title: tr(context, 'activities'),
          value: '${metrics.activityCounts.length}',
          subtitle: 'Types explored',
          icon: Icons.explore,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactChart(EnhancedEcoMetrics metrics) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'impact_over_time'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: metrics.visualization.dailyData.length.toDouble() - 1,
                minY: 0,
                maxY: metrics.visualization.dailyData.isNotEmpty
                    ? metrics.visualization.dailyData
                        .map((e) => e.value)
                        .reduce((a, b) => a > b ? a : b) * 1.2
                    : 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: metrics.visualization.dailyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    color: theme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(EnhancedEcoMetrics metrics) {
    final theme = Theme.of(context);
    final categoryData = metrics.categoryBreakdown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'impact_by_category'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: _createPieChartSections(categoryData),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: categoryData.entries.map((entry) {
                  final color = _getCategoryColor(entry.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.key}: ${entry.value.toStringAsFixed(1)}kg',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return [];

    return data.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.green;
      case 'transport':
        return Colors.blue;
      case 'energy':
        return Colors.orange;
      case 'waste':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentMilestones(List<EcoMilestone> milestones) {
    final theme = Theme.of(context);
    final recentMilestones = milestones.take(3).toList();

    if (recentMilestones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            tr(context, 'no_milestones_yet'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'milestones'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...recentMilestones.map((milestone) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  milestone.icon,
                  color: milestone.isAchieved ? milestone.color : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      LinearProgressIndicator(
                        value: milestone.progress,
                        backgroundColor: Colors.grey.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          milestone.isAchieved ? milestone.color : Colors.grey,
                        ),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${milestone.currentValue.toStringAsFixed(1)}/${milestone.targetValue.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: milestone.isAchieved ? milestone.color : Colors.grey,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return StreamBuilder<List<UserAchievement>>(
      stream: _ecoService.getUserAchievements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userAchievements = snapshot.data ?? [];

        return FutureBuilder<List<EcoAchievement>>(
          future: _ecoService.getAvailableAchievements(),
          builder: (context, achievementsSnapshot) {
            if (achievementsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allAchievements = achievementsSnapshot.data ?? [];
            final unlockedIds = userAchievements.map((ua) => ua.achievementId).toSet();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Achievement Progress Summary
                  _buildAchievementSummary(userAchievements, allAchievements),
                  const SizedBox(height: 16),

                  // Unlocked Achievements
                  if (userAchievements.isNotEmpty) ...[
                    _buildAchievementSection(
                      tr(context, 'unlocked_achievements'),
                      allAchievements.where((a) => unlockedIds.contains(a.id)).toList(),
                      true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Available Achievements
                  _buildAchievementSection(
                    tr(context, 'available_achievements'),
                    allAchievements.where((a) => !unlockedIds.contains(a.id)).toList(),
                    false,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAchievementSummary(List<UserAchievement> userAchievements, List<EcoAchievement> allAchievements) {
    final theme = Theme.of(context);
    final totalPoints = userAchievements.fold(0, (sum, ua) {
      final achievement = allAchievements.firstWhere(
        (a) => a.id == ua.achievementId,
        orElse: () => allAchievements.first,
      );
      return sum + achievement.points;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withValues(alpha: 0.3),
            Colors.orange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'achievement_progress'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  '${userAchievements.length}/${allAchievements.length} unlocked',
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  '$totalPoints total points',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementSection(String title, List<EcoAchievement> achievements, bool isUnlocked) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...achievements.map((achievement) => _buildAchievementCard(achievement, isUnlocked)),
      ],
    );
  }

  Widget _buildAchievementCard(EcoAchievement achievement, bool isUnlocked) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? achievement.color.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? achievement.color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? achievement.color.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: isUnlocked ? achievement.color : Colors.grey,
              size: 24,
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
                        tr(context, achievement.nameKey),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? achievement.color : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: achievement.tierColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        achievement.tierName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: achievement.tierColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  tr(context, achievement.descriptionKey),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${achievement.points} points',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isUnlocked ? achievement.color : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return StreamBuilder<EnhancedEcoMetrics>(
      stream: _ecoService.getUserEnhancedMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final metrics = snapshot.data ?? EnhancedEcoMetrics.empty('');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInsightsCard(metrics.visualization.insights),
              const SizedBox(height: 16),
              _buildPredictionsCard(metrics.predictions),
              const SizedBox(height: 16),
              _buildPersonalBestsCard(metrics.personalBests),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightsCard(List<String> insights) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                tr(context, 'insights'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (insights.isEmpty)
            Text(
              tr(context, 'no_insights_yet'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            )
          else
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPredictionsCard(Map<String, dynamic> predictions) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                tr(context, 'predictions'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (predictions.isEmpty)
            Text(
              tr(context, 'no_predictions_yet'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            )
          else ...[
            _buildPredictionItem(
              'Projected Monthly Savings',
              '${(predictions['projectedMonthlySavings'] ?? 0.0).toStringAsFixed(1)} kg CO₂',
              predictions['onTrackForGoal'] ?? false,
            ),
            _buildPredictionItem(
              'Daily Target Recommendation',
              '${(predictions['recommendedDailyTarget'] ?? 0.0).toStringAsFixed(2)} kg CO₂',
              true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredictionItem(String title, String value, bool isPositive) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestsCard(Map<String, double> personalBests) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                tr(context, 'personal_bests'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (personalBests.isEmpty)
            Text(
              tr(context, 'no_personal_bests_yet'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            )
          else
            ...personalBests.entries.where((entry) => !entry.key.startsWith('daily_2')).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatPersonalBestKey(entry.key),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(2)} kg CO₂',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatPersonalBestKey(String key) {
    switch (key) {
      case 'daily_best':
        return 'Best Daily Impact';
      case 'weekly_best':
        return 'Best Weekly Impact';
      case 'monthly_best':
        return 'Best Monthly Impact';
      default:
        return key.replaceAll('_', ' ').split(' ').map((word) =>
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
    }
  }

  Widget _buildLeaderboardTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _ecoService.getLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final leaderboardData = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top 3 podium
              if (leaderboardData.isNotEmpty) _buildPodium(leaderboardData.take(3).toList()),
              const SizedBox(height: 20),

              // Full leaderboard
              ...leaderboardData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return _buildLeaderboardItem(index + 1, data);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topThree) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.amber.withValues(alpha: 0.3),
            Colors.orange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            tr(context, 'top_eco_champions'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (topThree.length > 1) _buildPodiumPosition(2, topThree[1], Colors.grey),
              if (topThree.isNotEmpty) _buildPodiumPosition(1, topThree[0], Colors.amber),
              if (topThree.length > 2) _buildPodiumPosition(3, topThree[2], const Color(0xFFCD7F32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(int position, Map<String, dynamic> data, Color color) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            position == 1 ? Icons.emoji_events : Icons.military_tech,
            color: color,
            size: position == 1 ? 32 : 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '#$position',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'Level ${data['level'] ?? 1}',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          '${(data['totalCarbonSaved'] ?? 0.0).toStringAsFixed(1)} kg',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(int position, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final isCurrentUser = data['userId'] == _ecoService.currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? theme.primaryColor.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? theme.primaryColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: position <= 3
                  ? [Colors.amber, Colors.grey, const Color(0xFFCD7F32)][position - 1].withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: position <= 3
                      ? [Colors.amber, Colors.grey, const Color(0xFFCD7F32)][position - 1]
                      : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? 'You' : 'User ${data['userId'].substring(0, 8)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Level ${data['level'] ?? 1} • ${data['achievementCount'] ?? 0} achievements',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(data['totalCarbonSaved'] ?? 0.0).toStringAsFixed(1)} kg',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              Text(
                'Score: ${data['ecoScore'] ?? 0}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}