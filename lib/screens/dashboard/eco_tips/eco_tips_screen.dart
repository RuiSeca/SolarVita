import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/eco/eco_tip.dart';
import 'widgets/tip_card.dart';
import 'widgets/sustainable_product_card.dart';
import 'widgets/carbon_tracker.dart';
import '../../../models/eco/carbon_activity.dart';
import '../../../../providers/riverpod/eco_provider.dart';
import 'package:solar_vitas/utils/translation_helper.dart';

class EcoTipsScreen extends ConsumerStatefulWidget {
  const EcoTipsScreen({super.key});

  @override
  ConsumerState<EcoTipsScreen> createState() => _EcoTipsScreenState();
}

class _EcoTipsScreenState extends ConsumerState<EcoTipsScreen> {
  final List<EcoTip> _tips = [
    EcoTip(
      titleKey: 'tip_recycle_title',
      descriptionKey: 'tip_recycle_description',
      category: 'category_waste',
      imagePath: 'assets/images/eco_tips/waste_management/recycle.webp',
    ),
    EcoTip(
      titleKey: 'tip_energy_title',
      descriptionKey: 'tip_energy_description',
      category: 'category_energy',
      imagePath: 'assets/images/eco_tips/energy/energy.webp',
    ),
    EcoTip(
      titleKey: 'tip_water_title',
      descriptionKey: 'tip_water_description',
      category: 'category_water',
      imagePath: 'assets/images/eco_tips/water/water.webp',
    ),
    EcoTip(
      titleKey: 'tip_transport_title',
      descriptionKey: 'tip_transport_description',
      category: 'category_transport',
      imagePath: 'assets/images/eco_tips/transport/transport.webp',
    ),
  ];
  String _selectedCategory = 'category_all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentActivitiesAsync = ref.watch(recentEcoActivitiesProvider);
    final carbonLast30DaysAsync = ref.watch(carbonSavedLast30DaysProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          tr(context, 'sustainable_living_tips'),
          style: TextStyle(
            color: theme.primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('category_all'),
                        _buildCategoryChip('category_waste'),
                        _buildCategoryChip('category_energy'),
                        _buildCategoryChip('category_water'),
                        _buildCategoryChip('category_transport'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Eco tips list section
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tip = _tips[index];
                if (_selectedCategory == 'category_all' ||
                    tip.category == _selectedCategory) {
                  return TipCard(tip: tip);
                }
                return const SizedBox.shrink();
              }, childCount: _tips.length),
            ),
          ),
          // Carbon Tracker section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: recentActivitiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Error loading carbon tracker: $error')),
                data: (ecoActivities) {
                  // Convert EcoActivity to CarbonActivity for compatibility
                  final carbonActivities = ecoActivities
                      .map((eco) => CarbonActivity.fromEcoActivity(eco))
                      .toList();

                  return carbonLast30DaysAsync.when(
                    loading: () => CarbonTracker(
                      activities: carbonActivities,
                      totalSaved: carbonActivities.fold(
                        0.0,
                        (sum, activity) => sum + activity.co2Saved,
                      ),
                    ),
                    error: (error, stack) => CarbonTracker(
                      activities: carbonActivities,
                      totalSaved: carbonActivities.fold(
                        0.0,
                        (sum, activity) => sum + activity.co2Saved,
                      ),
                    ),
                    data: (totalSaved) => CarbonTracker(
                      activities: carbonActivities,
                      totalSaved: totalSaved,
                    ),
                  );
                },
              ),
            ),
          ),
          // Sustainable Products section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'eco_friendly_deals'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SustainableProductsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final theme = Theme.of(context);
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          tr(context, category),
          style: TextStyle(
            color: isSelected ? Colors.white : theme.primaryColor,
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: isSelected ? theme.primaryColor : Colors.grey[900],
        selectedColor: theme.primaryColor,
      ),
    );
  }
}
