import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/riverpod/health_data_provider.dart';
import '../../providers/riverpod/location_provider.dart';
import '../../widgets/optimized_map_factory.dart';
import 'package:geolocator/geolocator.dart';

class TransportationDetailsScreen extends ConsumerStatefulWidget {
  const TransportationDetailsScreen({super.key});

  @override
  ConsumerState<TransportationDetailsScreen> createState() => _TransportationDetailsScreenState();
}

class _TransportationDetailsScreenState extends ConsumerState<TransportationDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final steps = ref.watch(dailyStepsProvider);
    final activeMinutes = ref.watch(activeMinutesProvider);
    final currentPosition = ref.watch(currentPositionNotifierProvider);
    final ecoRoutes = ref.watch(ecoRoutesNotifierProvider);
    final carbonSavings = ref.watch(currentLocationCarbonSavingsProvider);

    // Generate sample eco routes when position is available
    currentPosition.whenData((position) {
      if (position != null) {
        final sampleDestination = Position(
          latitude: position.latitude + 0.01,
          longitude: position.longitude + 0.005,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(ecoRoutesNotifierProvider.notifier).updateRoutes(position, sampleDestination);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Transportation Details',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppTheme.textColor(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textColor(context)),
            onPressed: () {
              ref.invalidate(healthDataNotifierProvider);
              ref.invalidate(currentPositionNotifierProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section with today's overview
            _buildHeroSection(context, steps, activeMinutes, carbonSavings),
            const SizedBox(height: 24),

            // Interactive map section
            _buildMapSection(context),
            const SizedBox(height: 24),

            // Detailed stats grid
            _buildDetailedStatsSection(context, steps, activeMinutes, carbonSavings),
            const SizedBox(height: 24),

            // Eco routes section
            _buildEcoRoutesSection(context, ecoRoutes),
            const SizedBox(height: 24),

            // Transportation modes comparison
            _buildTransportationModesSection(context, steps),
            const SizedBox(height: 24),

            // Weekly progress section
            _buildWeeklyProgressSection(context),
            const SizedBox(height: 24),

            // Achievements section
            _buildAchievementsSection(context, steps, activeMinutes),
            const SizedBox(height: 24),

            // Environmental impact visualization
            _buildEnvironmentalImpactSection(context, carbonSavings),
            const SizedBox(height: 24),

            // Tips and recommendations
            _buildTipsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, int steps, int activeMinutes, double carbonSavings) {
    final walkingKm = (steps * 0.0008);
    final bottlesSaved = (carbonSavings / 0.2).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.8),
            Colors.blue.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                'Today\'s Movement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildHeroStatCard(
                  '$steps',
                  'Steps',
                  Icons.directions_walk,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeroStatCard(
                  '${walkingKm.toStringAsFixed(1)} km',
                  'Distance',
                  Icons.straighten,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildHeroStatCard(
                  '${carbonSavings.toStringAsFixed(2)} kg',
                  'CO₂ Saved',
                  Icons.eco,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeroStatCard(
                  '$bottlesSaved',
                  'Bottles Prevented',
                  Icons.water_drop,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: OptimizedMapFactory.createMap(
          height: 400,
          showRoutes: true,
          enableInteraction: true,
        ),
      ),
    );
  }

  Widget _buildDetailedStatsSection(BuildContext context, int steps, int activeMinutes, double carbonSavings) {
    final walkingKm = (steps * 0.0008);
    final caloriesBurned = (steps * 0.04).round();
    final bottlesSaved = (carbonSavings / 0.2).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Statistics',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(context, 'Steps', '$steps', 'Today', Icons.directions_walk, Colors.blue[600]!),
              _buildStatCard(context, 'Distance', '${walkingKm.toStringAsFixed(1)} km', 'Walked', Icons.straighten, Colors.green[600]!),
              _buildStatCard(context, 'Active Time', '$activeMinutes min', 'Exercise', Icons.timer, Colors.orange[600]!),
              _buildStatCard(context, 'Calories', '$caloriesBurned cal', 'Burned', Icons.local_fire_department, Colors.red[600]!),
              _buildStatCard(context, 'CO₂ Saved', '${carbonSavings.toStringAsFixed(2)} kg', 'vs Driving', Icons.co2, Colors.green[700]!),
              _buildStatCard(context, 'Bottles', '$bottlesSaved', 'Prevented', Icons.water_drop, Colors.blue[700]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textColor(context).withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEcoRoutesSection(BuildContext context, List<Map<String, dynamic>> routes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Eco-Friendly Routes',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (routes.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Enable location to discover eco routes',
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...routes.map((route) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getRouteColor(route['color'] as String).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRouteColor(route['color'] as String).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getRouteColor(route['color'] as String).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getRouteIcon(route['icon'] as String),
                      color: _getRouteColor(route['color'] as String),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route['name'] as String,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(route['carbonSaved'] as double).toStringAsFixed(1)} kg CO₂ saved • ${route['distance'] ?? 'Unknown'} distance',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ECO',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportationModesSection(BuildContext context, int steps) {
    final walkingKm = (steps * 0.0008);
    
    final modes = [
      {
        'name': 'Walking',
        'icon': Icons.directions_walk,
        'color': Colors.green,
        'distance': '${walkingKm.toStringAsFixed(1)} km',
        'carbon': '${(walkingKm * 0.21).toStringAsFixed(2)} kg saved',
        'efficiency': 'Most Eco-Friendly',
      },
      {
        'name': 'Biking',
        'icon': Icons.directions_bike,
        'color': Colors.blue,
        'distance': '0.0 km',
        'carbon': '0.00 kg saved',
        'efficiency': 'Very Efficient',
      },
      {
        'name': 'Public Transit',
        'icon': Icons.directions_bus,
        'color': Colors.orange,
        'distance': '0.0 km',
        'carbon': '0.00 kg saved',
        'efficiency': 'Good Option',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transportation Modes',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...modes.map((mode) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (mode['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (mode['color'] as Color).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  mode['icon'] as IconData,
                  color: mode['color'] as Color,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode['name'] as String,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${mode['distance']} • ${mode['carbon']}',
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (mode['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mode['efficiency'] as String,
                    style: TextStyle(
                      color: mode['color'] as Color,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.purple[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Weekly Progress',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Weekly stats grid
          Row(
            children: [
              Expanded(
                child: _buildWeeklyStatItem(
                  context,
                  'Total Steps',
                  '42,150',
                  Icons.directions_walk,
                  Colors.blue[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeeklyStatItem(
                  context,
                  'Distance',
                  '33.7 km',
                  Icons.straighten,
                  Colors.green[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildWeeklyStatItem(
                  context,
                  'CO₂ Saved',
                  '7.08 kg',
                  Icons.eco,
                  Colors.green[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeeklyStatItem(
                  context,
                  'Active Days',
                  '6/7',
                  Icons.star,
                  Colors.amber[600]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatItem(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, int steps, int activeMinutes) {
    final achievements = _calculateTransportationAchievements(steps, activeMinutes);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'Achievements',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (achievements.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Keep moving to unlock achievements!',
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...achievements.map((achievement) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      achievement['emoji'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement['title'] as String,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          achievement['description'] as String,
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildEnvironmentalImpactSection(BuildContext context, double carbonSavings) {
    final bottlesSaved = (carbonSavings / 0.2).round();
    final treesEquivalent = (carbonSavings / 22).toStringAsFixed(1); // 1 tree absorbs ~22kg CO2/year
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.teal.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nature, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'Environmental Impact',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Your sustainable transportation choices today have made a real difference:',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildImpactCard(
                  context,
                  '🌍',
                  '${carbonSavings.toStringAsFixed(2)} kg',
                  'CO₂ Prevented',
                  Colors.green[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImpactCard(
                  context,
                  '♻️',
                  '$bottlesSaved',
                  'Plastic Bottles',
                  Colors.blue[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildImpactCard(
                  context,
                  '🌳',
                  treesEquivalent,
                  'Trees Equivalent',
                  Colors.green[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImpactCard(
                  context,
                  '💪',
                  'Health',
                  'Bonus Benefits',
                  Colors.orange[600]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(BuildContext context, String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    final tips = [
      {
        'icon': Icons.directions_walk,
        'title': 'Walk for Short Trips',
        'description': 'Choose walking for trips under 1km to maximize health and environmental benefits.',
        'color': Colors.green,
      },
      {
        'icon': Icons.directions_bike,
        'title': 'Bike for Medium Distances',
        'description': 'Cycling is perfect for 1-5km trips, saving time while staying eco-friendly.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.directions_bus,
        'title': 'Use Public Transport',
        'description': 'For longer distances, public transport reduces individual carbon footprint significantly.',
        'color': Colors.orange,
      },
      {
        'icon': Icons.group,
        'title': 'Consider Carpooling',
        'description': 'When driving is necessary, sharing rides can reduce emissions per person.',
        'color': Colors.purple,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Smart Transportation Tips',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...tips.map((tip) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (tip['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (tip['color'] as Color).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  tip['icon'] as IconData,
                  color: tip['color'] as Color,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title'] as String,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip['description'] as String,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  IconData _getRouteIcon(String iconName) {
    switch (iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'directions_bus':
        return Icons.directions_bus;
      default:
        return Icons.directions;
    }
  }

  Color _getRouteColor(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _calculateTransportationAchievements(int steps, int activeMinutes) {
    final achievements = <Map<String, dynamic>>[];
    
    if (steps >= 10000) {
      achievements.add({
        'emoji': '🚶‍♀️',
        'title': '10K Steps Champion',
        'description': 'You\'ve walked over 10,000 steps today!',
      });
    }
    
    if (steps >= 5000) {
      achievements.add({
        'emoji': '🏃‍♂️',
        'title': 'Active Walker',
        'description': 'Great job staying active with $steps steps!',
      });
    }
    
    if (activeMinutes >= 30) {
      achievements.add({
        'emoji': '💪',
        'title': 'Fitness Goal',
        'description': '$activeMinutes minutes of active movement today!',
      });
    }
    
    final carbonSaved = (steps * 0.0008) * 0.21;
    if (carbonSaved >= 1.0) {
      achievements.add({
        'emoji': '🌱',
        'title': 'Carbon Saver',
        'description': 'Saved ${carbonSaved.toStringAsFixed(1)}kg CO₂ by walking!',
      });
    }
    
    return achievements;
  }
}