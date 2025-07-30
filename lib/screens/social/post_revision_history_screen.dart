// lib/screens/social/post_revision_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_revision.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/common/lottie_loading_widget.dart';

class PostRevisionHistoryScreen extends StatefulWidget {
  final String postId;

  const PostRevisionHistoryScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostRevisionHistoryScreen> createState() => _PostRevisionHistoryScreenState();
}

class _PostRevisionHistoryScreenState extends State<PostRevisionHistoryScreen> {
  List<PostRevision> _revisions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRevisions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: LottieLoadingWidget())
          : _buildRevisionsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'revision_history'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            '${_revisions.length} ${_revisions.length == 1 ? 'revision' : 'revisions'}',
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(153),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionsList() {
    if (_revisions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _revisions.length,
      itemBuilder: (context, index) {
        final revision = _revisions[index];
        final isLatest = index == 0;
        final isFirst = index == _revisions.length - 1;
        
        return _buildRevisionItem(
          revision,
          isLatest: isLatest,
          isFirst: isFirst,
        );
      },
    );
  }

  Widget _buildRevisionItem(
    PostRevision revision, {
    bool isLatest = false,
    bool isFirst = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: revision.getRevisionColor().withAlpha(26),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: revision.getRevisionColor(),
                    width: 2,
                  ),
                ),
                child: Icon(
                  revision.getRevisionIcon(),
                  size: 16,
                  color: revision.getRevisionColor(),
                ),
              ),
              if (!isLatest)
                Container(
                  width: 2,
                  height: 40,
                  color: AppTheme.textColor(context).withAlpha(51),
                ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Revision content
          Expanded(
            child: GestureDetector(
              onTap: () => _showRevisionDetails(revision),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLatest
                        ? revision.getRevisionColor().withAlpha(77)
                        : AppTheme.textColor(context).withAlpha(26),
                  ),
                  boxShadow: isLatest ? [
                    BoxShadow(
                      color: revision.getRevisionColor().withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revision header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            revision.getRevisionSummary(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                        ),
                        if (isLatest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: revision.getRevisionColor().withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tr(context, 'latest'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: revision.getRevisionColor(),
                              ),
                            ),
                          ),
                        if (isFirst)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tr(context, 'original'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // User and time
                    Row(
                      children: [
                        Text(
                          'by ${revision.userName}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(153),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          revision.getTimeAgo(),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textColor(context).withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                    
                    // Edit reason
                    if (revision.editReason != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.textFieldBackground(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.comment,
                              size: 14,
                              color: AppTheme.textColor(context).withAlpha(153),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                revision.editReason!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textColor(context).withAlpha(153),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Changed fields preview
                    if (revision.changedFields != null && revision.changedFields!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: revision.changedFields!.map((field) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: revision.getRevisionColor().withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              field,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: revision.getRevisionColor(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // Preview of changes
                    if (revision.type == RevisionType.contentEdit) ...[
                      const SizedBox(height: 8),
                      _buildContentChangePreview(revision),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentChangePreview(PostRevision revision) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (revision.previousContent != null) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tr(context, 'previous'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              revision.previousContent!.length > 100
                  ? '${revision.previousContent!.substring(0, 100)}...'
                  : revision.previousContent!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textColor(context).withAlpha(153),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          if (revision.newContent != null) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tr(context, 'new_text'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              revision.newContent!.length > 100
                  ? '${revision.newContent!.substring(0, 100)}...'
                  : revision.newContent!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'no_revisions'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'post_not_edited'),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  void _showRevisionDetails(PostRevision revision) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: revision.getRevisionColor().withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    revision.getRevisionIcon(),
                    color: revision.getRevisionColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        revision.getRevisionSummary(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      Text(
                        '${revision.userName} • ${revision.getTimeAgo()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor(context).withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (revision.editReason != null) ...[
              const SizedBox(height: 16),
              Text(
                tr(context, 'edit_reason'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                revision.editReason!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(tr(context, 'close')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRevisions() async {
    final failedLoadRevisions = tr(context, 'failed_load_revisions');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch actual revision data from Firebase
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('revisions')
          .orderBy('timestamp', descending: true)
          .get();

      final revisions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return PostRevision.fromMap(data, doc.id);
      }).toList();

      // If no revisions found, generate mock data for development
      _revisions = revisions.isEmpty ? _generateMockRevisions() : revisions;
    } catch (e) {
      _showErrorSnackBar(failedLoadRevisions.replaceAll('{error}', '$e'));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<PostRevision> _generateMockRevisions() {
    return [
      PostRevision(
        id: 'rev_3',
        postId: widget.postId,
        userId: 'user_1',
        userName: 'You',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: RevisionType.contentEdit,
        previousContent: 'Just completed my morning workout! Feeling energized.',
        newContent: 'Just completed my morning workout! 💪 Feeling energized and ready to tackle the day.',
        editReason: 'Added emoji and more details',
        changedFields: ['content'],
      ),
      PostRevision(
        id: 'rev_2',
        postId: widget.postId,
        userId: 'user_1',
        userName: 'You',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: RevisionType.pillarChange,
        previousData: {
          'pillars': ['PostPillar.fitness'],
        },
        newData: {
          'pillars': ['PostPillar.fitness', 'PostPillar.nutrition'],
        },
        editReason: 'Added nutrition category',
        changedFields: ['pillars'],
      ),
      PostRevision(
        id: 'rev_1',
        postId: widget.postId,
        userId: 'user_1',
        userName: 'You',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        type: RevisionType.creation,
        newContent: 'Just completed my morning workout! Feeling energized.',
        changedFields: ['content', 'pillars', 'visibility'],
      ),
    ];
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}