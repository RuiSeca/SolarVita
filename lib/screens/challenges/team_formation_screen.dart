import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/community_challenge.dart';
import '../../services/user/user_service.dart';
import '../../services/community/community_challenge_service.dart';
import '../../theme/app_theme.dart';
import '../challenges/challenge_participation_screen.dart';

class TeamFormationScreen extends ConsumerStatefulWidget {
  final CommunityChallenge challenge;
  final ParticipationMode mode;

  const TeamFormationScreen({
    super.key,
    required this.challenge,
    required this.mode,
  });

  @override
  ConsumerState<TeamFormationScreen> createState() => _TeamFormationScreenState();
}

class _TeamFormationScreenState extends ConsumerState<TeamFormationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityChallengeService _challengeService = CommunityChallengeService();
  final UserService _userService = UserService();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _teamDescriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<ChallengeTeam> _availableTeams = [];
  List<UserModel> _supporters = [];
  List<UserModel> _searchResults = [];
  final List<String> _selectedSupporterIds = [];
  bool _isLoading = false;
  bool _isCreatingTeam = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.mode == ParticipationMode.teamWithAnyone ? 2 : 1,
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teamNameController.dispose();
    _teamDescriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.mode == ParticipationMode.teamWithSupporter) {
        _supporters = await _userService.getUserSupporters();
      } else if (widget.mode == ParticipationMode.teamWithAnyone) {
        _availableTeams = await _challengeService.getAvailableTeamsForChallenge(widget.challenge.id);
      }
    } catch (e) {
      _showErrorSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          widget.mode == ParticipationMode.teamWithSupporter
              ? 'Team with Supporters'
              : 'Join Open Team',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: widget.mode == ParticipationMode.teamWithAnyone
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Join Team'),
                  Tab(text: 'Create Team'),
                ],
                labelColor: theme.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: theme.primaryColor,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.mode == ParticipationMode.teamWithAnyone
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJoinTeamTab(),
                    _buildCreateTeamTab(),
                  ],
                )
              : _buildSupporterTeamTab(),
    );
  }

  Widget _buildSupporterTeamTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChallengeInfo(),
                const SizedBox(height: 24),
                _buildTeamCreationForm(),
                const SizedBox(height: 24),
                _buildSupporterSelection(),
              ],
            ),
          ),
        ),
        _buildCreateTeamButton(),
      ],
    );
  }

  Widget _buildJoinTeamTab() {
    return Column(
      children: [
        Expanded(
          child: _availableTeams.isEmpty
              ? _buildEmptyTeamsState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _availableTeams.length,
                  itemBuilder: (context, index) {
                    final team = _availableTeams[index];
                    return _buildTeamCard(team);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCreateTeamTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChallengeInfo(),
                const SizedBox(height: 24),
                _buildTeamCreationForm(),
                const SizedBox(height: 24),
                _buildUserSearch(),
              ],
            ),
          ),
        ),
        _buildCreatePublicTeamButton(),
      ],
    );
  }

  Widget _buildChallengeInfo() {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(widget.challenge.type),
                        _getCategoryColor(widget.challenge.type).withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      widget.challenge.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.challenge.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      Text(
                        '${widget.challenge.daysRemaining} days remaining',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildTeamCreationForm() {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teamNameController,
              decoration: InputDecoration(
                labelText: 'Team Name',
                hintText: 'Enter your team name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
              ),
              maxLength: 30,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teamDescriptionController,
              decoration: InputDecoration(
                labelText: 'Team Description (Optional)',
                hintText: 'Describe your team goals...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
              ),
              maxLines: 3,
              maxLength: 150,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupporterSelection() {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite Supporters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select supporters to invite to your team',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_supporters.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No supporters found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_supporters.map((supporter) => _buildSupporterTile(supporter))),
          ],
        ),
      ),
    );
  }

  Widget _buildSupporterTile(UserModel supporter) {
    final isSelected = _selectedSupporterIds.contains(supporter.id);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedSupporterIds.add(supporter.id);
          } else {
            _selectedSupporterIds.remove(supporter.id);
          }
        });
      },
      title: Text(supporter.name),
      subtitle: Text(supporter.email),
      secondary: CircleAvatar(
        backgroundImage: supporter.profilePictureUrl != null
            ? NetworkImage(supporter.profilePictureUrl!)
            : null,
        child: supporter.profilePictureUrl == null
            ? Text(supporter.name.isNotEmpty ? supporter.name[0].toUpperCase() : 'U')
            : null,
      ),
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildUserSearch() {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite Users',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
                hintText: 'Enter username or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
              ),
              onChanged: _performUserSearch,
            ),
            const SizedBox(height: 16),
            if (_searchResults.isNotEmpty)
              Column(
                children: _searchResults.map((user) => _buildUserSearchResult(user)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchResult(UserModel user) {
    final isSelected = _selectedSupporterIds.contains(user.id);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.profilePictureUrl != null
            ? NetworkImage(user.profilePictureUrl!)
            : null,
        child: user.profilePictureUrl == null
            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U')
            : null,
      ),
      title: Text(user.name),
      subtitle: Text(user.email),
      trailing: IconButton(
        icon: Icon(
          isSelected ? Icons.remove_circle : Icons.add_circle,
          color: isSelected ? Colors.red : Theme.of(context).primaryColor,
        ),
        onPressed: () {
          setState(() {
            if (isSelected) {
              _selectedSupporterIds.remove(user.id);
            } else {
              _selectedSupporterIds.add(user.id);
            }
          });
        },
      ),
    );
  }

  Widget _buildTeamCard(ChallengeTeam team) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardColor(context),
      child: InkWell(
        onTap: () => _joinExistingTeam(team),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.group,
                      color: theme.primaryColor,
                      size: 24,
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
                        if (team.description?.isNotEmpty == true)
                          Text(
                            team.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
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
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTeamInfoChip(
                    icon: Icons.people,
                    label: '${team.memberIds.length}/8 members',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildTeamInfoChip(
                    icon: Icons.trending_up,
                    label: '${team.totalScore}/100',
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInfoChip({
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

  Widget _buildEmptyTeamsState() {
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
              Icons.group_off,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Open Teams',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to create a team for this challenge!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTeamButton() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCreatingTeam || _teamNameController.text.trim().isEmpty
                ? null
                : _createSupporterTeam,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isCreatingTeam
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Team',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePublicTeamButton() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCreatingTeam || _teamNameController.text.trim().isEmpty
                ? null
                : _createPublicTeam,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isCreatingTeam
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Public Team',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _performUserSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }

    try {
      final results = await _userService.searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      _showErrorSnackBar('Error searching users: $e');
    }
  }

  Future<void> _createSupporterTeam() async {
    if (_teamNameController.text.trim().isEmpty) return;

    setState(() => _isCreatingTeam = true);

    try {
      final team = ChallengeTeam(
        id: '',
        name: _teamNameController.text.trim(),
        description: _teamDescriptionController.text.trim(),
        captainId: _userService.currentUserId ?? '',
        memberIds: [_userService.currentUserId ?? '', ..._selectedSupporterIds],
        totalScore: 0,
        createdAt: DateTime.now(),
      );

      final success = await _challengeService.createTeamAndJoin(team, widget.challenge.id);
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        _showErrorSnackBar('Failed to create team');
      }
    } catch (e) {
      _showErrorSnackBar('Error creating team: $e');
    } finally {
      setState(() => _isCreatingTeam = false);
    }
  }

  Future<void> _createPublicTeam() async {
    if (_teamNameController.text.trim().isEmpty) return;

    setState(() => _isCreatingTeam = true);

    try {
      final team = ChallengeTeam(
        id: '',
        name: _teamNameController.text.trim(),
        description: _teamDescriptionController.text.trim(),
        captainId: _userService.currentUserId ?? '',
        memberIds: [_userService.currentUserId ?? '', ..._selectedSupporterIds],
        totalScore: 0,
        createdAt: DateTime.now(),
      );

      final success = await _challengeService.createTeamAndJoin(team, widget.challenge.id);
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        _showErrorSnackBar('Failed to create team');
      }
    } catch (e) {
      _showErrorSnackBar('Error creating team: $e');
    } finally {
      setState(() => _isCreatingTeam = false);
    }
  }

  Future<void> _joinExistingTeam(ChallengeTeam team) async {
    try {
      final success = await _challengeService.joinExistingTeam(
        widget.challenge.id,
        team.id,
      );
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        _showErrorSnackBar('Failed to join team');
      }
    } catch (e) {
      _showErrorSnackBar('Error joining team: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
}