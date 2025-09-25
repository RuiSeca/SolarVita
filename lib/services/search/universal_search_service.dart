import 'package:flutter/material.dart';

/// Universal search service that can search across different content types
class UniversalSearchService {
  static final UniversalSearchService _instance = UniversalSearchService._internal();
  factory UniversalSearchService() => _instance;
  UniversalSearchService._internal();

  /// Search across all content types
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final results = <SearchResult>[];

    // Search workouts
    results.addAll(await _searchWorkouts(query));

    // Search foods/meals
    results.addAll(await _searchFoods(query));

    // Search supporters/users
    results.addAll(await _searchSupporters(query));

    // Search eco tips
    results.addAll(await _searchEcoTips(query));

    // Sort by relevance score
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return results.take(20).toList(); // Limit to top 20 results
  }

  Future<List<SearchResult>> _searchWorkouts(String query) async {
    // TODO: Implement actual workout search
    // This would integrate with your workout database/service

    final mockWorkouts = [
      'Push-ups',
      'Pull-ups',
      'Squats',
      'Deadlifts',
      'Bench Press',
      'Running',
      'Cycling',
      'Yoga Flow',
      'HIIT Cardio',
      'Strength Training'
    ];

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    for (final workout in mockWorkouts) {
      if (workout.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: workout.toLowerCase().replaceAll(' ', '_'),
          title: workout,
          subtitle: 'Workout Exercise',
          type: SearchResultType.workout,
          relevanceScore: _calculateRelevance(workout, query),
          icon: Icons.fitness_center,
          onTap: () => _navigateToWorkout(workout),
        ));
      }
    }

    return results;
  }

  Future<List<SearchResult>> _searchFoods(String query) async {
    // TODO: Implement actual food search
    // This would integrate with Nutritionix API or your food database

    final mockFoods = [
      'Apple',
      'Banana',
      'Chicken Breast',
      'Salmon',
      'Brown Rice',
      'Quinoa',
      'Greek Yogurt',
      'Spinach',
      'Sweet Potato',
      'Avocado'
    ];

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    for (final food in mockFoods) {
      if (food.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: food.toLowerCase().replaceAll(' ', '_'),
          title: food,
          subtitle: 'Food Item',
          type: SearchResultType.food,
          relevanceScore: _calculateRelevance(food, query),
          icon: Icons.restaurant,
          onTap: () => _navigateToFood(food),
        ));
      }
    }

    return results;
  }

  Future<List<SearchResult>> _searchSupporters(String query) async {
    // TODO: Implement actual supporter search
    // This would integrate with your user/supporter service

    final mockSupporters = [
      'John Doe',
      'Jane Smith',
      'Mike Johnson',
      'Sarah Wilson',
      'David Brown'
    ];

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    for (final supporter in mockSupporters) {
      if (supporter.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: supporter.toLowerCase().replaceAll(' ', '_'),
          title: supporter,
          subtitle: 'Supporter',
          type: SearchResultType.supporter,
          relevanceScore: _calculateRelevance(supporter, query),
          icon: Icons.person,
          onTap: () => _navigateToSupporter(supporter),
        ));
      }
    }

    return results;
  }

  Future<List<SearchResult>> _searchEcoTips(String query) async {
    // TODO: Implement actual eco tips search

    final mockEcoTips = [
      'Reduce Carbon Footprint',
      'Save Water',
      'Sustainable Diet',
      'Eco-Friendly Transport',
      'Renewable Energy',
      'Reduce Plastic Waste',
      'Composting Tips',
      'Green Exercise',
      'Sustainable Shopping',
      'Energy Conservation'
    ];

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    for (final tip in mockEcoTips) {
      if (tip.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: tip.toLowerCase().replaceAll(' ', '_'),
          title: tip,
          subtitle: 'Eco Tip',
          type: SearchResultType.ecoTip,
          relevanceScore: _calculateRelevance(tip, query),
          icon: Icons.eco,
          onTap: () => _navigateToEcoTip(tip),
        ));
      }
    }

    return results;
  }

  double _calculateRelevance(String item, String query) {
    final lowerItem = item.toLowerCase();
    final lowerQuery = query.toLowerCase();

    // Exact match gets highest score
    if (lowerItem == lowerQuery) return 1.0;

    // Starts with query gets high score
    if (lowerItem.startsWith(lowerQuery)) return 0.8;

    // Contains query gets medium score
    if (lowerItem.contains(lowerQuery)) return 0.6;

    // Fuzzy matching could be added here
    return 0.0;
  }

  void _navigateToWorkout(String workout) {
    debugPrint('Navigate to workout: $workout');
    // TODO: Implement navigation to workout detail/start screen
  }

  void _navigateToFood(String food) {
    debugPrint('Navigate to food: $food');
    // TODO: Implement navigation to food detail/logging screen
  }

  void _navigateToSupporter(String supporter) {
    debugPrint('Navigate to supporter: $supporter');
    // TODO: Implement navigation to supporter profile
  }

  void _navigateToEcoTip(String tip) {
    debugPrint('Navigate to eco tip: $tip');
    // TODO: Implement navigation to eco tip detail
  }
}

/// Represents a search result item
class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final double relevanceScore;
  final IconData icon;
  final VoidCallback onTap;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.relevanceScore,
    required this.icon,
    required this.onTap,
  });
}

/// Types of search results
enum SearchResultType {
  workout,
  food,
  supporter,
  ecoTip,
}

/// Extension to get display colors for search result types
extension SearchResultTypeExtension on SearchResultType {
  Color get color {
    switch (this) {
      case SearchResultType.workout:
        return Colors.blue;
      case SearchResultType.food:
        return Colors.green;
      case SearchResultType.supporter:
        return Colors.purple;
      case SearchResultType.ecoTip:
        return Colors.teal;
    }
  }

  String get displayName {
    switch (this) {
      case SearchResultType.workout:
        return 'Workout';
      case SearchResultType.food:
        return 'Food';
      case SearchResultType.supporter:
        return 'Supporter';
      case SearchResultType.ecoTip:
        return 'Eco Tip';
    }
  }
}