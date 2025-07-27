import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_context.dart';
import '../../services/ai_service.dart';

class EcoImpactScreen extends StatelessWidget {
  const EcoImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get eco stats from AI service context
    final aiService = AIService(
      context: UserContext(
        preferredWorkoutDuration: 30,
        plasticBottlesSaved: 45,
        ecoScore: 85,
        carbonSaved: 12.5,
        mealCarbonSaved: 8.3,
        suggestedWorkoutTime: '8:00 AM',
      ),
    );
    final userContext = aiService.context;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Eco Impact',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main eco stats card
            _buildEcoStatsCard(userContext),
            const SizedBox(height: 24),
            
            // Individual impact sections
            _buildImpactSection(
              context,
              title: 'Plastic Reduction',
              icon: Icons.water_drop,
              color: Colors.blue,
              value: '${userContext.plasticBottlesSaved}',
              unit: 'Bottles Saved',
              description: 'By choosing eco-friendly options, you\'ve helped reduce plastic waste equivalent to ${userContext.plasticBottlesSaved} plastic bottles.',
            ),
            const SizedBox(height: 16),
            
            _buildImpactSection(
              context,
              title: 'Carbon Footprint',
              icon: Icons.co2,
              color: Colors.green,
              value: userContext.carbonSaved.toStringAsFixed(1),
              unit: 'kg CO₂ Saved',
              description: 'Your sustainable lifestyle choices have prevented ${userContext.carbonSaved.toStringAsFixed(1)}kg of CO₂ from entering the atmosphere.',
            ),
            const SizedBox(height: 16),
            
            _buildImpactSection(
              context,
              title: 'Sustainable Meals',
              icon: Icons.restaurant,
              color: Colors.orange,
              value: userContext.mealCarbonSaved.toStringAsFixed(1),
              unit: 'kg CO₂ from Meals',
              description: 'Your mindful meal choices have reduced your carbon footprint by ${userContext.mealCarbonSaved.toStringAsFixed(1)}kg through sustainable eating.',
            ),
            const SizedBox(height: 16),
            
            _buildImpactSection(
              context,
              title: 'Overall Eco Score',
              icon: Icons.stars,
              color: Colors.amber,
              value: '${userContext.ecoScore}',
              unit: 'Points',
              description: 'Your combined eco-friendly actions have earned you ${userContext.ecoScore} sustainability points. Keep up the great work!',
            ),
            const SizedBox(height: 32),
            
            // Tips section
            _buildTipsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEcoStatsCard(UserContext userContext) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Eco Impact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEcoStatItem(
                  icon: Icons.water_drop,
                  value: '${userContext.plasticBottlesSaved}',
                  label: 'Bottles Saved',
                  color: Colors.blue.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEcoStatItem(
                  icon: Icons.co2,
                  value: '${userContext.carbonSaved.toStringAsFixed(1)}kg',
                  label: 'Carbon Saved',
                  color: Colors.green.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEcoStatItem(
                  icon: Icons.restaurant,
                  value: '${userContext.mealCarbonSaved.toStringAsFixed(1)}kg',
                  label: 'Meal Carbon',
                  color: Colors.orange.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEcoStatItem(
                  icon: Icons.stars,
                  value: '${userContext.ecoScore}',
                  label: 'Eco Score',
                  color: Colors.yellow.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcoStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String unit,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Eco Tips',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...const [
            '🌱 Choose plant-based meals to reduce carbon footprint',
            '♻️ Use reusable water bottles and containers',
            '🚶‍♀️ Walk or bike for short distances instead of driving',
            '💡 Turn off lights and electronics when not in use',
            '🌿 Support local and organic food producers',
          ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  tip,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}