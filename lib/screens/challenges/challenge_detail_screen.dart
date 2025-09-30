import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/community_challenge.dart';
import '../../services/community/community_challenge_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import 'challenge_participation_screen.dart';
import 'challenge_verification_screen.dart';
import 'verification_history_screen.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  final CommunityChallenge challenge;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
  });

  @override
  ConsumerState<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityChallengeService _challengeService = CommunityChallengeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildChallengeHeader(),
                _buildTabBar(),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildLeaderboardTab(),
                _buildTeamsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: widget.challenge.imageUrl != null ? 300 : 200,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor(context),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.challenge.imageUrl != null)
              Image.network(
                widget.challenge.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackHeader(),
              )
            else
              _buildFallbackHeader(),
            // Gradient overlay for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Content overlay
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
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
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.challenge.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.challenge.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _getCategoryLabel(widget.challenge.type),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildFallbackHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(widget.challenge.type),
            _getCategoryColor(widget.challenge.type).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildChallengeHeader() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.challenge.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textColor(context),
              height: 1.6,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          _buildCommunityGoalProgress(),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildModernInfoChip(
                icon: Icons.people,
                label: '${widget.challenge.getTotalParticipants()}',
                subLabel: 'participants',
                color: Colors.blue,
              ),
              _buildModernInfoChip(
                icon: Icons.timer,
                label: '${widget.challenge.daysRemaining}',
                subLabel: 'days left',
                color: widget.challenge.daysRemaining > 7
                    ? Colors.green
                    : widget.challenge.daysRemaining > 3
                        ? Colors.orange
                        : Colors.red,
              ),
              _buildModernInfoChip(
                icon: _getModeIcon(widget.challenge.mode),
                label: _getModeLabel(widget.challenge.mode),
                subLabel: 'mode',
                color: _getModeColor(widget.challenge.mode),
              ),
              if (widget.challenge.prizeConfiguration.communityPrize != null)
                _buildModernInfoChip(
                  icon: Icons.card_giftcard,
                  label: widget.challenge.prizeConfiguration.communityPrize!,
                  subLabel: 'community prize',
                  color: Colors.amber,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Individual'),
          Tab(text: 'Teams'),
        ],
        labelColor: theme.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressCard(),
          const SizedBox(height: 16),
          _buildDetailsCard(),
          const SizedBox(height: 16),
          _buildRulesCard(),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final theme = Theme.of(context);
    final progress = widget.challenge.progressPercentage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Challenge Progress',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * (progress / 100),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${progress.toStringAsFixed(1)}%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  Text(
                    'Complete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.challenge.daysRemaining}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  Text(
                    'Days left',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Challenge Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Start Date', _formatDate(widget.challenge.startDate)),
            _buildDetailRow('End Date', _formatDate(widget.challenge.endDate)),
            _buildDetailRow('Duration', '${widget.challenge.endDate.difference(widget.challenge.startDate).inDays} days'),
            _buildDetailRow('Category', _getCategoryLabel(widget.challenge.type)),
            _buildDetailRow('Mode', _getModeLabel(widget.challenge.mode)),
            if (widget.challenge.maxTeamSize != null)
              _buildDetailRow('Max Team Size', '${widget.challenge.maxTeamSize} members'),
            if (widget.challenge.maxTeams != null)
              _buildDetailRow('Max Teams', '${widget.challenge.maxTeams} teams'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Rules & Guidelines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRuleItem('Complete daily activities to earn points'),
            _buildRuleItem('Submit photo verification when required'),
            _buildRuleItem('Respect other participants and be supportive'),
            _buildRuleItem('No cheating or fraudulent submissions'),
            _buildRuleItem('Follow community guidelines at all times'),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rule,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    // This will be the Individual Leaderboard
    return FutureBuilder<List<IndividualParticipant>>(
      future: _challengeService.getIndividualLeaderboard(widget.challenge.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final individuals = snapshot.data ?? [];

        if (individuals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No individual participants yet'),
                Text('Be the first to join individually!'),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildPrizeInfo(isIndividual: true),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: individuals.length,
                itemBuilder: (context, index) {
                  final participant = individuals[index];
                  return _buildIndividualLeaderboardItem(participant, index + 1);
                },
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildTeamsTab() {
    if (!widget.challenge.acceptsTeams) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Individual Challenge'),
            Text('This challenge is for individual participation only'),
          ],
        ),
      );
    }

    // This will be the Team Leaderboard
    return FutureBuilder<List<ChallengeTeam>>(
      future: _challengeService.getTeamLeaderboard(widget.challenge.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final teams = snapshot.data ?? [];

        if (teams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No teams yet'),
                Text('Create or join a team to get started!'),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildPrizeInfo(isIndividual: false),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return _buildTeamLeaderboardItem(team, index + 1);
                },
              ),
            ),
          ],
        );
      },
    );
  }



  void _joinChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeParticipationScreen(
          challenge: widget.challenge,
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCommunityGoalProgress() {
    final theme = Theme.of(context);
    final goal = widget.challenge.communityGoal;
    final progress = goal.currentProgress / goal.targetValue;
    final percentage = (progress * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Community Goal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * progress.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple,
                        Colors.purple.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.currentProgress} / ${goal.targetValue} ${goal.unit}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoChip({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Theme.of(context).primaryColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrizeInfo({required bool isIndividual}) {
    final theme = Theme.of(context);
    final prizeConfig = widget.challenge.prizeConfiguration;
    final communityGoal = widget.challenge.communityGoal;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: theme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                '${isIndividual ? 'Individual' : 'Team'} Prize Tiers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Community goal requirement notice
          if (prizeConfig.communityGoalRequired) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: communityGoal.isReached ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: communityGoal.isReached ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    communityGoal.isReached ? Icons.check_circle : Icons.warning,
                    color: communityGoal.isReached ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      communityGoal.isReached
                          ? 'Community goal reached! Prizes will be distributed.'
                          : 'Community goal must be reached for prize distribution.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: communityGoal.isReached ? Colors.green[800] : Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Prize tiers
          _buildPrizeTierDisplay(isIndividual),
        ],
      ),
    );
  }

  Widget _buildPrizeTierDisplay(bool isIndividual) {
    final prizeConfig = widget.challenge.prizeConfiguration;
    final prizes = isIndividual ? prizeConfig.individualPrizes : prizeConfig.teamPrizes;
    final tier = isIndividual ? prizeConfig.individualPrizeTier : prizeConfig.teamPrizeTier;

    if (prizes.isEmpty) {
      return Text(
        'No prizes configured for ${isIndividual ? 'individual' : 'team'} participants.',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      );
    }

    final tierCounts = _getPrizeTierCounts(tier);

    return Column(
      children: [
        for (int i = 0; i < prizes.length && i < tierCounts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getRankColor(i + 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getRankIcon(i + 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_getRankLabel(i + 1, tierCounts[i])}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Text(
                    prizes[i],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildIndividualLeaderboardItem(IndividualParticipant participant, int rank) {
    final theme = Theme.of(context);
    final rankColor = _getRankColor(rank);
    final willReceivePrize = _willReceivePrize(rank, true);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: willReceivePrize
            ? theme.primaryColor.withValues(alpha: 0.05)
            : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: willReceivePrize
              ? theme.primaryColor.withValues(alpha: 0.2)
              : theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rank <= 3 ? rankColor.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                _getRankIcon(rank),
                style: TextStyle(
                  color: rank <= 3 ? rankColor : AppTheme.textColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: rank <= 3 ? 16 : 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      participant.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    if (participant.teamName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          participant.teamName!,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (!participant.meetMinimumRequirement)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Below minimum',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (willReceivePrize) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Prize winner',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${participant.score}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
              Text(
                'points',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLeaderboardItem(ChallengeTeam team, int rank) {
    final theme = Theme.of(context);
    final rankColor = _getRankColor(rank);
    final willReceivePrize = _willReceivePrize(rank, false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: willReceivePrize
            ? theme.primaryColor.withValues(alpha: 0.05)
            : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: willReceivePrize
              ? theme.primaryColor.withValues(alpha: 0.2)
              : theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [rankColor, rankColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                _getRankIcon(rank),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Team info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTeamStat(Icons.people, '${team.memberCount} members'),
                    if (willReceivePrize) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Prize winner',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${team.totalScore}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
              Text(
                'points',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _getPrizeTierCounts(PrizeTier tier) {
    switch (tier) {
      case PrizeTier.top3:
        return [1, 2, 3];
      case PrizeTier.top5:
        return [1, 2, 3, 4, 5];
      case PrizeTier.top10:
        return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      case PrizeTier.top15:
        return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
      case PrizeTier.top20:
        return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    }
  }

  bool _willReceivePrize(int rank, bool isIndividual) {
    final prizeConfig = widget.challenge.prizeConfiguration;
    final tier = isIndividual ? prizeConfig.individualPrizeTier : prizeConfig.teamPrizeTier;
    final maxPrizeRank = _getPrizeTierCounts(tier).length;

    return rank <= maxPrizeRank &&
           (!prizeConfig.communityGoalRequired || widget.challenge.communityGoal.isReached);
  }

  Color _getRankColor(int rank) {
    final theme = Theme.of(context);
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.brown;
      default:
        return theme.primaryColor;
    }
  }

  String _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  String _getRankLabel(int rank, int count) {
    switch (rank) {
      case 1:
        return '1st Place';
      case 2:
        return '2nd Place';
      case 3:
        return '3rd Place';
      default:
        return '$rank${_getOrdinalSuffix(rank)} Place';
    }
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Color _getCategoryColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.fitness:
        return Colors.orange;
      case ChallengeType.nutrition:
        return Colors.green;
      case ChallengeType.sustainability:
        return Colors.teal;
      case ChallengeType.community:
        return Colors.indigo;
    }
  }

  String _getCategoryLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.fitness:
        return 'Fitness';
      case ChallengeType.nutrition:
        return 'Nutrition';
      case ChallengeType.sustainability:
        return 'Sustainability';
      case ChallengeType.community:
        return 'Community';
    }
  }

  IconData _getModeIcon(ChallengeMode mode) {
    switch (mode) {
      case ChallengeMode.individual:
        return Icons.person;
      case ChallengeMode.team:
        return Icons.group;
      case ChallengeMode.mixed:
        return Icons.public;
    }
  }

  String _getModeLabel(ChallengeMode mode) {
    switch (mode) {
      case ChallengeMode.individual:
        return 'Individual Only';
      case ChallengeMode.team:
        return 'Team Only';
      case ChallengeMode.mixed:
        return 'Individual & Team';
    }
  }

  Color _getModeColor(ChallengeMode mode) {
    switch (mode) {
      case ChallengeMode.individual:
        return Colors.blue;
      case ChallengeMode.team:
        return Colors.green;
      case ChallengeMode.mixed:
        return Colors.purple;
    }
  }

  Widget _buildActionButton() {
    final theme = Theme.of(context);
    final isParticipating = _challengeService.isUserParticipating(widget.challenge);
    final userTeam = _challengeService.getUserTeamForChallenge(widget.challenge);

    if (!isParticipating) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _joinChallenge,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Join Challenge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _showVerificationOptions(userTeam?.id),
            backgroundColor: Colors.transparent,
            elevation: 0,
            heroTag: 'verify',
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withValues(alpha: 0.7),
                theme.primaryColor.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _showVerificationHistory(userTeam?.id),
            backgroundColor: Colors.transparent,
            elevation: 0,
            heroTag: 'history',
            child: const Icon(Icons.history, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showVerificationOptions(String? teamId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textColor(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr(context, 'verification_options'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(
                tr(context, 'submit_verification'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                tr(context, 'capture_photo_and_earn_points'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToVerification(teamId);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(
                tr(context, 'view_history'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                tr(context, 'see_previous_verifications'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showVerificationHistory(teamId);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToVerification(String? teamId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeVerificationScreen(
          challenge: widget.challenge,
          teamId: teamId,
        ),
      ),
    );
  }

  void _showVerificationHistory(String? teamId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationHistoryScreen(
          challenge: widget.challenge,
          teamId: teamId,
        ),
      ),
    );
  }
}