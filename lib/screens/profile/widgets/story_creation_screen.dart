import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/social/story_highlight.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../providers/riverpod/story_provider.dart';

class StoryCreationScreen extends ConsumerStatefulWidget {
  final StoryHighlight? existingHighlight; // For adding to existing highlight

  const StoryCreationScreen({
    super.key,
    this.existingHighlight,
  });

  @override
  ConsumerState<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends ConsumerState<StoryCreationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  
  // Selected values
  StoryHighlightCategory? _selectedCategory;
  File? _selectedMedia;
  StoryContentType _contentType = StoryContentType.image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.existingHighlight != null) {
      // Adding to existing highlight
      _selectedCategory = widget.existingHighlight!.category;
      _titleController.text = widget.existingHighlight!.displayTitle;
      _tabController.index = 1; // Go directly to content tab
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _textController.dispose();
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
          widget.existingHighlight != null
              ? tr(context, 'add_story')
              : tr(context, 'create_highlight'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleCreate,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Text(
                    tr(context, 'create'),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
        bottom: widget.existingHighlight == null
            ? TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textColor(context).withValues(alpha: 0.6),
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  Tab(text: tr(context, 'highlight_info')),
                  Tab(text: tr(context, 'add_content')),
                ],
              )
            : null,
      ),
      body: widget.existingHighlight == null
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildHighlightInfoTab(),
                _buildContentTab(),
              ],
            )
          : _buildContentTab(),
    );
  }

  Widget _buildHighlightInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title input
          Text(
            tr(context, 'highlight_title'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: tr(context, 'enter_highlight_title'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category selection
          Text(
            tr(context, 'choose_category'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 12),

          // Available categories
          ref.watch(availableCategoriesProvider).when(
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(
              tr(context, 'failed_to_load_categories'),
              style: TextStyle(color: Colors.red),
            ),
            data: (categories) => _buildCategoryGrid(categories),
          ),

          const SizedBox(height: 24),

          // Custom category option
          ref.watch(canCreateCustomHighlightProvider).when(
            loading: () => SizedBox.shrink(),
            error: (error, stack) => SizedBox.shrink(),
            data: (canCreate) => canCreate ? _buildCustomCategoryOption() : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<StoryHighlightCategory> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategory == category;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category;
              _titleController.text = category.title;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: category.colorGradient.map((c) => Color(c)).toList(),
              ),
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(category.colorGradient.first).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  category.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomCategoryOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'or_create_custom'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = StoryHighlightCategory.custom;
              _titleController.clear();
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: StoryHighlightCategory.custom.colorGradient.map((c) => Color(c)).toList(),
              ),
              borderRadius: BorderRadius.circular(16),
              border: _selectedCategory == StoryHighlightCategory.custom
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Text(
                  tr(context, 'create_custom_category'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content type selector
          Text(
            tr(context, 'story_content_type'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              _buildContentTypeChip(StoryContentType.image, Icons.image, tr(context, 'photo')),
              const SizedBox(width: 12),
              _buildContentTypeChip(StoryContentType.video, Icons.videocam, tr(context, 'video')),
              const SizedBox(width: 12),
              _buildContentTypeChip(StoryContentType.textWithImage, Icons.text_fields, tr(context, 'text')),
            ],
          ),

          const SizedBox(height: 24),

          // Media picker
          if (_contentType != StoryContentType.textWithImage || _selectedMedia == null)
            _buildMediaPicker(),

          const SizedBox(height: 24),

          // Text input for text content
          if (_contentType == StoryContentType.textWithImage)
            _buildTextInput(),

          // Preview
          if (_selectedMedia != null || _textController.text.isNotEmpty)
            _buildPreview(),
        ],
      ),
    );
  }

  Widget _buildContentTypeChip(StoryContentType type, IconData icon, String label) {
    final isSelected = _contentType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _contentType = type;
          _selectedMedia = null; // Reset media when changing type
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textColor(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPicker() {
    return GestureDetector(
      onTap: _pickMedia,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: _selectedMedia != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _selectedMedia!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _contentType == StoryContentType.video 
                        ? Icons.videocam_outlined
                        : Icons.add_a_photo_outlined,
                    size: 48,
                    color: AppTheme.textColor(context).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _contentType == StoryContentType.video
                        ? tr(context, 'tap_to_add_video')
                        : tr(context, 'tap_to_add_photo'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'story_text'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: tr(context, 'enter_story_text'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'preview'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildPreviewContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContent() {
    switch (_contentType) {
      case StoryContentType.image:
        return _selectedMedia != null
            ? Image.file(_selectedMedia!, fit: BoxFit.cover)
            : _buildEmptyPreview();
      case StoryContentType.video:
        return _selectedMedia != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: Colors.grey[800]),
                  Icon(Icons.play_circle_filled, color: Colors.white, size: 64),
                ],
              )
            : _buildEmptyPreview();
      case StoryContentType.textWithImage:
        return Stack(
          children: [
            if (_selectedMedia != null)
              Positioned.fill(
                child: Image.file(_selectedMedia!, fit: BoxFit.cover),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            if (_textController.text.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _textController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
    }
  }

  Widget _buildEmptyPreview() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.preview,
              color: Colors.white.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              tr(context, 'story_preview'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(StoryHighlightCategory category) {
    switch (category) {
      case StoryHighlightCategory.workouts:
        return Icons.fitness_center;
      case StoryHighlightCategory.progress:
        return Icons.trending_up;
      case StoryHighlightCategory.challenges:
        return Icons.emoji_events;
      case StoryHighlightCategory.recovery:
        return Icons.spa;
      case StoryHighlightCategory.meals:
        return Icons.restaurant;
      case StoryHighlightCategory.cooking:
        return Icons.kitchen;
      case StoryHighlightCategory.hydration:
        return Icons.local_drink;
      case StoryHighlightCategory.ecoActions:
        return Icons.eco;
      case StoryHighlightCategory.nature:
        return Icons.nature;
      case StoryHighlightCategory.greenLiving:
        return Icons.park;
      case StoryHighlightCategory.dailyLife:
        return Icons.today;
      case StoryHighlightCategory.travel:
        return Icons.flight;
      case StoryHighlightCategory.community:
        return Icons.people;
      case StoryHighlightCategory.motivation:
        return Icons.psychology;
      case StoryHighlightCategory.custom:
        return Icons.star;
    }
  }

  Future<void> _pickMedia() async {
    try {
      XFile? file;
      if (_contentType == StoryContentType.video) {
        file = await _picker.pickVideo(source: ImageSource.gallery);
      } else {
        file = await _picker.pickImage(source: ImageSource.gallery);
      }

      if (file != null) {
        final filePath = file.path;
        setState(() {
          _selectedMedia = File(filePath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'failed_to_pick_media')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCreate() async {
    if (_validateInput()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _createStoryContent();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.existingHighlight != null
                    ? tr(context, 'story_added_successfully')
                    : tr(context, 'highlight_created_successfully'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'failed_to_create_story')),
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
  }

  bool _validateInput() {
    if (widget.existingHighlight == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'please_select_category'))),
        );
        return false;
      }
      
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'please_enter_title'))),
        );
        return false;
      }
    }

    if (_contentType != StoryContentType.textWithImage && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'please_add_media'))),
      );
      return false;
    }

    if (_contentType == StoryContentType.textWithImage && 
        _selectedMedia == null && 
        _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'please_add_content'))),
      );
      return false;
    }

    return true;
  }

  Future<void> _createStoryContent() async {
    final storyActions = ref.read(storyActionsProvider);
    
    // Upload media if present
    String? mediaUrl;
    if (_selectedMedia != null) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      mediaUrl = await storyActions.uploadStoryMedia(_selectedMedia!, fileName);
    }

    // Create story content
    final contentId = await storyActions.createStoryContent(
      contentType: _contentType,
      mediaUrl: mediaUrl,
      text: _textController.text.trim().isNotEmpty ? _textController.text.trim() : null,
    );

    // Create highlight or add to existing
    if (widget.existingHighlight != null) {
      // Add story to existing highlight
      await storyActions.addStoryToHighlight(widget.existingHighlight!.id, contentId);
    } else {
      // Create new highlight and add the story content to it
      final highlightId = await storyActions.createStoryHighlight(
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        coverImageUrl: mediaUrl ?? '',
        customTitle: _selectedCategory == StoryHighlightCategory.custom 
            ? _titleController.text.trim() 
            : null,
      );
      
      // Add the story content to the newly created highlight
      await storyActions.addStoryToHighlight(highlightId, contentId);
    }
  }
}