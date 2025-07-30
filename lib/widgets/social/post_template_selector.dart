// lib/widgets/social/post_template_selector.dart
import 'package:flutter/material.dart';
import '../../models/post_template.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class PostTemplateSelectorSheet extends StatefulWidget {
  final Function(PostTemplate) onTemplateSelected;
  final TemplateCategory? filterCategory;

  const PostTemplateSelectorSheet({
    super.key,
    required this.onTemplateSelected,
    this.filterCategory,
  });

  @override
  State<PostTemplateSelectorSheet> createState() => _PostTemplateSelectorSheetState();
}

class _PostTemplateSelectorSheetState extends State<PostTemplateSelectorSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<PostTemplate> _templates = [];
  TemplateCategory _selectedCategory = TemplateCategory.weeklyWins;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _selectedCategory = widget.filterCategory ?? TemplateCategory.weeklyWins;
    _tabController = TabController(
      length: TemplateCategory.values.length,
      vsync: this,
      initialIndex: _selectedCategory.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTemplates() {
    _templates = WeeklyWinsTemplate.getAllTemplates();
  }

  List<PostTemplate> _getTemplatesForCategory(TemplateCategory category) {
    return _templates.where((template) => template.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textColor(context).withAlpha(102),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  tr(context, 'choose_template'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
          ),

          // Category tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: AppTheme.textColor(context).withAlpha(153),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: TemplateCategory.values.map((category) {
                return Tab(
                  text: _getCategoryDisplayName(category),
                  icon: Icon(
                    _getCategoryIcon(category),
                    size: 20,
                  ),
                );
              }).toList(),
            ),
          ),

          // Template list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: TemplateCategory.values.map((category) {
                final categoryTemplates = _getTemplatesForCategory(category);
                return _buildTemplateList(categoryTemplates);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(List<PostTemplate> templates) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppTheme.textColor(context).withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'no_templates'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context).withAlpha(153),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'check_back_templates'),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor(context).withAlpha(128),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(PostTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withAlpha(26),
        ),
      ),
      child: InkWell(
        onTap: () => widget.onTemplateSelected(template),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: template.color.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      template.icon,
                      color: template.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textColor(context).withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textColor(context).withAlpha(128),
                  ),
                ],
              ),

              // Template preview
              if (template.hasVariables) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.textColor(context).withAlpha(13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'preview_label'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor(context).withAlpha(153),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTemplatePreview(template),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              // Suggested content (if any)
              if (template.suggestedContent.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  tr(context, 'ideas_label'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context).withAlpha(153),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: template.suggestedContent.take(3).map((idea) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: template.color.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        idea,
                        style: TextStyle(
                          fontSize: 11,
                          color: template.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTemplatePreview(PostTemplate template) {
    // Show a preview with placeholder text
    const placeholderMap = {
      'achievement': '[your achievement]',
      'feeling': '[how you feel]',
      'workout_type': '[workout type]',
      'recipe_name': '[recipe name]',
      'timeframe': '[time period]',
      'exercise': '[exercise name]',
      'habit': '[your habit]',
      'streak_days': '[X]',
    };

    String preview = template.promptText;
    for (final placeholder in template.placeholders) {
      final replacement = placeholderMap[placeholder] ?? '[$placeholder]';
      preview = preview.replaceAll('{$placeholder}', replacement);
    }

    return preview;
  }

  String _getCategoryDisplayName(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.weeklyWins:
        return tr(context, 'weekly_wins');
      case TemplateCategory.fitnessAchievement:
        return tr(context, 'fitness');
      case TemplateCategory.nutritionGoal:
        return tr(context, 'nutrition');
      case TemplateCategory.ecoChallenge:
        return tr(context, 'eco');
      case TemplateCategory.mindfulness:
        return tr(context, 'mindfulness');
      case TemplateCategory.milestone:
        return tr(context, 'milestones');
      case TemplateCategory.gratitude:
        return tr(context, 'gratitude');
    }
  }

  IconData _getCategoryIcon(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.weeklyWins:
        return Icons.emoji_events;
      case TemplateCategory.fitnessAchievement:
        return Icons.fitness_center;
      case TemplateCategory.nutritionGoal:
        return Icons.restaurant;
      case TemplateCategory.ecoChallenge:
        return Icons.eco;
      case TemplateCategory.mindfulness:
        return Icons.self_improvement;
      case TemplateCategory.milestone:
        return Icons.flag;
      case TemplateCategory.gratitude:
        return Icons.favorite;
    }
  }

}