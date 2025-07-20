// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../dashboard/eco_tips/eco_tips_screen.dart';
import 'package:solar_vitas/theme/app_theme.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import '../../providers/riverpod/user_profile_provider.dart';
import '../../providers/riverpod/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  File? imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        setState(() {
          imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Image picker failed - continue without updating profile image
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final userProfileAsync = ref.watch(userProfileNotifierProvider);
                    final currentUser = ref.watch(currentUserProvider);
                    
                    final userProfile = userProfileAsync.value;
                    
                    String displayName = userProfile?.displayName ?? 
                                      currentUser?.displayName ?? 
                                      'Fitness Enthusiast';
                    
                    String? profileImageUrl = userProfile?.photoURL ?? 
                                           currentUser?.photoURL;
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: imageFile != null
                                          ? FileImage(imageFile!)
                                          : profileImageUrl != null
                                              ? CachedNetworkImageProvider(profileImageUrl)
                                              : null,
                                      backgroundColor:
                                          AppTheme.textFieldBackground(context),
                                      child: imageFile == null && profileImageUrl == null
                                          ? Icon(Icons.person,
                                              color: theme.iconTheme.color)
                                          : null,
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.scaffoldBackgroundColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr(context, 'welcome'),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.hintColor,
                                      ),
                                    ),
                                    Text(
                                      displayName,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const EcoTipsScreen()),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: theme.primaryColor.withAlpha(25),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            tr(context, 'eco_tips'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),


                const SizedBox(height: 16),

                // Popular Workouts Section
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(context, 'explore_popular_workouts'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.arrow_back_ios,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey[600]),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _buildWorkoutCard(
                  title: tr(context, 'beginners_hiit'),
                  author: tr(context, 'active_user'),
                  isPremium: true,
                  color: Colors.green,
                  imagePath: 'assets/images/dashboard/hiit.webp',
                ),
                const SizedBox(height: 24),

                // Quick Exercise Section
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(context, 'quick_exercise_routines'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.arrow_back_ios,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey[600]),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildExerciseCard(
                        title: tr(context, 'efficient_abs'),
                        author: tr(context, 'regular_trainer'),
                        imagePath: 'assets/images/dashboard/abs.webp',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildExerciseCard(
                        title: tr(context, 'strength_training'),
                        author: tr(context, 'fitness_coach'),
                        imagePath:
                            'assets/images/search/strength_training/strength.webp',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Categories
                Text(
                  tr(context, 'fitness_categories'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCategoryIcon(
                        Icons.fitness_center, tr(context, 'gym')),
                    _buildCategoryIcon(
                        Icons.directions_run, tr(context, 'hiit')),
                    _buildCategoryIcon(Icons.forest, tr(context, 'mindful')),
                    _buildCategoryIcon(
                        Icons.sports_volleyball, tr(context, 'toned')),
                    _buildCategoryIcon(
                        Icons.local_drink_outlined, tr(context, 'supplements')),
                  ],
                ),

                const SizedBox(height: 32),

                // Community Feed Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Friends & Community',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.people,
                          size: 20,
                          color: theme.primaryColor,
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to full community page
                      },
                      child: Text(
                        'See All',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSocialFeed(),

                const SizedBox(height: 32),

                // Active Challenges Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Community Challenges',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to challenges page
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActiveChallenges(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard({
    required String title,
    required String author,
    required bool isPremium,
    required Color color,
    required String imagePath,
  }) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withAlpha(77),
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        children: [
          if (isPremium)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FittedBox(
                  // Added FittedBox
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tr(context, 'upgrade'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, size: 16, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              // Added Container with width constraint
              width:
                  MediaQuery.of(context).size.width - 64, // Account for padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Added to minimize height
                children: [
                  Text(
                    tr(context, title),
                    style: const TextStyle(
                      fontSize: 14, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(context, author),
                    style: const TextStyle(
                      fontSize: 12, // Reduced font size
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard({
    required String title,
    required String author,
    required String imagePath,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withAlpha(77),
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.star, size: 14, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialFeed() {
    final theme = Theme.of(context);
    
    // Mock data for now - will be replaced with actual data from Firebase
    final mockActivities = [
      {
        'userName': 'Sarah M.',
        'activity': 'completed a 30-min HIIT workout',
        'time': '2h ago',
        'icon': '💪',
        'likes': 12,
        'visibility': '👥', // Friends only
        'isFriend': true,
      },
      {
        'userName': 'Mike R.',
        'activity': 'saved 500g CO2 by biking to work',
        'time': '4h ago',
        'icon': '🌱',
        'likes': 8,
        'visibility': '🌍', // Community
        'isFriend': false,
      },
      {
        'userName': 'Emma K.',
        'activity': 'shared a healthy breakfast recipe',
        'time': '6h ago',
        'icon': '🍽️',
        'likes': 15,
        'visibility': '👥', // Friends only
        'isFriend': true,
      },
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mockActivities.length,
        itemBuilder: (context, index) {
          final activity = mockActivities[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.textFieldBackground(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withAlpha(51),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.primaryColor.withAlpha(51),
                          child: Text(
                            activity['userName'].toString().substring(0, 1),
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (activity['isFriend'] == true)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  activity['userName'].toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activity['visibility'].toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            activity['time'].toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      activity['icon'].toString(),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activity['activity'].toString(),
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity['likes'].toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: theme.hintColor,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveChallenges() {
    final theme = Theme.of(context);
    
    // Mock challenge data
    final mockChallenges = [
      {
        'title': '7-Day Eco Challenge',
        'description': 'Reduce your carbon footprint for a week',
        'progress': 0.6,
        'participants': 156,
        'daysLeft': 3,
        'icon': '🌍',
      },
      {
        'title': 'January Fitness Sprint',
        'description': 'Complete 20 workouts this month',
        'progress': 0.45,
        'participants': 89,
        'daysLeft': 12,
        'icon': '🏃‍♂️',
      },
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mockChallenges.length,
        itemBuilder: (context, index) {
          final challenge = mockChallenges[index];
          return Container(
            width: 260,
            height: 140,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withAlpha(51),
                  theme.primaryColor.withAlpha(25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withAlpha(76),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      challenge['icon'].toString(),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        challenge['title'].toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    challenge['description'].toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: challenge['progress'] as double,
                  backgroundColor: theme.dividerColor.withAlpha(76),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${challenge['participants']} participants',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    Text(
                      '${challenge['daysLeft']} days left',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
