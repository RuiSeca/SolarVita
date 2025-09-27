import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/community_challenge.dart';
import '../../services/community/community_challenge_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import 'challenge_detail_screen.dart';
import 'challenge_participation_screen.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityChallengeService _challengeService = CommunityChallengeService();

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
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: theme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              tr(context, 'challenges'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              child: _buildTabItem(Icons.public, tr(context, 'global')),
            ),
            Tab(
              child: _buildTabItem(Icons.person, tr(context, 'individual')),
            ),
            Tab(
              child: _buildTabItem(Icons.group, tr(context, 'team')),
            ),
            Tab(
              child: _buildTabItem(Icons.schedule, tr(context, 'my_challenges')),
            ),
          ],
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: theme.primaryColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalChallenges(),
          _buildIndividualChallenges(),
          _buildTeamChallenges(),
          _buildMyChallenges(),
        ],
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildGlobalChallenges() {
    return StreamBuilder<List<CommunityChallenge>>(
      stream: _challengeService.getActiveChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final challenges = snapshot.data ?? [];
        // Global tab shows ALL active challenges
        final globalChallenges = challenges;

        if (globalChallenges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.public,
            title: 'No Global Challenges',
            subtitle: 'Check back soon for worldwide challenges!',
          );
        }

        return _buildChallengesList(globalChallenges);
      },
    );
  }

  Widget _buildIndividualChallenges() {
    return StreamBuilder<List<CommunityChallenge>>(
      stream: _challengeService.getActiveChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final challenges = snapshot.data ?? [];
        final individualChallenges = challenges
            .where((challenge) =>
                challenge.mode == ChallengeMode.individual ||
                challenge.mode == ChallengeMode.mixed)
            .toList();

        if (individualChallenges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person,
            title: 'No Individual Challenges',
            subtitle: 'Personal challenges are coming soon!',
          );
        }

        return _buildChallengesList(individualChallenges);
      },
    );
  }

  Widget _buildTeamChallenges() {
    return StreamBuilder<List<CommunityChallenge>>(
      stream: _challengeService.getActiveChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final challenges = snapshot.data ?? [];
        final teamChallenges = challenges
            .where((challenge) =>
                challenge.mode == ChallengeMode.team ||
                challenge.mode == ChallengeMode.mixed)
            .toList();

        if (teamChallenges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.group,
            title: 'No Team Challenges',
            subtitle: 'Team up with friends for upcoming challenges!',
          );
        }

        return _buildChallengesList(teamChallenges);
      },
    );
  }

  Widget _buildMyChallenges() {
    return StreamBuilder<List<CommunityChallenge>>(
      stream: _challengeService.getUserParticipatingChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.schedule,
            title: 'No Active Challenges',
            subtitle: 'Join a challenge to see your progress here!',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return _buildMyChallengeCard(challenge);
            },
          ),
        );
      },
    );
  }

  Widget _buildChallengesList(List<CommunityChallenge> challenges) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Trigger rebuild
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return _buildChallengeCard(challenge);
        },
      ),
    );
  }

  Widget _buildMyChallengeCard(CommunityChallenge challenge) {
    final theme = Theme.of(context);
    final userTeam = _challengeService.getUserTeamForChallenge(challenge);
    final isInTeam = userTeam != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.cardColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openChallengeDetail(challenge),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(challenge.type),
                          _getCategoryColor(challenge.type).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        challenge.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isInTeam ? Icons.group : Icons.person,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isInTeam ? 'Team: ${userTeam.name}' : 'Individual',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      Text(
                        isInTeam ? '${userTeam.totalScore}/${challenge.targetValue}' : '0/${challenge.targetValue}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: isInTeam
                        ? (userTeam.totalScore / challenge.targetValue).clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.timer,
                    label: '${challenge.daysRemaining}d left',
                    color: challenge.daysRemaining > 7
                        ? Colors.green
                        : challenge.daysRemaining > 3
                            ? Colors.orange
                            : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  if (isInTeam)
                    _buildInfoChip(
                      icon: Icons.people,
                      label: '${userTeam.memberIds.length} members',
                      color: Colors.blue,
                    ),
                  const Spacer(),
                  if (challenge.prize != null)
                    _buildInfoChip(
                      icon: Icons.card_giftcard,
                      label: challenge.prize!,
                      color: Colors.amber,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(CommunityChallenge challenge) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.cardColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openChallengeDetail(challenge),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(challenge.type),
                          _getCategoryColor(challenge.type).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        challenge.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${challenge.getTotalParticipants()}',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.timer,
                    label: '${challenge.daysRemaining}d',
                    color: challenge.daysRemaining > 7
                        ? Colors.green
                        : challenge.daysRemaining > 3
                            ? Colors.orange
                            : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: _getModeIcon(challenge.mode),
                    label: _getModeLabel(challenge.mode),
                    color: _getModeColor(challenge.mode),
                  ),
                  const Spacer(),
                  if (challenge.prize != null)
                    _buildInfoChip(
                      icon: Icons.card_giftcard,
                      label: challenge.prize!,
                      color: Colors.amber,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _joinChallenge(challenge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    challenge.acceptsTeams && challenge.acceptsIndividuals
                        ? 'Join Challenge'
                        : challenge.acceptsTeams
                            ? 'Join as Team'
                            : 'Join Individual',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openChallengeDetail(CommunityChallenge challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeDetailScreen(challenge: challenge),
      ),
    );
  }

  void _joinChallenge(CommunityChallenge challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeParticipationScreen(challenge: challenge),
      ),
    );
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
        return 'Solo';
      case ChallengeMode.team:
        return 'Team';
      case ChallengeMode.mixed:
        return 'Global';
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
}