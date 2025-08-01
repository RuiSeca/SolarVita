import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../models/user/supporter.dart';
import '../../../providers/riverpod/firebase_chat_provider.dart';
import '../../../providers/riverpod/user_profile_provider.dart';
import '../../chat/chat_screen.dart';
import 'supporter_profile_screen.dart';

part 'supporters_list_screen.g.dart';

// Provider for supporters list
@riverpod
Stream<List<Supporter>> supportersList(Ref ref) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getSupporters();
}

// Provider for supporting list (people I support)
@riverpod
Stream<List<Supporter>> supportingList(Ref ref) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getSupporting();
}

class SupportersListScreen extends ConsumerStatefulWidget {
  const SupportersListScreen({super.key});

  @override
  ConsumerState<SupportersListScreen> createState() =>
      _SupportersListScreenState();
}

class _SupportersListScreenState extends ConsumerState<SupportersListScreen>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          'Supporters',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.textColor(context),
          unselectedLabelColor: AppTheme.textColor(context).withAlpha(128),
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'My Supporters'),
            Tab(text: 'Supporting'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSupportersTab(), _buildSupportingTab()],
      ),
    );
  }

  Widget _buildSupporterCard(BuildContext context, Supporter supporter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SupporterProfileScreen(supporter: supporter),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Photo
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: supporter.photoURL != null
                    ? CachedNetworkImageProvider(supporter.photoURL!)
                    : null,
                child: supporter.photoURL == null
                    ? Icon(Icons.person, size: 30, color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(width: 16),

              // Supporter Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supporter.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    if (supporter.username != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${supporter.username}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (supporter.ecoScore != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.eco, size: 16, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Eco Score: ${supporter.ecoScore}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Chat navigation button
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
                onPressed: () => _openChat(supporter),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportersTab() {
    final supportersAsync = ref.watch(supportersListProvider);
    return supportersAsync.when(
      data: (supporters) {
        if (supporters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No supporters yet',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start connecting with supporters',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: supporters.length,
          itemExtent: 128.0,
          itemBuilder: (context, index) {
            final supporter = supporters[index];
            return _buildSupporterCard(context, supporter);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading supporters',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportingTab() {
    final supportingAsync = ref.watch(supportingListProvider);
    return supportingAsync.when(
      data: (supporting) {
        if (supporting.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_add_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Not supporting anyone yet',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find people to support and build connections',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: supporting.length,
          itemExtent: 128.0,
          itemBuilder: (context, index) {
            final supporter = supporting[index];
            return _buildSupporterCard(context, supporter);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading supporting list',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(Supporter supporter) async {
    try {
      final conversation = await ref.read(
        getOrCreateConversationProvider(otherUserId: supporter.userId).future,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.conversationId,
              otherUserId: supporter.userId,
              otherUserName: supporter.displayName,
              otherUserPhotoURL: supporter.photoURL,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
