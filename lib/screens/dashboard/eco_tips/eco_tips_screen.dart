import 'package:flutter/material.dart';
import 'models/eco_tip.dart';
import 'widgets/tip_card.dart';
import 'widgets/sustainable_product_card.dart';
import 'widgets/carbon_tracker.dart';

class EcoTipsScreen extends StatefulWidget {
  const EcoTipsScreen({super.key});

  @override
  State<EcoTipsScreen> createState() => _EcoTipsScreenState();
}

class _EcoTipsScreenState extends State<EcoTipsScreen> {
  final List<EcoTip> _tips = [
    EcoTip(
      title: 'Reduce, Reuse, Recycle',
      description:
          'Learn how to effectively manage waste by reducing consumption, reusing products, and recycling materials.',
      category: 'Waste Management',
      imagePath: 'assets/images/recycle.jpg',
    ),
    EcoTip(
      title: 'Save Energy',
      description:
          'Discover simple habits to cut down on energy usage, such as turning off lights when not in use and using energy-efficient appliances.',
      category: 'Energy',
      imagePath: 'assets/images/energy.jpg',
    ),
    EcoTip(
      title: 'Water Conservation',
      description:
          'Implement water-saving techniques like fixing leaks and using low-flow showerheads to conserve this precious resource.',
      category: 'Water',
      imagePath: 'assets/images/water.jpg',
    ),
    EcoTip(
      title: 'Pedals for the Planet',
      description:
          'Use conventional bikes, and for those that want to benefit from technology, pedal-powered scooters, electric scooters, and electric bikes to reduce carbon footprint.',
      category: 'Transport',
      imagePath: 'assets/images/transport.jpg',
    ),
    // Add more tips as needed
  ];

  // Sample carbon tracker data
  final List<CarbonActivity> _carbonActivities = [
    CarbonActivity(
      name: 'Carpooling',
      co2Saved: 2.5,
      icon: Icons.directions_car,
      date: DateTime(2025, 1, 20),
    ),
    CarbonActivity(
      name: 'Public Transit',
      co2Saved: 1.8,
      icon: Icons.directions_bus,
      date: DateTime(2025, 1, 22),
    ),
    CarbonActivity(
      name: 'Biking',
      co2Saved: 0.5,
      icon: Icons.directions_bike,
      date: DateTime(2025, 1, 23),
    ),
  ];

  String _selectedCategory = 'All';

  double get _totalSaved {
    return _carbonActivities.fold(
        0, (sum, activity) => sum + activity.co2Saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme
          .scaffoldBackgroundColor, // Adjust background color based on theme
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text('Eco Tips', style: TextStyle(color: theme.primaryColor)),
        elevation: theme.appBarTheme.elevation,
      ),
      body: CustomScrollView(
        slivers: [
          // Header and category chips section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sustainable Living Tips',
                    style: TextStyle(
                      color: theme.primaryColor, // Use primary color from theme
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All'),
                        _buildCategoryChip('Waste Management'),
                        _buildCategoryChip('Energy'),
                        _buildCategoryChip('Water'),
                        _buildCategoryChip('Transport'),
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
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tip = _tips[index];
                  if (_selectedCategory == 'All' ||
                      tip.category == _selectedCategory) {
                    return TipCard(tip: tip);
                  }
                  return const SizedBox.shrink();
                },
                childCount: _tips.length,
              ),
            ),
          ),
          // Carbon Tracker section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CarbonTracker(
                activities: _carbonActivities,
                totalSaved: _totalSaved,
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
                    'Eco-Friendly Products Deals',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 24,
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
        label: Text(category,
            style: TextStyle(
                color: isSelected ? Colors.white : theme.primaryColor)),
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
