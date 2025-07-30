// lib/widgets/social/user_autocomplete_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../../models/user_mention.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

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
      // Query Firebase for users matching the search term
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('searchTerms', arrayContainsAny: [
            widget.query.toLowerCase(),
            widget.query.toLowerCase().substring(0, math.min(3, widget.query.length)),
          ])
          .limit(widget.maxResults)
          .get();

      final filteredUsers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return MentionableUser(
          userId: doc.id,
          userName: data['userName'] ?? '',
          displayName: data['displayName'] ?? data['fullName'] ?? '',
          avatarUrl: data['avatarUrl'],
          isFollowing: data['isFollowing'] ?? false,
          isSupporter: data['isSupporter'] ?? false,
        );
      }).where((user) => user.matchesQuery(widget.query)).toList();

      // If no results from Firebase, fall back to mock data for development
      final finalUsers = filteredUsers.isEmpty ? 
          _getMockUsers().where((user) => user.matchesQuery(widget.query)).take(widget.maxResults).toList() :
          filteredUsers;

      setState(() {
        _users = finalUsers;
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
    // Get recent users from Firebase (users the current user has interacted with)
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('recent_interactions')
        .orderBy('lastInteraction', descending: true)
        .limit(widget.maxResults)
        .get()
        .then((querySnapshot) {
      final recentUsers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return MentionableUser(
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? '',
          displayName: data['displayName'] ?? '',
          avatarUrl: data['avatarUrl'],
          isFollowing: data['isFollowing'] ?? false,
          isSupporter: data['isSupporter'] ?? false,
        );
      }).toList();
      
      if (mounted) {
        setState(() {
          _users = recentUsers;
        });
      }
    }).catchError((e) {
      // Fall back to mock data if Firebase fails
      if (mounted) {
        setState(() {
          _users = _getMockUsers().take(widget.maxResults).toList();
        });
      }
    });
    
    // Return mock data initially while Firebase loads
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
              ? tr(context, 'start_typing_search')
              : tr(context, 'no_users_found').replaceAll('{query}', widget.query),
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
                    tr(context, 'recent'),
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
                          child: Text(
                            tr(context, 'sup'),
                            style: const TextStyle(
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
                  tr(context, 'following'),
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