// lib/models/post_template.dart
import 'package:flutter/material.dart';
import 'social_post.dart';

enum TemplateCategory {
  weeklyWins,
  fitnessAchievement,
  nutritionGoal,
  ecoChallenge,
  mindfulness,
  milestone,
  gratitude,
}

class PostTemplate {
  final String id;
  final String title;
  final String description;
  final String promptText;
  final List<String> suggestedContent;
  final PostType postType;
  final List<PostPillar> defaultPillars;
  final TemplateCategory category;
  final IconData icon;
  final Color color;
  final List<String> placeholders;
  final Map<String, String> variablePrompts;

  PostTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.promptText,
    required this.suggestedContent,
    required this.postType,
    required this.defaultPillars,
    required this.category,
    required this.icon,
    required this.color,
    required this.placeholders,
    required this.variablePrompts,
  });

  // Generate personalized content based on user input
  String generateContent(Map<String, String> userInputs) {
    String content = promptText;
    
    // Replace placeholders with user inputs
    userInputs.forEach((key, value) {
      content = content.replaceAll('{$key}', value);
    });
    
    return content;
  }

  // Check if template has variables that need user input
  bool get hasVariables => placeholders.isNotEmpty;
}

class WeeklyWinsTemplate {
  static List<PostTemplate> getWeeklyWinsTemplates() {
    return [
      PostTemplate(
        id: 'weekly_wins_fitness',
        title: 'Fitness Wins',
        description: 'Share your fitness achievements this week',
        promptText: 'This week I conquered: {achievement}! 💪\n\nWhat made it special: {details}\n\nNext week I\'m aiming for: {next_goal}',
        suggestedContent: [
          'Completed my first 5K run',
          'Hit the gym 4 times this week',
          'Tried a new workout class',
          'Increased my weights',
          'Improved my form',
        ],
        postType: PostType.weeklyWins,
        defaultPillars: [PostPillar.fitness],
        category: TemplateCategory.weeklyWins,
        icon: Icons.fitness_center,
        color: const Color(0xFF2196F3),
        placeholders: ['achievement', 'details', 'next_goal'],
        variablePrompts: {
          'achievement': 'What was your biggest fitness win this week?',
          'details': 'What made this achievement special?',
          'next_goal': 'What are you aiming for next week?',
        },
      ),
      
      PostTemplate(
        id: 'weekly_wins_nutrition',
        title: 'Nutrition Wins',
        description: 'Celebrate your healthy eating achievements',
        promptText: 'Nutrition win of the week: {achievement} 🥗\n\nHow it felt: {feeling}\n\nTip for others: {tip}',
        suggestedContent: [
          'Meal prepped for the entire week',
          'Tried 3 new healthy recipes',
          'Drank 8 glasses of water daily',
          'Cut down on processed foods',
          'Added more vegetables to meals',
        ],
        postType: PostType.weeklyWins,
        defaultPillars: [PostPillar.nutrition],
        category: TemplateCategory.weeklyWins,
        icon: Icons.restaurant,
        color: const Color(0xFF4CAF50),
        placeholders: ['achievement', 'feeling', 'tip'],
        variablePrompts: {
          'achievement': 'What was your biggest nutrition win?',
          'feeling': 'How did this make you feel?',
          'tip': 'What tip would you share with others?',
        },
      ),

      PostTemplate(
        id: 'weekly_wins_eco',
        title: 'Eco Wins',
        description: 'Share your sustainable living achievements',
        promptText: 'Eco-friendly win: {achievement} 🌱\n\nImpact: {impact}\n\nInspiring others to: {inspiration}',
        suggestedContent: [
          'Used reusable bags for all shopping',
          'Biked to work every day',
          'Started composting',
          'Reduced plastic usage by 50%',
          'Planted herbs in my garden',
        ],
        postType: PostType.weeklyWins,
        defaultPillars: [PostPillar.eco],
        category: TemplateCategory.weeklyWins,
        icon: Icons.eco,
        color: const Color(0xFF8BC34A),
        placeholders: ['achievement', 'impact', 'inspiration'],
        variablePrompts: {
          'achievement': 'What eco-friendly action did you take?',
          'impact': 'What impact do you think it had?',
          'inspiration': 'How can you inspire others?',
        },
      ),

      PostTemplate(
        id: 'weekly_wins_mindful',
        title: 'Mindfulness Wins',
        description: 'Reflect on your mental wellness journey',
        promptText: 'Mindfulness moment: {practice} 🧘‍♀️\n\nWhat I learned: {insight}\n\nFeeling grateful for: {gratitude}',
        suggestedContent: [
          'Meditated for 10 minutes daily',
          'Practiced gratitude journaling',
          'Took mindful walks in nature',
          'Did breathing exercises during stress',
          'Disconnected from social media',
        ],
        postType: PostType.weeklyWins,
        defaultPillars: [PostPillar.fitness], // Wellness/mental health
        category: TemplateCategory.weeklyWins,
        icon: Icons.self_improvement,
        color: const Color(0xFF9C27B0),
        placeholders: ['practice', 'insight', 'gratitude'],
        variablePrompts: {
          'practice': 'What mindfulness practice did you do?',
          'insight': 'What insight did you gain?',
          'gratitude': 'What are you grateful for?',
        },
      ),
    ];
  }

  static List<PostTemplate> getAchievementTemplates() {
    return [
      PostTemplate(
        id: 'milestone_weight_loss',
        title: 'Weight Loss Milestone',
        description: 'Celebrate reaching a weight loss goal',
        promptText: 'Milestone achieved! Lost {amount} {unit}! 🎉\n\nJourney so far: {journey}\n\nWhat kept me motivated: {motivation}\n\nNext milestone: {next_goal}',
        suggestedContent: [],
        postType: PostType.milestone,
        defaultPillars: [PostPillar.fitness, PostPillar.nutrition],
        category: TemplateCategory.fitnessAchievement,
        icon: Icons.trending_down,
        color: const Color(0xFFFF9800),
        placeholders: ['amount', 'unit', 'journey', 'motivation', 'next_goal'],
        variablePrompts: {
          'amount': 'How much weight did you lose?',
          'unit': 'lbs or kg?',
          'journey': 'How long did this take?',
          'motivation': 'What kept you motivated?',
          'next_goal': 'What\'s your next milestone?',
        },
      ),

      PostTemplate(
        id: 'first_race',
        title: 'First Race Completion',
        description: 'Share your first race experience',
        promptText: 'Just completed my first {race_type}! 🏃‍♀️\n\nTime: {time}\nFeeling: {emotion}\n\nBiggest challenge: {challenge}\nProudest moment: {proud_moment}\n\nTo anyone thinking about it: {advice}',
        suggestedContent: [],
        postType: PostType.milestone,
        defaultPillars: [PostPillar.fitness],
        category: TemplateCategory.fitnessAchievement,
        icon: Icons.emoji_events,
        color: const Color(0xFFFFD700),
        placeholders: ['race_type', 'time', 'emotion', 'challenge', 'proud_moment', 'advice'],
        variablePrompts: {
          'race_type': 'What type of race? (5K, 10K, marathon, etc.)',
          'time': 'What was your finish time?',
          'emotion': 'How are you feeling right now?',
          'challenge': 'What was the biggest challenge?',
          'proud_moment': 'What moment are you most proud of?',
          'advice': 'What advice would you give others?',
        },
      ),

      PostTemplate(
        id: 'habit_streak',
        title: 'Habit Streak',
        description: 'Celebrate maintaining a healthy habit',
        promptText: '{streak_days} days of {habit}! 📈\n\nHow it started: {start_story}\nHow it\'s going: {current_feeling}\n\nTips that helped: {tips}\nNext milestone: {next_milestone}',
        suggestedContent: [],
        postType: PostType.milestone,
        defaultPillars: [PostPillar.fitness],
        category: TemplateCategory.milestone,
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF5722),
        placeholders: ['streak_days', 'habit', 'start_story', 'current_feeling', 'tips', 'next_milestone'],
        variablePrompts: {
          'streak_days': 'How many days is your streak?',
          'habit': 'What habit are you tracking?',
          'start_story': 'How did you start this habit?',
          'current_feeling': 'How does it feel now?',
          'tips': 'What tips helped you succeed?',
          'next_milestone': 'What\'s your next goal?',
        },
      ),
    ];
  }

  static List<PostTemplate> getGratitudeTemplates() {
    return [
      PostTemplate(
        id: 'daily_gratitude',
        title: 'Daily Gratitude',
        description: 'Share what you\'re grateful for today',
        promptText: 'Today I\'m grateful for: {gratitude_1}, {gratitude_2}, and {gratitude_3} 🙏\n\nWhy: {reason}\n\nSpread the gratitude: {call_to_action}',
        suggestedContent: [
          'My health and energy',
          'Supportive friends and family',
          'Access to nutritious food',
          'The ability to move my body',
          'A beautiful day outdoors',
        ],
        postType: PostType.reflection,
        defaultPillars: [],
        category: TemplateCategory.gratitude,
        icon: Icons.favorite,
        color: const Color(0xFFE91E63),
        placeholders: ['gratitude_1', 'gratitude_2', 'gratitude_3', 'reason', 'call_to_action'],
        variablePrompts: {
          'gratitude_1': 'First thing you\'re grateful for?',
          'gratitude_2': 'Second thing you\'re grateful for?',
          'gratitude_3': 'Third thing you\'re grateful for?',
          'reason': 'Why are these meaningful to you?',
          'call_to_action': 'What would you like others to reflect on?',
        },
      ),
    ];
  }

  static List<PostTemplate> getProgressTemplates() {
    return [
      PostTemplate(
        id: 'progress_before_after',
        title: 'Before & After Progress',
        description: 'Share your transformation journey',
        promptText: 'Progress check! 📸\n\nTimeframe: {timeframe}\nWhat changed: {changes}\nHardest part: {challenge}\nBest part: {highlight}\n\nTo anyone starting: {encouragement}',
        suggestedContent: [],
        postType: PostType.fitnessProgress,
        defaultPillars: [PostPillar.fitness],
        category: TemplateCategory.fitnessAchievement,
        icon: Icons.compare,
        color: const Color(0xFF3F51B5),
        placeholders: ['timeframe', 'changes', 'challenge', 'highlight', 'encouragement'],
        variablePrompts: {
          'timeframe': 'How long between these photos?',
          'changes': 'What changes do you see?',
          'challenge': 'What was the hardest part of this journey?',
          'highlight': 'What are you most proud of?',
          'encouragement': 'What would you tell someone just starting?',
        },
      ),

      PostTemplate(
        id: 'strength_pr',
        title: 'Personal Record (PR)',
        description: 'Celebrate breaking a personal record',
        promptText: 'NEW PR! 🔥\n\nExercise: {exercise}\nNew record: {new_record}\nPrevious: {old_record}\n\nHow it felt: {feeling}\nKey to success: {success_factor}\n\nNext goal: {next_goal}',
        suggestedContent: [],
        postType: PostType.fitnessProgress,
        defaultPillars: [PostPillar.fitness],
        category: TemplateCategory.fitnessAchievement,
        icon: Icons.trending_up,
        color: const Color(0xFFFF6B35),
        placeholders: ['exercise', 'new_record', 'old_record', 'feeling', 'success_factor', 'next_goal'],
        variablePrompts: {
          'exercise': 'What exercise did you PR in?',
          'new_record': 'What was your new record?',
          'old_record': 'What was your previous record?',
          'feeling': 'How did breaking this PR feel?',
          'success_factor': 'What do you think led to this breakthrough?',
          'next_goal': 'What PR are you working towards next?',
        },
      ),
    ];
  }

  static List<PostTemplate> getNutritionTemplates() {
    return [
      PostTemplate(
        id: 'recipe_share',
        title: 'Healthy Recipe Share',
        description: 'Share a delicious and nutritious recipe',
        promptText: 'Recipe of the day: {recipe_name} 🍽️\n\nWhy I love it: {why_love}\nKey ingredients: {ingredients}\nPrep time: {prep_time}\n\nNutrition highlight: {nutrition}\nTip: {cooking_tip}',
        suggestedContent: [],
        postType: PostType.nutritionUpdate,
        defaultPillars: [PostPillar.nutrition],
        category: TemplateCategory.nutritionGoal,
        icon: Icons.restaurant_menu,
        color: const Color(0xFF66BB6A),
        placeholders: ['recipe_name', 'why_love', 'ingredients', 'prep_time', 'nutrition', 'cooking_tip'],
        variablePrompts: {
          'recipe_name': 'What\'s the name of your recipe?',
          'why_love': 'Why do you love this recipe?',
          'ingredients': 'What are the key ingredients?',
          'prep_time': 'How long does it take to prepare?',
          'nutrition': 'What makes this nutritionally great?',
          'cooking_tip': 'Any cooking tips to share?',
        },
      ),

      PostTemplate(
        id: 'nutrition_challenge',
        title: 'Nutrition Challenge Complete',
        description: 'Celebrate completing a nutrition challenge',
        promptText: '{challenge_name} challenge complete! ✅\n\nDuration: {duration}\nBiggest change: {change}\nUnexpected benefit: {benefit}\nWould I do it again: {would_repeat}\n\nAdvice for others: {advice}',
        suggestedContent: [],
        postType: PostType.nutritionUpdate,
        defaultPillars: [PostPillar.nutrition],
        category: TemplateCategory.nutritionGoal,
        icon: Icons.task_alt,
        color: const Color(0xFF43A047),
        placeholders: ['challenge_name', 'duration', 'change', 'benefit', 'would_repeat', 'advice'],
        variablePrompts: {
          'challenge_name': 'What challenge did you complete?',
          'duration': 'How long was the challenge?',
          'change': 'What was the biggest change you noticed?',
          'benefit': 'What unexpected benefit did you experience?',
          'would_repeat': 'Would you do this challenge again? Why?',
          'advice': 'What advice would you give someone starting this?',
        },
      ),
    ];
  }

  static List<PostTemplate> getEcoTemplates() {
    return [
      PostTemplate(
        id: 'sustainable_swap',
        title: 'Sustainable Product Swap',
        description: 'Share a sustainable product you\'ve switched to',
        promptText: 'Sustainable swap: {product_name} ♻️\n\nSwapped from: {old_product}\nWhy I switched: {reason}\nHow it\'s different: {difference}\nCost comparison: {cost}\n\nRecommend it? {recommendation}',
        suggestedContent: [],
        postType: PostType.ecoAchievement,
        defaultPillars: [PostPillar.eco],
        category: TemplateCategory.ecoChallenge,
        icon: Icons.swap_horiz,
        color: const Color(0xFF4CAF50),
        placeholders: ['product_name', 'old_product', 'reason', 'difference', 'cost', 'recommendation'],
        variablePrompts: {
          'product_name': 'What sustainable product did you try?',
          'old_product': 'What were you using before?',
          'reason': 'Why did you decide to make the switch?',
          'difference': 'How is the new product different?',
          'cost': 'How does the cost compare?',
          'recommendation': 'Would you recommend it to others?',
        },
      ),

      PostTemplate(
        id: 'carbon_reduction',
        title: 'Carbon Footprint Reduction',
        description: 'Share actions you took to reduce your carbon footprint',
        promptText: 'This week I reduced my carbon footprint by: {action} 🌍\n\nImpact: {impact}\nEasier than expected: {easy_part}\nChallenge: {challenge}\nNext step: {next_action}\n\nJoin me in: {call_to_action}',
        suggestedContent: [],
        postType: PostType.ecoAchievement,
        defaultPillars: [PostPillar.eco],
        category: TemplateCategory.ecoChallenge,
        icon: Icons.co2,
        color: const Color(0xFF2E7D32),
        placeholders: ['action', 'impact', 'easy_part', 'challenge', 'next_action', 'call_to_action'],
        variablePrompts: {
          'action': 'What action did you take to reduce your carbon footprint?',
          'impact': 'What impact do you think this had?',
          'easy_part': 'What was easier than you expected?',
          'challenge': 'What was challenging about it?',
          'next_action': 'What\'s your next eco-friendly goal?',
          'call_to_action': 'How can others join you in this effort?',
        },
      ),
    ];
  }

  static List<PostTemplate> getAllTemplates() {
    return [
      ...getWeeklyWinsTemplates(),
      ...getAchievementTemplates(),
      ...getProgressTemplates(),
      ...getNutritionTemplates(),
      ...getEcoTemplates(),
      ...getGratitudeTemplates(),
    ];
  }
}