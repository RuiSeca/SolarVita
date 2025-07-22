import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tribe.dart';
import '../../services/tribe_service.dart';
import '../../theme/app_theme.dart';

class CreateTribeScreen extends ConsumerStatefulWidget {
  const CreateTribeScreen({super.key});

  @override
  ConsumerState<CreateTribeScreen> createState() => _CreateTribeScreenState();
}

class _CreateTribeScreenState extends ConsumerState<CreateTribeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  
  final TribeService _tribeService = TribeService();
  
  TribeCategory _selectedCategory = TribeCategory.fitness;
  TribeVisibility _visibility = TribeVisibility.public;
  bool _isLoading = false;
  final List<String> _tags = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _locationController.dispose();
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

  Future<void> _createTribe() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final tribeId = await _tribeService.createTribe(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        customCategory: _selectedCategory == TribeCategory.custom 
            ? _customCategoryController.text.trim() 
            : null,
        visibility: _visibility,
        tags: _tags,
        location: _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tribe created successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(tribeId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating tribe: $e'),
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
        title: const Text('Create Tribe'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createTribe,
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
                    'Create',
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
              // Basic Information Section
              _buildSectionHeader('Basic Information', '🏛️'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tribe Name *',
                  hintText: 'Enter your tribe name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tribe name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Tribe name must be at least 3 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Tribe name must be less than 50 characters';
                  }
                  return null;
                },
                maxLength: 50,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe what your tribe is about',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  if (value.trim().length > 500) {
                    return 'Description must be less than 500 characters';
                  }
                  return null;
                },
                maxLength: 500,
              ),

              const SizedBox(height: 24),

              // Category Section
              _buildSectionHeader('Category', '📂'),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.textFieldBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a category that best describes your tribe:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TribeCategory.values.map((category) {
                        final isSelected = _selectedCategory == category;
                        return FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category == TribeCategory.custom ? '⭐' : Tribe(
                                  id: '', 
                                  name: '', 
                                  description: '', 
                                  creatorId: '', 
                                  creatorName: '',
                                  category: category,
                                  createdAt: DateTime.now(),
                                ).getCategoryIcon(),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category == TribeCategory.custom 
                                    ? 'Custom' 
                                    : TribeService.getCategoryDisplayName(category),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            }
                          },
                          backgroundColor: AppTheme.textFieldBackground(context),
                          selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                          checkmarkColor: theme.primaryColor,
                        );
                      }).toList(),
                    ),
                    
                    if (_selectedCategory == TribeCategory.custom) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customCategoryController,
                        decoration: InputDecoration(
                          labelText: 'Custom Category Name *',
                          hintText: 'Enter your custom category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (_selectedCategory == TribeCategory.custom) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Custom category name is required';
                            }
                          }
                          return null;
                        },
                        maxLength: 30,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Privacy Settings Section
              _buildSectionHeader('Privacy Settings', '🔒'),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.textFieldBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    RadioListTile<TribeVisibility>(
                      title: const Row(
                        children: [
                          Text('🌍', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text('Public'),
                        ],
                      ),
                      subtitle: const Text(
                        'Anyone can discover and join your tribe',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: TribeVisibility.public,
                      groupValue: _visibility,
                      onChanged: (value) {
                        setState(() {
                          _visibility = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    const Divider(),
                    
                    RadioListTile<TribeVisibility>(
                      title: const Row(
                        children: [
                          Text('🔒', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text('Private'),
                        ],
                      ),
                      subtitle: const Text(
                        'Invitation only - members need an invite code to join',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: TribeVisibility.private,
                      groupValue: _visibility,
                      onChanged: (value) {
                        setState(() {
                          _visibility = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    if (_visibility == TribeVisibility.private) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, 
                                color: theme.primaryColor, 
                                size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'A unique invite code will be generated for your private tribe',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Optional Information Section
              _buildSectionHeader('Optional Information', '📋'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'City, Region, or "Online Only"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                maxLength: 100,
              ),

              const SizedBox(height: 16),

              // Tags Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tags',
                    style: theme.textTheme.labelLarge,
                  ),
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
                      children: _tags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(tag),
                        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                        side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.3)),
                      )).toList(),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTribe,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Create Tribe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}