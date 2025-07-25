// lib/screens/social/edit_post_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/social_post.dart';
import '../../models/post_revision.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import 'post_revision_history_screen.dart';

class EditPostScreen extends StatefulWidget {
  final SocialPost post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _contentController = TextEditingController();
  final _editReasonController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  // Original values for comparison
  late String _originalContent;
  late List<PostPillar> _originalPillars;
  late PostVisibility _originalVisibility;
  late List<String> _originalMediaUrls;
  
  // Current editing values
  List<PostPillar> _selectedPillars = [];
  PostVisibility _selectedVisibility = PostVisibility.supporters;
  final List<File> _newImages = [];
  final List<String> _removedMediaUrls = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    _originalContent = widget.post.content;
    _originalPillars = List.from(widget.post.pillars);
    _originalVisibility = widget.post.visibility;
    _originalMediaUrls = List.from(widget.post.mediaUrls);
    
    _contentController.text = _originalContent;
    _selectedPillars = List.from(_originalPillars);
    _selectedVisibility = _originalVisibility;
    
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    setState(() {
      _hasChanges = _detectChanges();
    });
  }

  bool _detectChanges() {
    return _contentController.text.trim() != _originalContent ||
           !_listsEqual(_selectedPillars, _originalPillars) ||
           _selectedVisibility != _originalVisibility ||
           _newImages.isNotEmpty ||
           _removedMediaUrls.isNotEmpty;
  }

  bool _listsEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _editReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: LottieLoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditHeader(),
                  const SizedBox(height: 16),
                  _buildContentEditor(),
                  const SizedBox(height: 16),
                  _buildMediaEditor(),
                  const SizedBox(height: 16),
                  _buildPillarEditor(),
                  const SizedBox(height: 16),
                  _buildVisibilityEditor(),
                  const SizedBox(height: 16),
                  _buildEditReason(),
                  const SizedBox(height: 24),
                  _buildPreview(),
                  const SizedBox(height: 100), // Space for floating buttons
                ],
              ),
            ),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppTheme.textColor(context)),
        onPressed: () => _handleBackPress(),
      ),
      title: Text(
        'Edit Post',
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostRevisionHistoryScreen(postId: widget.post.id),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'History',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(26),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing Post',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
                Text(
                  'Changes will be tracked in revision history',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textColor(context).withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Modified',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textColor(context).withAlpha(51),
            ),
          ),
          child: TextField(
            controller: _contentController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'What\'s on your mind?',
              hintStyle: TextStyle(
                color: AppTheme.textColor(context).withAlpha(128),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Media',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const Spacer(),
            _buildMediaButton(
              icon: Icons.add_photo_alternate,
              label: 'Add Photos',
              onTap: _addImages,
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Existing media
        if (widget.post.mediaUrls.isNotEmpty) ...[
          _buildExistingMedia(),
          const SizedBox(height: 8),
        ],
        
        // New media
        if (_newImages.isNotEmpty) _buildNewMedia(),
      ],
    );
  }

  Widget _buildExistingMedia() {
    final visibleMedia = widget.post.mediaUrls
        .where((url) => !_removedMediaUrls.contains(url))
        .toList();

    if (visibleMedia.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.textColor(context).withAlpha(26),
          ),
        ),
        child: Text(
          'All existing media removed',
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(128),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: visibleMedia.length,
        itemBuilder: (context, index) {
          final mediaUrl = visibleMedia[index];
          return _buildExistingMediaItem(mediaUrl);
        },
      ),
    );
  }

  Widget _buildExistingMediaItem(String mediaUrl) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              mediaUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeExistingMedia(mediaUrl),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(204),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Media',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _newImages.length,
            itemBuilder: (context, index) {
              final image = _newImages[index];
              return _buildNewMediaItem(image, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewMediaItem(File image, int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeNewMedia(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(204),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withAlpha(77),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PostPillar.values.map((pillar) {
            final isSelected = _selectedPillars.contains(pillar);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedPillars.remove(pillar);
                  } else {
                    _selectedPillars.add(pillar);
                  }
                  _hasChanges = _detectChanges();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getPillarColor(pillar)
                      : AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _getPillarColor(pillar)
                        : AppTheme.textColor(context).withAlpha(51),
                  ),
                ),
                child: Text(
                  _getPillarDisplayName(pillar),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisibilityEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who can see this?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textColor(context).withAlpha(51),
            ),
          ),
          child: Row(
            children: PostVisibility.values.map((visibility) {
              final isSelected = _selectedVisibility == visibility;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVisibility = visibility;
                      _hasChanges = _detectChanges();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getVisibilityIcon(visibility),
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textColor(context).withAlpha(153),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getVisibilityDisplayName(visibility),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Reason (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textColor(context).withAlpha(51),
            ),
          ),
          child: TextField(
            controller: _editReasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Why are you editing this post? (e.g., "Fixed typo", "Added more details")',
              hintStyle: TextStyle(
                color: AppTheme.textColor(context).withAlpha(128),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textColor(context).withAlpha(51),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock user header
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.post.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'EDITED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Content
              Text(
                _contentController.text.trim().isEmpty 
                    ? 'No content'
                    : _contentController.text,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: _contentController.text.trim().isEmpty
                      ? AppTheme.textColor(context).withAlpha(128)
                      : AppTheme.textColor(context),
                  fontStyle: _contentController.text.trim().isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              
              // Pillar tags
              if (_selectedPillars.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: _selectedPillars.map((pillar) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPillarColor(pillar).withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPillarDisplayName(pillar),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getPillarColor(pillar),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_hasChanges)
          FloatingActionButton(
            heroTag: "save",
            onPressed: _saveChanges,
            backgroundColor: Colors.green,
            child: const Icon(Icons.save, color: Colors.white),
          ),
      ],
    );
  }

  // Event handlers
  Future<void> _addImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images.map((xfile) => File(xfile.path)));
          _hasChanges = _detectChanges();
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to pick images: $e');
    }
  }

  void _removeExistingMedia(String mediaUrl) {
    setState(() {
      _removedMediaUrls.add(mediaUrl);
      _hasChanges = _detectChanges();
    });
  }

  void _removeNewMedia(int index) {
    setState(() {
      _newImages.removeAt(index);
      _hasChanges = _detectChanges();
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual post update with Firebase
      // This would include:
      // 1. Upload new media files
      // 2. Update post document
      // 3. Create revision history entry
      // 4. Update post's editedAt timestamp

      await Future.delayed(const Duration(seconds: 2)); // Mock delay

      // Create revision entries for tracking changes
      await _createRevisionEntries();

      if (mounted) {
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      _showErrorMessage('Failed to save changes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createRevisionEntries() async {
    final editReason = _editReasonController.text.trim().isEmpty 
        ? null 
        : _editReasonController.text.trim();

    // Content change revision
    if (_contentController.text.trim() != _originalContent) {
      PostRevision.createContentEdit(
        postId: widget.post.id,
        userId: widget.post.userId,
        userName: widget.post.userName,
        previousContent: _originalContent,
        newContent: _contentController.text.trim(),
        editReason: editReason,
      );
      // TODO: Save revision to Firebase
    }

    // Pillar changes revision
    if (!_listsEqual(_selectedPillars, _originalPillars)) {
      PostRevision.createPillarEdit(
        postId: widget.post.id,
        userId: widget.post.userId,
        userName: widget.post.userName,
        previousPillars: _originalPillars,
        newPillars: _selectedPillars,
        editReason: editReason,
      );
      // TODO: Save revision to Firebase
    }

    // Visibility change revision
    if (_selectedVisibility != _originalVisibility) {
      PostRevision.createVisibilityEdit(
        postId: widget.post.id,
        userId: widget.post.userId,
        userName: widget.post.userName,
        previousVisibility: _originalVisibility,
        newVisibility: _selectedVisibility,
        editReason: editReason,
      );
      // TODO: Save revision to Firebase
    }

    // Media changes revision
    if (_newImages.isNotEmpty || _removedMediaUrls.isNotEmpty) {
      PostRevision.createMediaEdit(
        postId: widget.post.id,
        userId: widget.post.userId,
        userName: widget.post.userName,
        type: _newImages.isNotEmpty ? RevisionType.mediaAdd : RevisionType.mediaRemove,
        previousData: {
          'mediaUrls': _originalMediaUrls,
        },
        newData: {
          'addedMedia': _newImages.length,
          'removedMedia': _removedMediaUrls,
        },
        editReason: editReason,
      );
      // TODO: Save revision to Firebase
    }
  }

  void _handleBackPress() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Do you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close edit screen
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Helper methods
  Color _getPillarColor(PostPillar pillar) {
    switch (pillar) {
      case PostPillar.fitness:
        return const Color(0xFF2196F3);
      case PostPillar.nutrition:
        return const Color(0xFF4CAF50);
      case PostPillar.eco:
        return const Color(0xFF8BC34A);
    }
  }

  String _getPillarDisplayName(PostPillar pillar) {
    switch (pillar) {
      case PostPillar.fitness:
        return 'Fitness';
      case PostPillar.nutrition:
        return 'Nutrition';
      case PostPillar.eco:
        return 'Eco';
    }
  }

  String _getVisibilityDisplayName(PostVisibility visibility) {
    switch (visibility) {
      case PostVisibility.public:
        return 'Public';
      case PostVisibility.supporters:
        return 'Supporters';
      case PostVisibility.private:
        return 'Private';
    }
  }

  IconData _getVisibilityIcon(PostVisibility visibility) {
    switch (visibility) {
      case PostVisibility.public:
        return Icons.public;
      case PostVisibility.supporters:
        return Icons.people;
      case PostVisibility.private:
        return Icons.lock;
    }
  }
}