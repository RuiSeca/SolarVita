// lib/screens/social/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../../models/social_post.dart';
import '../../models/user_mention.dart';
import '../../models/post_template.dart';
import '../../models/content_moderation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../widgets/media/video_thumbnail_widget.dart';
import '../../widgets/social/mention_text_field.dart';
import '../../widgets/social/post_template_selector.dart';
import 'template_variable_input_screen.dart';

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
  List<MentionInfo> _mentions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPostType != null) {
      _selectedPostType = widget.initialPostType!;
    }
    _initializePillarsFromPostType();
    _handleSourceData();
  }

  void _handleSourceData() {
    if (widget.sourceData != null) {
      final data = widget.sourceData!;
      
      // Pre-fill content from template
      if (data['pre_filled_content'] != null) {
        _contentController.text = data['pre_filled_content'];
      }
      
      // Set default pillars from template
      if (data['default_pillars'] != null) {
        final pillarStrings = List<String>.from(data['default_pillars']);
        _selectedPillars = pillarStrings.map((pillarStr) {
          return PostPillar.values.firstWhere(
            (p) => p.toString() == pillarStr,
            orElse: () => PostPillar.fitness,
          );
        }).toList();
      }
    }
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
        Row(
          children: [
            Text(
              'What\'s on your mind?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showTemplateSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withAlpha(102),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.article,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Templates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MentionTextField(
          controller: _contentController,
          hintText: _getPostTypeHint(_selectedPostType),
          maxLines: 6,
          onMentionsChanged: (mentions) {
            setState(() {
              _mentions = mentions;
            });
          },
          textStyle: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
          ),
        ),
        // Show mentions count if any
        if (_mentions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_mentions.length} ${_mentions.length == 1 ? 'person' : 'people'} mentioned',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
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
              onTap: _canAddMoreMedia() ? _pickImages : null,
              isDisabled: !_canAddMoreMedia(),
            ),
            const SizedBox(width: 8),
            _buildMediaButton(
              icon: Icons.videocam,
              label: 'Videos',
              onTap: _canAddMoreMedia() ? _pickVideos : null,
              isDisabled: !_canAddMoreMedia(),
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
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled 
              ? AppTheme.textColor(context).withAlpha(26)
              : Theme.of(context).primaryColor.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDisabled
                ? AppTheme.textColor(context).withAlpha(51)
                : Theme.of(context).primaryColor.withAlpha(102),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isDisabled
                  ? AppTheme.textColor(context).withAlpha(128)
                  : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isDisabled
                    ? AppTheme.textColor(context).withAlpha(128)
                    : Theme.of(context).primaryColor,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media count and reorder info
        Row(
          children: [
            Text(
              '${allMedia.length} ${allMedia.length == 1 ? 'file' : 'files'} selected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context).withAlpha(153),
              ),
            ),
            const Spacer(),
            if (allMedia.length > 1)
              Text(
                'Tap and hold to reorder',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textColor(context).withAlpha(128),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Enhanced media grid with reordering
        SizedBox(
          height: allMedia.length > 3 ? 260 : 130, // Adjust height for multiple rows
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allMedia.length,
            onReorder: _reorderMedia,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.1,
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final media = allMedia[index];
              return _buildEnhancedMediaItem(media, index, key: ValueKey(media.file.path));
            },
          ),
        ),
        
        // Media limit indicator
        if (allMedia.length >= 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  'Maximum 10 files per post',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedMediaItem(MediaPreviewItem media, int index, {required Key key}) {
    return Container(
      key: key,
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // Main media content
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.textColor(context).withAlpha(26),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: media.isVideo
                  ? VideoThumbnailWidget(
                      videoFile: media.file,
                      width: 120,
                      height: 120,
                      showDuration: true,
                      showPlayButton: true,
                      onTap: () => _previewVideo(media.file),
                    )
                  : Image.file(
                      media.file,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          
          // Media type indicator
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    media.isVideo ? Icons.videocam : Icons.image,
                    size: 10,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    media.isVideo ? 'VIDEO' : 'PHOTO',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Order indicator
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Remove button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removeMedia(media.file, media.isVideo),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(204),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
          
          // Drag handle for reordering
          if (index < _getMediaCount() - 1 || _getMediaCount() > 1)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.drag_indicator,
                  size: 12,
                  color: Colors.white,
                ),
              ),
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

  bool _canAddMoreMedia() {
    final totalMedia = _selectedImages.length + _selectedVideos.length;
    return totalMedia < 10;
  }

  int _getMediaCount() {
    return _selectedImages.length + _selectedVideos.length;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        // Check media limit
        final totalMedia = _selectedImages.length + _selectedVideos.length;
        final availableSlots = 10 - totalMedia;
        
        if (availableSlots <= 0) {
          _showErrorMessage('Maximum 10 files allowed per post');
          return;
        }
        
        final imagesToAdd = images.take(availableSlots).toList();
        
        setState(() {
          _selectedImages.addAll(imagesToAdd.map((xfile) => File(xfile.path)));
        });
        
        // Show warning if some images were not added
        if (images.length > imagesToAdd.length) {
          _showWarningMessage('Only ${imagesToAdd.length} images added due to limit');
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to pick images: $e');
    }
  }

  Future<void> _pickVideos() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // Limit video length
      );
      if (video != null) {
        // Check media limit
        final totalMedia = _selectedImages.length + _selectedVideos.length;
        
        if (totalMedia >= 10) {
          _showErrorMessage('Maximum 10 files allowed per post');
          return;
        }
        
        // Check video file size (limit to 100MB)
        final file = File(video.path);
        final fileSize = await file.length();
        const maxSize = 100 * 1024 * 1024; // 100MB in bytes
        
        if (fileSize > maxSize) {
          _showErrorMessage('Video file too large. Maximum size is 100MB.');
          return;
        }
        
        setState(() {
          _selectedVideos.add(file);
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to pick video: $e');
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

  void _reorderMedia(int oldIndex, int newIndex) {
    setState(() {
      // Create combined media list for reordering
      final allMedia = [
        ..._selectedImages.map((file) => MediaPreviewItem(file: file, isVideo: false)),
        ..._selectedVideos.map((file) => MediaPreviewItem(file: file, isVideo: true)),
      ];

      // Perform reordering
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = allMedia.removeAt(oldIndex);
      allMedia.insert(newIndex, item);

      // Separate back to images and videos lists
      _selectedImages.clear();
      _selectedVideos.clear();
      
      for (final media in allMedia) {
        if (media.isVideo) {
          _selectedVideos.add(media.file);
        } else {
          _selectedImages.add(media.file);
        }
      }
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarningMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostTemplateSelectorSheet(
        onTemplateSelected: (template) {
          Navigator.pop(context); // Close the template selector
          
          if (template.hasVariables) {
            // Navigate to variable input screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TemplateVariableInputScreen(template: template),
              ),
            );
          } else {
            // Use template directly
            _useTemplate(template);
          }
        },
      ),
    );
  }

  void _useTemplate(PostTemplate template) {
    setState(() {
      _contentController.text = template.promptText;
      _selectedPostType = template.postType;
      _selectedPillars = template.defaultPillars;
      _initializePillarsFromPostType();
    });
  }

  void _previewVideo(File videoFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Stack(
            children: [
              VideoThumbnailWidget(
                videoFile: videoFile,
                width: double.infinity,
                height: double.infinity,
                showDuration: true,
                showPlayButton: true,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Video Preview\nTap to close',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Content moderation check
      final content = _contentController.text.trim();
      final moderationResult = ContentModerationService.analyzeContent(content);
      
      if (moderationResult.flagged) {
        _showModerationWarning(moderationResult);
        return;
      }

      // TODO: Implement actual post creation with Firebase
      // This would include:
      // 1. Upload media files to Firebase Storage
      // 2. Create post document in Firestore with mentions
      // 3. Create mention notifications for mentioned users
      // 4. Update user's feed and supporters' feeds
      // 5. Store moderation result for review if flagged

      // Prepare mention data for storage
      // TODO: Store mention data when implementing Firebase integration
      
      // Show success message with mention count
      String successMessage = 'Post created successfully!';
      if (_mentions.isNotEmpty) {
        successMessage += ' ${_mentions.length} ${_mentions.length == 1 ? 'person' : 'people'} will be notified.';
      }

      // Add moderation notice if content requires review
      if (moderationResult.requiresHumanReview) {
        successMessage += ' Your post is being reviewed and will be visible once approved.';
      }

      await Future.delayed(const Duration(seconds: 2)); // Mock delay

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: moderationResult.requiresHumanReview ? Colors.orange : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showModerationWarning(AutoModerationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              'Content Review',
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your post contains content that may violate our community guidelines.',
              style: TextStyle(
                color: AppTheme.textColor(context),
              ),
            ),
            if (result.explanation != null) ...[
              const SizedBox(height: 8),
              Text(
                result.explanation!,
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(153),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Please review and edit your content to ensure it follows our community guidelines.',
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Edit Post',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Continue with post creation despite warning
              _createPostAnyway();
            },
            child: Text(
              'Submit Anyway',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPostAnyway() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create post but mark for review
      // TODO: Store content and mentions when implementing Firebase integration
      
      await Future.delayed(const Duration(seconds: 2)); // Mock delay

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post submitted for review. It will be visible once approved by our moderation team.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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