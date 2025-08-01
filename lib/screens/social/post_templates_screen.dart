// lib/screens/social/post_templates_screen.dart
import 'package:flutter/material.dart';
import '../../models/posts/post_template.dart';
import '../../models/social/social_post.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../utils/template_localization.dart';
import 'template_post_creator_screen.dart';

class PostTemplatesScreen extends StatefulWidget {
  const PostTemplatesScreen({super.key});

  @override
  State<PostTemplatesScreen> createState() => _PostTemplatesScreenState();
}

class _PostTemplatesScreenState extends State<PostTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyWinsTab(),
                _buildAchievementsTab(),
                _buildGratitudeTab(),
                _buildAllTemplatesTab(),
              ],
            ),
          ),
        ],
      ),
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
      title: Text(
        tr(context, 'post_templates'),
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'get_inspired'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    Text(
                      tr(context, 'templates_description'),
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
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textColor(context),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(text: tr(context, 'weekly_wins')),
          Tab(text: tr(context, 'achievements')),
          Tab(text: tr(context, 'gratitude')),
          Tab(text: tr(context, 'all')),
        ],
      ),
    );
  }

  Widget _buildWeeklyWinsTab() {
    final templates = WeeklyWinsTemplate.getWeeklyWinsTemplates();
    final localizedTemplates = TemplateLocalization.getLocalizedTemplates(
      context,
      templates,
    );
    return _buildTemplateGrid(localizedTemplates);
  }

  Widget _buildAchievementsTab() {
    final templates = WeeklyWinsTemplate.getAchievementTemplates();
    final localizedTemplates = TemplateLocalization.getLocalizedTemplates(
      context,
      templates,
    );
    return _buildTemplateGrid(localizedTemplates);
  }

  Widget _buildGratitudeTab() {
    final templates = WeeklyWinsTemplate.getGratitudeTemplates();
    final localizedTemplates = TemplateLocalization.getLocalizedTemplates(
      context,
      templates,
    );
    return _buildTemplateGrid(localizedTemplates);
  }

  Widget _buildAllTemplatesTab() {
    final templates = WeeklyWinsTemplate.getAllTemplates();
    final localizedTemplates = TemplateLocalization.getLocalizedTemplates(
      context,
      templates,
    );
    return _buildTemplateGrid(localizedTemplates);
  }

  Widget _buildTemplateGrid(List<PostTemplate> templates) {
    if (templates.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTemplateCard(template),
        );
      },
    );
  }

  Widget _buildTemplateCard(PostTemplate template) {
    return GestureDetector(
      onTap: () => _selectTemplate(template),
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textColor(context).withAlpha(26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Template icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: template.color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(template.icon, color: template.color, size: 24),
            ),
            const SizedBox(width: 16),

            // Template info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    template.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textColor(context).withAlpha(153),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (template.defaultPillars.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    // Pillar tags
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: template.defaultPillars.take(2).map((pillar) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPillarColor(pillar).withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getPillarName(pillar),
                            style: TextStyle(
                              fontSize: 10,
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

            // Use template button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: template.color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_forward, color: template.color, size: 20),
            ),
          ],
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
            Icons.auto_awesome_outlined,
            size: 64,
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'no_templates_available'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'check_back_templates'),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor(context).withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  void _selectTemplate(PostTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplatePostCreatorScreen(template: template),
      ),
    );
  }

  Color _getPillarColor(pillar) {
    switch (pillar) {
      case PostPillar.fitness:
        return const Color(0xFF2196F3);
      case PostPillar.nutrition:
        return const Color(0xFF4CAF50);
      case PostPillar.eco:
        return const Color(0xFF8BC34A);
      default:
        return Colors.grey;
    }
  }

  String _getPillarName(pillar) {
    switch (pillar) {
      case PostPillar.fitness:
        return tr(context, 'fitness');
      case PostPillar.nutrition:
        return tr(context, 'nutrition');
      case PostPillar.eco:
        return tr(context, 'eco');
      default:
        return tr(context, 'other');
    }
  }
}
