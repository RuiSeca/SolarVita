import 'package:flutter/material.dart';
import '../../models/templates/workout_template.dart';
import '../../services/templates/workout_template_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import 'template_detail_screen.dart';

class WorkoutTemplatesScreen extends StatefulWidget {
  final String? initialCategory;
  
  const WorkoutTemplatesScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<WorkoutTemplatesScreen> createState() => _WorkoutTemplatesScreenState();
}

class _WorkoutTemplatesScreenState extends State<WorkoutTemplatesScreen>
    with SingleTickerProviderStateMixin {
  final WorkoutTemplateService _templateService = WorkoutTemplateService();
  late TabController _tabController;
  
  List<WorkoutTemplate> _allTemplates = [];
  List<WorkoutTemplate> _filteredTemplates = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';

  final Map<String, String> _categoryNames = {
    'all': 'All',
    'strength': 'Strength',
    'cardio': 'Cardio',
    'full_body': 'Full Body',
    'flexibility': 'Flexibility',
  };

  final Map<String, String> _difficultyNames = {
    'all': 'All Levels',
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Set initial category if provided
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    
    try {
      final templates = await _templateService.getAllTemplates();
      setState(() {
        _allTemplates = templates;
        _filteredTemplates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTemplates = _allTemplates.where((template) {
        final categoryMatch = _selectedCategory == 'all' || template.category == _selectedCategory;
        final difficultyMatch = _selectedDifficulty == 'all' || template.difficulty == _selectedDifficulty;
        return categoryMatch && difficultyMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(tr(context, 'workout_templates')),
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor(context),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr(context, 'browse_templates')),
            Tab(text: tr(context, 'my_templates')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildMyTemplatesTab(),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    if (_isLoading) {
      return const Center(child: LottieLoadingWidget());
    }

    return Column(
      children: [
        // Filter section
        _buildFilterSection(),
        
        // Templates grid
        Expanded(
          child: _filteredTemplates.isEmpty
              ? _buildEmptyState()
              : _buildTemplatesGrid(),
        ),
      ],
    );
  }

  Widget _buildMyTemplatesTab() {
    return FutureBuilder<List<WorkoutTemplate>>(
      future: _templateService.getCustomTemplates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LottieLoadingWidget());
        }

        final customTemplates = snapshot.data ?? [];
        
        if (customTemplates.isEmpty) {
          return _buildEmptyCustomTemplatesState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customTemplates.length,
          itemBuilder: (context, index) {
            return _buildCustomTemplateCard(customTemplates[index]);
          },
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Category filter
          Row(
            children: [
              Text(
                tr(context, 'category'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categoryNames.entries.map((entry) {
                      final isSelected = _selectedCategory == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = entry.key;
                            });
                            _applyFilters();
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Difficulty filter
          Row(
            children: [
              Text(
                tr(context, 'difficulty'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _difficultyNames.entries.map((entry) {
                      final isSelected = _selectedDifficulty == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedDifficulty = entry.key;
                            });
                            _applyFilters();
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 3.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        return _buildTemplateCard(_filteredTemplates[index]);
      },
    );
  }

  Widget _buildTemplateCard(WorkoutTemplate template) {
    return GestureDetector(
      onTap: () => _navigateToTemplateDetail(template),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textColor(context).withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Template image/icon
            Container(
              width: 80,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _getCategoryColor(template.category).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Icon(
                _getCategoryIcon(template.category),
                color: _getCategoryColor(template.category),
                size: 32,
              ),
            ),
            
            // Template info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildDifficultyBadge(template.difficulty),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      template.description,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppTheme.textColor(context).withValues(alpha: 0.6),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.estimatedDuration} min',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.fitness_center,
                          color: AppTheme.textColor(context).withValues(alpha: 0.6),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.exercises.length} exercises',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        if (template.isPremium) ...[
                          const Spacer(),
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTemplateCard(WorkoutTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Icon(
            Icons.fitness_center,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          template.name,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${template.exercises.length} exercises • ${template.estimatedDuration} min',
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.textColor(context).withValues(alpha: 0.4),
          size: 16,
        ),
        onTap: () => _navigateToTemplateDetail(template),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty) {
      case 'beginner':
        color = Colors.green;
        break;
      case 'intermediate':
        color = Colors.orange;
        break;
      case 'advanced':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textColor(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'no_templates_found'),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'try_different_filters'),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCustomTemplatesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 64,
            color: AppTheme.textColor(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'no_custom_templates'),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'create_your_first_template'),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'strength':
        return Colors.red;
      case 'cardio':
        return Colors.blue;
      case 'full_body':
        return Colors.purple;
      case 'flexibility':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'full_body':
        return Icons.accessibility_new;
      case 'flexibility':
        return Icons.spa;
      default:
        return Icons.sports_gymnastics;
    }
  }

  void _navigateToTemplateDetail(WorkoutTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateDetailScreen(template: template),
      ),
    );
  }


}