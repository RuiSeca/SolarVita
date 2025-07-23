// lib/screens/social/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../../models/social_post.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/lottie_loading_widget.dart';

class CreatePostScreen extends StatefulWidget {
  final PostType? initialPostType;
  final Map<String, dynamic>? sourceData;

  const CreatePostScreen({
    super.key,
    this.initialPostType,
    this.sourceData,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  PostType _selectedPostType = PostType.reflection;
  PostVisibility _selectedVisibility = PostVisibility.supporters;
  List<PostPillar> _selectedPillars = [];
  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = [];
  final List<VideoPlayerController> _videoControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPostType != null) {
      _selectedPostType = widget.initialPostType!;
    }
    _initializePillarsFromPostType();
  }

  @override
  void dispose() {
    _contentController.dispose();
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializePillarsFromPostType() {
    switch (_selectedPostType) {
      case PostType.fitnessProgress:
        _selectedPillars = [PostPillar.fitness];
        break;
      case PostType.nutritionUpdate:
        _selectedPillars = [PostPillar.nutrition];
        break;
      case PostType.ecoAchievement:
        _selectedPillars = [PostPillar.eco];
        break;
      default:
        _selectedPillars = [];
    }
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
                  _buildPostTypeSelector(),
                  const SizedBox(height: 16),
                  _buildContentInput(),
                  const SizedBox(height: 16),
                  _buildMediaSection(),
                  const SizedBox(height: 16),
                  _buildPillarSelector(),
                  const SizedBox(height: 16),
                  _buildVisibilitySelector(),
                  const SizedBox(height: 24),
                  _buildPostPreview(),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppTheme.textColor(context)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Create Post',
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _canPost() ? _createPost : null,
          child: Text(
            'Share',
            style: TextStyle(
              color: _canPost()
                  ? Theme.of(context).primaryColor
                  : AppTheme.textColor(context).withAlpha(128),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Type',
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
          children: PostType.values.map((type) {
            final isSelected = _selectedPostType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPostType = type;
                  _initializePillarsFromPostType();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : AppTheme.textColor(context).withAlpha(51),
                  ),
                ),
                child: Text(
                  _getPostTypeDisplayName(type),
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

  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s on your mind?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
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
              hintText: _getPostTypeHint(_selectedPostType),
              hintStyle: TextStyle(
                color: AppTheme.textColor(context).withAlpha(128),
              ),
              border: InputBorder.none,
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

  Widget _buildMediaSection() {
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
              icon: Icons.photo_library,
              label: 'Photos',
              onTap: _pickImages,
            ),
            const SizedBox(width: 8),
            _buildMediaButton(
              icon: Icons.videocam,
              label: 'Videos',
              onTap: _pickVideos,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty)
          _buildMediaPreview(),
      ],
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
          color: Theme.of(context).primaryColor.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withAlpha(102),
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

  Widget _buildMediaPreview() {
    final allMedia = [
      ..._selectedImages.map((file) => MediaPreviewItem(file: file, isVideo: false)),
      ..._selectedVideos.map((file) => MediaPreviewItem(file: file, isVideo: true)),
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allMedia.length,
        itemBuilder: (context, index) {
          final media = allMedia[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: media.isVideo
                      ? _buildVideoThumbnail(media.file)
                      : Image.file(
                          media.file,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeMedia(media.file, media.isVideo),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoThumbnail(File videoFile) {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[300],
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 40, color: Colors.grey),
          Positioned(
            bottom: 4,
            right: 4,
            child: Icon(Icons.videocam, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarSelector() {
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

  Widget _buildVisibilitySelector() {
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

  Widget _buildPostPreview() {
    if (_contentController.text.isEmpty && 
        _selectedImages.isEmpty && 
        _selectedVideos.isEmpty) {
      return const SizedBox.shrink();
    }

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
                    'You',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _getVisibilityIcon(_selectedVisibility),
                    size: 12,
                    color: AppTheme.textColor(context).withAlpha(128),
                  ),
                ],
              ),
              if (_contentController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _contentController.text,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
              if (_selectedPillars.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: _selectedPillars.map((pillar) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPillarColor(pillar).withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getPillarDisplayName(pillar),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPillarColor(pillar),
                          fontWeight: FontWeight.w600,
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

  // Helper methods
  bool _canPost() {
    return _contentController.text.trim().isNotEmpty ||
           _selectedImages.isNotEmpty ||
           _selectedVideos.isNotEmpty;
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }

  Future<void> _pickVideos() async {
    final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideos.add(File(video.path));
      });
    }
  }

  void _removeMedia(File file, bool isVideo) {
    setState(() {
      if (isVideo) {
        _selectedVideos.remove(file);
      } else {
        _selectedImages.remove(file);
      }
    });
  }

  Future<void> _createPost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual post creation with Firebase
      // This would include:
      // 1. Upload media files to Firebase Storage
      // 2. Create post document in Firestore
      // 3. Update user's feed and supporters' feeds

      await Future.delayed(const Duration(seconds: 2)); // Mock delay

      if (mounted) {
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Display name helpers
  String _getPostTypeDisplayName(PostType type) {
    switch (type) {
      case PostType.fitnessProgress:
        return 'Fitness Progress';
      case PostType.nutritionUpdate:
        return 'Nutrition Update';
      case PostType.ecoAchievement:
        return 'Eco Achievement';
      case PostType.reflection:
        return 'Reflection';
      case PostType.milestone:
        return 'Milestone';
      case PostType.weeklyWins:
        return 'Weekly Wins';
    }
  }

  String _getPostTypeHint(PostType type) {
    switch (type) {
      case PostType.fitnessProgress:
        return 'Share your workout achievements, progress photos, or fitness goals...';
      case PostType.nutritionUpdate:
        return 'Share a healthy meal, nutrition tips, or eating habits...';
      case PostType.ecoAchievement:
        return 'Share your sustainable choices, eco-friendly habits, or environmental impact...';
      case PostType.reflection:
        return 'Share your thoughts, gratitude, or wellness reflections...';
      case PostType.milestone:
        return 'Celebrate a major achievement or goal reached...';
      case PostType.weeklyWins:
        return 'What was your biggest win this week?';
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

class MediaPreviewItem {
  final File file;
  final bool isVideo;

  MediaPreviewItem({required this.file, required this.isVideo});
}