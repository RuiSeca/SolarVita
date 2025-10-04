import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/eco/eco_tip.dart';
import 'widgets/tip_card.dart';
import 'widgets/sustainable_product_card.dart';
import 'widgets/carbon_tracker.dart';
import '../../../models/eco/carbon_activity.dart';
import '../../../../providers/riverpod/eco_provider.dart';
import '../../../providers/riverpod/interactive_coach_provider.dart';
import '../../../widgets/interactive_quantum_coach.dart';
import 'package:solar_vitas/utils/translation_helper.dart';

class EcoTipsScreen extends ConsumerStatefulWidget {
  const EcoTipsScreen({super.key});

  @override
  ConsumerState<EcoTipsScreen> createState() => _EcoTipsScreenState();
}

class _EcoTipsScreenState extends ConsumerState<EcoTipsScreen> {
  final List<EcoTip> _tips = [
    // Waste Management
    EcoTip(
      titleKey: 'tip_recycle_title',
      descriptionKey: 'tip_recycle_description',
      category: 'category_waste',
      imagePath: 'assets/images/eco_tips/waste_management/recycle.webp',
    ),
    EcoTip(
      titleKey: 'tip_composting_title',
      descriptionKey: 'tip_composting_description',
      category: 'category_waste',
      imagePath: 'assets/images/eco_tips/waste_management/composting.webp',
    ),
    EcoTip(
      titleKey: 'tip_plastic_free_title',
      descriptionKey: 'tip_plastic_free_description',
      category: 'category_waste',
      imagePath: 'assets/images/eco_tips/waste_management/plastic_free.webp',
    ),

    // Energy Conservation
    EcoTip(
      titleKey: 'tip_energy_title',
      descriptionKey: 'tip_energy_description',
      category: 'category_energy',
      imagePath: 'assets/images/eco_tips/energy/energy_saving.webp',
    ),
    EcoTip(
      titleKey: 'tip_led_bulbs_title',
      descriptionKey: 'tip_led_bulbs_description',
      category: 'category_energy',
      imagePath: 'assets/images/eco_tips/energy/led_bulbs.webp',
    ),
    EcoTip(
      titleKey: 'tip_unplug_devices_title',
      descriptionKey: 'tip_unplug_devices_description',
      category: 'category_energy',
      imagePath: 'assets/images/eco_tips/energy/unplug_devices.webp',
    ),

    // Water Conservation
    EcoTip(
      titleKey: 'tip_water_title',
      descriptionKey: 'tip_water_description',
      category: 'category_water',
      imagePath: 'assets/images/eco_tips/water/water_conservation.webp',
    ),
    EcoTip(
      titleKey: 'tip_shorter_showers_title',
      descriptionKey: 'tip_shorter_showers_description',
      category: 'category_water',
      imagePath: 'assets/images/eco_tips/water/shorter_showers.webp',
    ),
    EcoTip(
      titleKey: 'tip_fix_leaks_title',
      descriptionKey: 'tip_fix_leaks_description',
      category: 'category_water',
      imagePath: 'assets/images/eco_tips/water/fix_leaks.webp',
    ),

    // Sustainable Transport
    EcoTip(
      titleKey: 'tip_transport_title',
      descriptionKey: 'tip_transport_description',
      category: 'category_transport',
      imagePath: 'assets/images/eco_tips/transport/eco_transport.webp',
    ),
    EcoTip(
      titleKey: 'tip_bike_commute_title',
      descriptionKey: 'tip_bike_commute_description',
      category: 'category_transport',
      imagePath: 'assets/images/eco_tips/transport/bike_commute.webp',
    ),
    EcoTip(
      titleKey: 'tip_carpool_title',
      descriptionKey: 'tip_carpool_description',
      category: 'category_transport',
      imagePath: 'assets/images/eco_tips/transport/carpool.webp',
    ),

    // NEW: Sustainable Food
    EcoTip(
      titleKey: 'tip_local_food_title',
      descriptionKey: 'tip_local_food_description',
      category: 'category_food',
      imagePath: 'assets/images/eco_tips/food/local_food.webp',
    ),
    EcoTip(
      titleKey: 'tip_plant_based_title',
      descriptionKey: 'tip_plant_based_description',
      category: 'category_food',
      imagePath: 'assets/images/eco_tips/food/plant_based.webp',
    ),
    EcoTip(
      titleKey: 'tip_food_waste_title',
      descriptionKey: 'tip_food_waste_description',
      category: 'category_food',
      imagePath: 'assets/images/eco_tips/food/food_waste.webp',
    ),

    // NEW: Eco-Friendly Fitness
    EcoTip(
      titleKey: 'tip_outdoor_workout_title',
      descriptionKey: 'tip_outdoor_workout_description',
      category: 'category_fitness',
      imagePath: 'assets/images/eco_tips/fitness/outdoor_workout.webp',
    ),
    EcoTip(
      titleKey: 'tip_reusable_bottle_title',
      descriptionKey: 'tip_reusable_bottle_description',
      category: 'category_fitness',
      imagePath: 'assets/images/eco_tips/fitness/reusable_bottle.webp',
    ),
    EcoTip(
      titleKey: 'tip_bodyweight_exercise_title',
      descriptionKey: 'tip_bodyweight_exercise_description',
      category: 'category_fitness',
      imagePath: 'assets/images/eco_tips/fitness/bodyweight_exercise.webp',
    ),

    // NEW: Environmental Awareness (Fires, Pollution, etc.)
    EcoTip(
      titleKey: 'tip_forest_fires_title',
      descriptionKey: 'tip_forest_fires_description',
      category: 'category_awareness',
      imagePath: 'assets/images/eco_tips/awareness/forest_fires.webp',
    ),
    EcoTip(
      titleKey: 'tip_littering_impact_title',
      descriptionKey: 'tip_littering_impact_description',
      category: 'category_awareness',
      imagePath: 'assets/images/eco_tips/awareness/littering.webp',
    ),
    EcoTip(
      titleKey: 'tip_ocean_plastic_title',
      descriptionKey: 'tip_ocean_plastic_description',
      category: 'category_awareness',
      imagePath: 'assets/images/eco_tips/awareness/ocean_plastic.webp',
    ),
    EcoTip(
      titleKey: 'tip_deforestation_title',
      descriptionKey: 'tip_deforestation_description',
      category: 'category_awareness',
      imagePath: 'assets/images/eco_tips/awareness/deforestation.webp',
    ),
    EcoTip(
      titleKey: 'tip_air_pollution_title',
      descriptionKey: 'tip_air_pollution_description',
      category: 'category_awareness',
      imagePath: 'assets/images/eco_tips/awareness/air_pollution.webp',
    ),
    EcoTip(
      titleKey: 'tip_endangered_species_title',
      descriptionKey: 'tip_endangered_species_description',
      category: 'category_awareness',
      imagePath: 'assets/images/eco_tips/awareness/endangered_species.webp',
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
      body: Stack(
        children: [
          CustomScrollView(
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
                            _buildCategoryChip('category_food'),
                            _buildCategoryChip('category_fitness'),
                            _buildCategoryChip('category_awareness'),
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
          // Interactive Quantum Coach positioned on top of eco tips cards
          PositionedInteractiveCoach(
            location: CoachLocation.ecoStats,
            bottom: 100, // Positioned over the eco tips content
            right: 20,
            width: 80,
            height: 80,
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
