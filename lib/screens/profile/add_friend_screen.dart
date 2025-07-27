import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/supporter.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import 'supporter_profile_screen.dart';

class AddSupporterScreen extends StatefulWidget {
  const AddSupporterScreen({super.key});

  @override
  State<AddSupporterScreen> createState() => _AddSupporterScreenState();
}

class _AddSupporterScreenState extends State<AddSupporterScreen> {
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Supporter> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.trim();
    });

    try {
      final results = await _socialService.searchUsers(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _findUserByUsername(String username) async {
    if (username.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final user = await _socialService.findUserByUsername(username.trim());
      if (mounted) {
        setState(() {
          _searchResults = user != null ? [user] : [];
          _isSearching = false;
        });
        
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendSupporterRequest(String userId, String userName) {
    _showSupportRequestDialog(userId, userName);
  }
  
  void _showSupportRequestDialog(String userId, String userName) {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          'Send Support Request',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a support request to $userName',
              style: TextStyle(
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLength: 250,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Optional message',
                hintText: 'Introduce yourself or explain why you\'d like to connect...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(153),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendSupportRequestWithMessage(userId, userName, messageController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Send Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSupportRequestWithMessage(String userId, String userName, String message) async {
    try {
      // Send support request with optional message
      await _socialService.sendSupporterRequest(userId, message: message.isNotEmpty ? message : null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Support request sent to $userName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending support request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: const Text('Add Supporter'),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchHeader(theme),
            const SizedBox(height: 24),
            _buildSearchField(theme),
            const SizedBox(height: 24),
            _buildSearchResults(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find Supporters',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Search by username to find and add supporters',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'Enter username...',
            prefixIcon: Icon(Icons.search, color: theme.primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
          ),
          onChanged: (value) {
            setState(() {});
            // Debounce search to avoid too many API calls
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchController.text == value && value.isNotEmpty) {
                _searchUsers(value);
              }
            });
          },
          onSubmitted: _findUserByUsername,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _searchController.text.isEmpty 
                ? null 
                : () => _findUserByUsername(_searchController.text),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Search'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_isSearching) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search,
                size: 64,
                color: theme.hintColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Start typing to search for supporters',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: theme.hintColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different username',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return _buildUserCard(user, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Supporter user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _viewUserProfile(user),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.primaryColor.withAlpha(51),
                      backgroundImage: user.photoURL != null ? CachedNetworkImageProvider(user.photoURL!) : null,
                      child: user.photoURL == null
                          ? Text(
                              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            )
                          : null,
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
                                  user.displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: theme.hintColor,
                              ),
                            ],
                          ),
                          if (user.username != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '@${user.username}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (user.ecoScore != null) ...[
                                const Text('🌱', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  'Eco Score: ${user.ecoScore}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '• Tap to view profile',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                  fontSize: 11,
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
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _sendSupporterRequest(user.userId, user.displayName),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Send Request',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewUserProfile(Supporter user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupporterProfileScreen(supporter: user),
      ),
    );
  }
}