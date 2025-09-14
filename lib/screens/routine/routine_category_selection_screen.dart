import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../templates/workout_templates_screen.dart';
import 'routine_creation_screen.dart';

class RoutineCategorySelectionScreen extends StatelessWidget {
  const RoutineCategorySelectionScreen({super.key});

  final List<RoutineCategory> _categories = const [
    RoutineCategory(
      name: 'Strength',
      icon: Icons.fitness_center,
      color: Colors.red,
      description: 'Build muscle and increase strength',
    ),
    RoutineCategory(
      name: 'Cardio',
      icon: Icons.directions_run,
      color: Colors.blue,
      description: 'Improve cardiovascular endurance',
    ),
    RoutineCategory(
      name: 'Full Body',
      icon: Icons.accessibility_new,
      color: Colors.purple,
      description: 'Complete body workouts',
    ),
    RoutineCategory(
      name: 'Split',
      icon: Icons.format_list_bulleted,
      color: Colors.orange,
      description: 'Targeted muscle group training',
    ),
    RoutineCategory(
      name: 'Mixed',
      icon: Icons.shuffle,
      color: Colors.teal,
      description: 'Combination training styles',
    ),
    RoutineCategory(
      name: 'Flexibility',
      icon: Icons.spa,
      color: Colors.green,
      description: 'Improve mobility and flexibility',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        elevation: 0,
        title: Text(
          tr(context, 'choose_workout_type'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'select_category_description'),
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(context, category);
              },
            ),
            
            const SizedBox(height: 32),
            
            // Quick Create Custom Routine Option
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.edit,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(context, 'create_custom_routine'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'build_routine_from_scratch'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _createCustomRoutine(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(tr(context, 'start_creating')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, RoutineCategory category) {
    return GestureDetector(
      onTap: () => _showCategoryOptions(context, category),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textColor(context).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                category.icon,
                size: 28,
                color: category.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr(context, category.name.toLowerCase()),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              tr(context, '${category.name.toLowerCase()}_description'),
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryOptions(BuildContext context, RoutineCategory category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textColor(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Category info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    size: 24,
                    color: category.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, category.name.toLowerCase()),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tr(context, '${category.name.toLowerCase()}_description'),
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Template option
            _buildOptionCard(
              context,
              icon: Icons.library_books,
              title: tr(context, 'browse_templates'),
              subtitle: tr(context, 'start_with_proven_workouts'),
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _browseTemplates(context, category.name);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Custom routine option  
            _buildOptionCard(
              context,
              icon: Icons.edit,
              title: tr(context, 'create_custom'),
              subtitle: tr(context, 'build_your_own_routine'),
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
              onTap: () {
                Navigator.pop(context);
                _createCustomRoutineWithCategory(context, category.name);
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textColor(context).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textColor(context).withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _browseTemplates(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutTemplatesScreen(
          initialCategory: category.toLowerCase(),
        ),
      ),
    );
  }

  void _createCustomRoutine(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoutineCreationScreen(),
      ),
    );
  }

  void _createCustomRoutineWithCategory(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineCreationScreen(
          preselectedCategory: category,
        ),
      ),
    );
  }
}

class RoutineCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const RoutineCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}