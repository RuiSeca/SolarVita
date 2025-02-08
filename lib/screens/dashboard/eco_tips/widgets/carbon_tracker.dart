import 'package:flutter/material.dart';

class CarbonActivity {
  final String name;
  final double co2Saved;
  final IconData icon;
  final DateTime date;

  CarbonActivity({
    required this.name,
    required this.co2Saved,
    required this.icon,
    required this.date,
  });
}

class CarbonTracker extends StatelessWidget {
  final List<CarbonActivity> activities;
  final double totalSaved;

  const CarbonTracker({
    super.key,
    required this.activities,
    required this.totalSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.cardColor; // Use the theme's card color
    final textColor = theme.textTheme.bodyLarge?.color;
    final accentColor =
        theme.colorScheme.secondary; // Use accent color for emphasis

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor, // Apply theme's background color
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carbon Footprint',
                style: TextStyle(
                  color: textColor, // Use theme's text color
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${totalSaved.toStringAsFixed(1)} kg CO₂',
                  style: TextStyle(
                    color: accentColor, // Use accent color for emphasis
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(activity.icon, color: accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.name,
                            style: TextStyle(
                              color: textColor, // Use theme's text color
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${activity.date.day}/${activity.date.month}/${activity.date.year}',
                            style: TextStyle(
                              color: theme.hintColor, // Use theme's hint color
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-${activity.co2Saved.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: accentColor, // Use accent color for emphasis
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
