// lib/widgets/social/user_autocomplete_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_mention.dart';
import '../../theme/app_theme.dart';

class UserAutocompleteWidget extends StatefulWidget {
  final String query;
  final Function(MentionableUser) onUserSelected;
  final VoidCallback onDismiss;
  final int maxResults;

  const UserAutocompleteWidget({
    super.key,
    required this.query,
    required this.onUserSelected,
    required this.onDismiss,
    this.maxResults = 5,
  });

  @override
  State<UserAutocompleteWidget> createState() => _UserAutocompleteWidgetState();
}

class _UserAutocompleteWidgetState extends State<UserAutocompleteWidget> {
  List<MentionableUser> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchUsers();
  }

  @override
  void didUpdateWidget(UserAutocompleteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _searchUsers();
    }
  }

  Future<void> _searchUsers() async {
    if (widget.query.isEmpty) {
      setState(() {
        _users = _getRecentUsers();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Replace with actual Firebase query
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay
      
      final allUsers = _getMockUsers();
      final filteredUsers = allUsers
          .where((user) => user.matchesQuery(widget.query))
          .take(widget.maxResults)
          .toList();

      setState(() {
        _users = filteredUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _users = [];
        _isLoading = false;
      });
    }
  }

  List<MentionableUser> _getRecentUsers() {
    // TODO: Get from shared preferences or Firebase
    return _getMockUsers().take(widget.maxResults).toList();
  }

  List<MentionableUser> _getMockUsers() {
    // Mock data - replace with actual Firebase query
    return [
      MentionableUser(
        userId: 'user1',
        userName: 'sarah_fitness',
        displayName: 'Sarah Johnson',
        avatarUrl: null,
        isFollowing: true,
        isSupporter: true,
      ),
      MentionableUser(
        userId: 'user2',
        userName: 'mike_runner',
        displayName: 'Mike Chen',
        avatarUrl: null,
        isFollowing: true,
        isSupporter: false,
      ),
      MentionableUser(
        userId: 'user3',
        userName: 'emma_yoga',
        displayName: 'Emma Wilson',
        avatarUrl: null,
        isFollowing: false,
        isSupporter: true,
      ),
      MentionableUser(
        userId: 'user4',
        userName: 'alex_eco',
        displayName: 'Alex Rodriguez',
        avatarUrl: null,
        isFollowing: true,
        isSupporter: true,
      ),
      MentionableUser(
        userId: 'user5',
        userName: 'jessica_nutrition',
        displayName: 'Jessica Brown',
        avatarUrl: null,
        isFollowing: false,
        isSupporter: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          widget.query.isEmpty 
              ? 'Start typing to search users...'
              : 'No users found matching "${widget.query}"',
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(128),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.query.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.textColor(context).withAlpha(13),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: AppTheme.textColor(context).withAlpha(128),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context).withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _users.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppTheme.textColor(context).withAlpha(26),
              ),
              itemBuilder: (context, index) {
                final user = _users[index];
                return _buildUserTile(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(MentionableUser user) {
    return InkWell(
      onTap: () => widget.onUserSelected(user),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              backgroundColor: AppTheme.textFieldBackground(context),
              child: user.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      color: AppTheme.textColor(context).withAlpha(128),
                      size: 18,
                    )
                  : null,
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
                        user.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      if (user.isSupporter) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(51),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SUP',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.userName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textColor(context).withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
            
            // Following indicator
            if (user.isFollowing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Following',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}