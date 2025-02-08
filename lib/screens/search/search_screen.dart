import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context),
            _buildTitle(context),
            _buildWorkoutList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SolarVita',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.textColor(context)),
            onPressed: () {},
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        'Fitness routines',
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          WorkoutCategoryCard(
            title: 'Strength training',
            mainImage: 'assets/images/search/strength_training/strength.jpg',
            smallImages: [
              'assets/images/search/strength_training/strength-1.jpg',
              'assets/images/search/strength_training/strength-2.jpg',
            ],
            count: '29+ challenges',
          ),
          SizedBox(height: 24),
          WorkoutCategoryCard(
            title: 'Abs & Cardio',
            mainImage: 'assets/images/search/abs_cardio/abs-1.jpg',
            smallImages: [
              'assets/images/search/abs_cardio/abs-2.jpg',
              'assets/images/search/abs_cardio/cardio.jpg',
            ],
            count: '20+ challenges',
          ),
          SizedBox(height: 24),
          WorkoutCategoryCard(
            title: 'Outdoor Activities',
            mainImage: 'assets/images/search/outdoor_activities/running.jpg',
            smallImages: [
              'assets/images/search/outdoor_activities/running-1.jpg',
              'assets/images/search/outdoor_activities/running-2.jpg',
            ],
            count: '32+ workouts',
          ),
          SizedBox(height: 24),
          WorkoutCategoryCard(
            title: 'Yoga sessions',
            mainImage: 'assets/images/search/yoga_sessions/yoga.jpg',
            smallImages: [
              'assets/images/search/yoga_sessions/yoga-1.jpg',
              'assets/images/search/yoga_sessions/yoga-2.jpg',
            ],
            count: '27+ activities',
          ),
          SizedBox(height: 24),
          WorkoutCategoryCard(
            title: 'Calisthenics',
            mainImage: 'assets/images/search/calisthenics/calisthenics.jpg',
            smallImages: [
              'assets/images/search/calisthenics/calisthenics-1.jpg',
              'assets/images/search/calisthenics/calisthenics-2.jpg',
            ],
            count: '50+ activities',
          ),
          SizedBox(height: 24),
          WorkoutCategoryCard(
            title: 'Meditation',
            mainImage: 'assets/images/search/meditation/meditation-2.jpg',
            smallImages: [
              'assets/images/search/meditation/meditation-1.jpg',
              'assets/images/search/meditation/meditation.jpg',
            ],
            count: '13+ challenges',
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class WorkoutCategoryCard extends StatelessWidget {
  final String title;
  final String mainImage;
  final List<String> smallImages;
  final String count;

  const WorkoutCategoryCard({
    super.key,
    required this.title,
    required this.mainImage,
    required this.smallImages,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Hero(
                tag: '${title}_main',
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: AssetImage(mainImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(smallImages[0]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(smallImages[1]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black54,
                              Colors.black26,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Center(
                          child: Text(
                            count,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
