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
    final theme = Theme.of(context);

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
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor(context),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getCategoryColor(widget.challenge.type),
                _getCategoryColor(widget.challenge.type).withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.challenge.icon,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.challenge.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.challenge.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textColor(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                icon: Icons.people,
                label: '${widget.challenge.getTotalParticipants()} participants',
                color: Colors.blue,
              ),
              _buildInfoChip(
                icon: Icons.timer,
                label: '${widget.challenge.daysRemaining} days left',
                color: widget.challenge.daysRemaining > 7
                    ? Colors.green
                    : widget.challenge.daysRemaining > 3
                        ? Colors.orange
                        : Colors.red,
              ),
              _buildInfoChip(
                icon: Icons.flag,
                label: 'Goal: ${widget.challenge.targetValue} ${widget.challenge.unit}',
                color: Colors.purple,
              ),
              _buildInfoChip(
                icon: _getModeIcon(widget.challenge.mode),
                label: _getModeLabel(widget.challenge.mode),
                color: _getModeColor(widget.challenge.mode),
              ),
              _buildInfoChip(
                icon: Icons.category,
                label: _getCategoryLabel(widget.challenge.type),
                color: _getCategoryColor(widget.challenge.type),
              ),
              if (widget.challenge.prize != null)
                _buildInfoChip(
                  icon: Icons.card_giftcard,
                  label: 'Prize: ${widget.challenge.prize}',
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
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Leaderboard'),
          Tab(text: 'Teams'),
        ],
        labelColor: theme.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: theme.primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
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

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Challenge Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}% complete',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${widget.challenge.daysRemaining} days remaining',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
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
            color: Colors.green,
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
                Icon(Icons.leaderboard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No participants yet'),
                Text('Be the first to join!'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            return _buildLeaderboardItem(team, index + 1);
          },
        );
      },
    );
  }

  Widget _buildLeaderboardItem(ChallengeTeam team, int rank) {
    final theme = Theme.of(context);
    Color rankColor;

    switch (rank) {
      case 1:
        rankColor = Colors.amber;
        break;
      case 2:
        rankColor = Colors.grey;
        break;
      case 3:
        rankColor = Colors.brown;
        break;
      default:
        rankColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.bold,
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
                    team.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  Text(
                    '${team.memberCount} members',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${team.totalScore} pts',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.challenge.teams.length,
      itemBuilder: (context, index) {
        final team = widget.challenge.teams[index];
        return _buildTeamCard(team);
      },
    );
  }

  Widget _buildTeamCard(ChallengeTeam team) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                  child: Text(
                    team.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      if (team.description != null)
                        Text(
                          team.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${team.totalScore}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${team.memberCount} members',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created ${_formatDate(team.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                if (!team.isFullForChallenge(widget.challenge.maxTeamSize))
                  TextButton(
                    onPressed: () => _joinTeam(team),
                    child: const Text('Join'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

  void _joinTeam(ChallengeTeam team) {
    // Implement team joining logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining team "${team.name}"...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
      return FloatingActionButton.extended(
        onPressed: _joinChallenge,
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add),
        label: Text(tr(context, 'join_challenge')),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () => _showVerificationOptions(userTeam?.id),
          backgroundColor: theme.primaryColor,
          heroTag: 'verify',
          child: const Icon(Icons.camera_alt),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: () => _showVerificationHistory(userTeam?.id),
          backgroundColor: theme.primaryColor.withValues(alpha: 0.8),
          heroTag: 'history',
          child: const Icon(Icons.history),
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