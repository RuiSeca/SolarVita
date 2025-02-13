// lib/screens/health/meal_search_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

class MealSearchScreen extends StatefulWidget {
  const MealSearchScreen({super.key});

  @override
  State<MealSearchScreen> createState() => _MealSearchScreenState();
}

class _MealSearchScreenState extends State<MealSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredMeals = [];
  final List<Map<String, dynamic>> _allMeals = [
    {
      'titleKey': 'breakfast_oatmeal',
      'imagePath': 'assets/images/health/meals/breakfast_1.jpg',
      'calories': '300 kcal',
      'category': 'breakfast',
      'isFavorite': false,
    },
    // Add more meals here
  ];

  @override
  void initState() {
    super.initState();
    _filteredMeals = _allMeals;
  }

  void _filterMeals(String query) {
    setState(() {
      _filteredMeals = _allMeals
          .where((meal) => tr(context, meal['titleKey'])
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, 'search_meals'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMeals,
              style: TextStyle(color: AppTheme.textColor(context)),
              decoration: InputDecoration(
                hintText: tr(context, 'search_meals_hint'),
                hintStyle: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(128)),
                prefixIcon:
                    Icon(Icons.search, color: AppTheme.textColor(context)),
                filled: true,
                fillColor: AppTheme.cardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredMeals.length,
              itemBuilder: (context, index) {
                final meal = _filteredMeals[index];
                return _buildMealItem(context, meal);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(BuildContext context, Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            meal['imagePath'],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          tr(context, meal['titleKey']),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              meal['calories'],
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(179),
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            meal['isFavorite'] ? Icons.favorite : Icons.favorite_border,
            color: meal['isFavorite']
                ? Colors.red
                : AppTheme.textColor(context).withAlpha(179),
          ),
          onPressed: () {
            setState(() {
              meal['isFavorite'] = !meal['isFavorite'];
            });
          },
        ),
        onTap: () {
          Navigator.pop(context, meal);
        },
      ),
    );
  }
}
