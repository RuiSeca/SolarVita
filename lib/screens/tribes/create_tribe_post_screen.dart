import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tribe/tribe.dart';
import '../../models/tribe/tribe_post.dart';
import '../../services/database/tribe_service.dart';
import '../../theme/app_theme.dart';

class CreateTribePostScreen extends ConsumerStatefulWidget {
  final Tribe tribe;

  const CreateTribePostScreen({super.key, required this.tribe});

  @override
  ConsumerState<CreateTribePostScreen> createState() =>
      _CreateTribePostScreenState();
}

class _CreateTribePostScreenState extends ConsumerState<CreateTribePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  final TribeService _tribeService = TribeService();

  TribePostType _postType = TribePostType.text;
  bool _isAnnouncement = false;
  bool _isLoading = false;
  final List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag.toLowerCase())) {
      setState(() {
        _tags.add(tag.toLowerCase());
      });
      _tagsController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _tribeService.createTribePost(
        tribeId: widget.tribe.id,
        content: _contentController.text.trim(),
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null,
        type: _postType,
        isAnnouncement: _isAnnouncement,
        tags: _tags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Post in ${widget.tribe.name}'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tribe Info Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textFieldBackground(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.tribe.getCategoryIcon(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Posting in ${widget.tribe.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Post Type Selection
              Text('Post Type', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textFieldBackground(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TribePostType.values.map((type) {
                    final isSelected = _postType == type;
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            TribePost(
                              id: '',
                              tribeId: '',
                              authorId: '',
                              authorName: '',
                              content: '',
                              type: type,
                              createdAt: DateTime.now(),
                            ).getPostTypeIcon(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TribePost(
                              id: '',
                              tribeId: '',
                              authorId: '',
                              authorName: '',
                              content: '',
                              type: type,
                              createdAt: DateTime.now(),
                            ).getPostTypeText(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _postType = type;
                          });
                        }
                      },
                      backgroundColor: AppTheme.textFieldBackground(context),
                      selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: theme.primaryColor,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Title (optional)
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'Add a catchy title for your post',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLength: 100,
              ),

              const SizedBox(height: 16),

              // Content
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'What\'s on your mind? *',
                  hintText: 'Share your thoughts, experiences, or questions...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write something to post';
                  }
                  if (value.trim().length < 10) {
                    return 'Post content must be at least 10 characters';
                  }
                  if (value.trim().length > 2000) {
                    return 'Post content must be less than 2000 characters';
                  }
                  return null;
                },
                maxLength: 2000,
              ),

              const SizedBox(height: 24),

              // Tags Section
              Text('Tags', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),

              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Add tags',
                  hintText: 'Type and press Enter to add tags',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.tag),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(_tagsController.text.trim()),
                  ),
                ),
                onFieldSubmitted: (value) => _addTag(value.trim()),
              ),

              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tags
                      .map(
                        (tag) => Chip(
                          label: Text(
                            '#$tag',
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeTag(tag),
                          backgroundColor: theme.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          side: BorderSide(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Announcement Toggle (for admins/creators only)
              // Note: In a real implementation, you'd check if user is admin
              CheckboxListTile(
                title: const Text('📢 Make this an announcement'),
                subtitle: const Text('Announcements are pinned at the top'),
                value: _isAnnouncement,
                onChanged: (value) {
                  setState(() {
                    _isAnnouncement = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // Post Guidelines
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: theme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Community Guidelines',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Be respectful and supportive to all members\n'
                      '• Share relevant content related to ${widget.tribe.getCategoryName()}\n'
                      '• No spam or promotional content\n'
                      '• Use tags to help others find your posts',
                      style: TextStyle(
                        color: theme.primaryColor.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Post Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _postType == TribePostType.text
                                  ? '💬'
                                  : _postType == TribePostType.question
                                  ? '❓'
                                  : _postType == TribePostType.achievement
                                  ? '🏆'
                                  : _postType == TribePostType.announcement
                                  ? '📢'
                                  : _postType == TribePostType.event
                                  ? '📅'
                                  : '📸',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Share with Tribe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
