// lib/utils/template_localization.dart
import 'package:flutter/material.dart';
import '../models/posts/post_template.dart';
import 'translation_helper.dart';

class TemplateLocalization {
  static PostTemplate localizeTemplate(
    BuildContext context,
    PostTemplate template,
  ) {
    return PostTemplate(
      id: template.id,
      title: _getLocalizedTitle(context, template.id, template.title),
      description: _getLocalizedDescription(
        context,
        template.id,
        template.description,
      ),
      promptText: _getLocalizedPromptText(
        context,
        template.id,
        template.promptText,
      ),
      suggestedContent: _getLocalizedSuggestedContent(
        context,
        template.id,
        template.suggestedContent,
      ),
      postType: template.postType,
      defaultPillars: template.defaultPillars,
      category: template.category,
      icon: template.icon,
      color: template.color,
      placeholders: template.placeholders,
      variablePrompts: _getLocalizedVariablePrompts(
        context,
        template.id,
        template.variablePrompts,
      ),
    );
  }

  static String _getLocalizedTitle(
    BuildContext context,
    String templateId,
    String fallbackTitle,
  ) {
    switch (templateId) {
      case 'weekly_wins_fitness':
        return tr(context, 'fitness_wins');
      case 'weekly_wins_nutrition':
        return tr(context, 'nutrition_wins');
      case 'weekly_wins_eco':
        return tr(context, 'eco_wins');
      case 'weekly_wins_mindful':
        return tr(context, 'mindfulness_wins');
      case 'milestone_weight_loss':
        return tr(context, 'weight_loss_milestone');
      case 'first_race':
        return tr(context, 'first_race_completion');
      case 'habit_streak':
        return tr(context, 'habit_streak');
      case 'daily_gratitude':
        return tr(context, 'daily_gratitude');
      case 'progress_before_after':
        return tr(context, 'before_after_progress');
      case 'strength_pr':
        return tr(context, 'personal_record');
      case 'recipe_share':
        return tr(context, 'healthy_recipe_share');
      case 'nutrition_challenge':
        return tr(context, 'nutrition_challenge_complete');
      case 'sustainable_swap':
        return tr(context, 'sustainable_product_swap');
      case 'carbon_reduction':
        return tr(context, 'carbon_footprint_reduction');
      default:
        return fallbackTitle;
    }
  }

  static String _getLocalizedDescription(
    BuildContext context,
    String templateId,
    String fallbackDescription,
  ) {
    switch (templateId) {
      case 'weekly_wins_fitness':
        return tr(context, 'fitness_wins_desc');
      case 'weekly_wins_nutrition':
        return tr(context, 'nutrition_wins_desc');
      case 'weekly_wins_eco':
        return tr(context, 'eco_wins_desc');
      case 'weekly_wins_mindful':
        return tr(context, 'mindfulness_wins_desc');
      case 'milestone_weight_loss':
        return tr(context, 'weight_loss_milestone_desc');
      case 'first_race':
        return tr(context, 'first_race_completion_desc');
      case 'habit_streak':
        return tr(context, 'habit_streak_desc');
      case 'daily_gratitude':
        return tr(context, 'daily_gratitude_desc');
      case 'progress_before_after':
        return tr(context, 'before_after_progress_desc');
      case 'strength_pr':
        return tr(context, 'personal_record_desc');
      case 'recipe_share':
        return tr(context, 'healthy_recipe_share_desc');
      case 'nutrition_challenge':
        return tr(context, 'nutrition_challenge_complete_desc');
      case 'sustainable_swap':
        return tr(context, 'sustainable_product_swap_desc');
      case 'carbon_reduction':
        return tr(context, 'carbon_footprint_reduction_desc');
      default:
        return fallbackDescription;
    }
  }

  static String _getLocalizedPromptText(
    BuildContext context,
    String templateId,
    String fallbackPromptText,
  ) {
    switch (templateId) {
      case 'weekly_wins_fitness':
        return tr(context, 'prompt_fitness_weekly');
      case 'weekly_wins_nutrition':
        return tr(context, 'prompt_nutrition_weekly');
      case 'weekly_wins_eco':
        return tr(context, 'prompt_eco_weekly');
      case 'weekly_wins_mindful':
        return tr(context, 'prompt_mindfulness_weekly');
      case 'milestone_weight_loss':
        return tr(context, 'prompt_weight_loss');
      case 'first_race':
        return tr(context, 'prompt_first_race');
      case 'habit_streak':
        return tr(context, 'prompt_habit_streak');
      case 'daily_gratitude':
        return tr(context, 'prompt_daily_gratitude');
      case 'progress_before_after':
        return tr(context, 'prompt_progress_photos');
      case 'strength_pr':
        return tr(context, 'prompt_personal_record');
      case 'recipe_share':
        return tr(context, 'prompt_recipe_share');
      case 'nutrition_challenge':
        return tr(context, 'prompt_nutrition_challenge');
      case 'sustainable_swap':
        return tr(context, 'prompt_sustainable_swap');
      case 'carbon_reduction':
        return tr(context, 'prompt_carbon_reduction');
      default:
        return fallbackPromptText;
    }
  }

  static List<String> _getLocalizedSuggestedContent(
    BuildContext context,
    String templateId,
    List<String> fallbackContent,
  ) {
    switch (templateId) {
      case 'weekly_wins_fitness':
        return [
          tr(context, 'suggestion_first_5k'),
          tr(context, 'suggestion_gym_4_times'),
          tr(context, 'suggestion_new_workout'),
          tr(context, 'suggestion_increased_weights'),
          tr(context, 'suggestion_improved_form'),
        ];
      case 'weekly_wins_nutrition':
        return [
          tr(context, 'suggestion_meal_prepped'),
          tr(context, 'suggestion_healthy_recipes'),
          tr(context, 'suggestion_water_daily'),
          tr(context, 'suggestion_less_processed'),
          tr(context, 'suggestion_more_vegetables'),
        ];
      case 'weekly_wins_eco':
        return [
          tr(context, 'suggestion_reusable_bags'),
          tr(context, 'suggestion_biked_work'),
          tr(context, 'suggestion_started_composting'),
          tr(context, 'suggestion_reduced_plastic'),
          tr(context, 'suggestion_planted_herbs'),
        ];
      case 'weekly_wins_mindful':
        return [
          tr(context, 'suggestion_meditated_daily'),
          tr(context, 'suggestion_gratitude_journal'),
          tr(context, 'suggestion_mindful_walks'),
          tr(context, 'suggestion_breathing_exercises'),
          tr(context, 'suggestion_disconnected_social'),
        ];
      case 'daily_gratitude':
        return [
          tr(context, 'suggestion_gratitude_health'),
          tr(context, 'suggestion_gratitude_family'),
          tr(context, 'suggestion_gratitude_food'),
          tr(context, 'suggestion_gratitude_movement'),
          tr(context, 'suggestion_gratitude_nature'),
        ];
      default:
        return fallbackContent;
    }
  }

  static Map<String, String> _getLocalizedVariablePrompts(
    BuildContext context,
    String templateId,
    Map<String, String> fallbackPrompts,
  ) {
    switch (templateId) {
      case 'weekly_wins_fitness':
        return {
          'achievement': tr(context, 'question_biggest_fitness_win'),
          'details': tr(context, 'question_what_made_special'),
          'next_goal': tr(context, 'question_aiming_next_week'),
        };
      case 'weekly_wins_nutrition':
        return {
          'achievement': tr(context, 'question_biggest_nutrition_win'),
          'feeling': tr(context, 'question_how_did_feel'),
          'tip': tr(context, 'question_tip_for_others'),
        };
      case 'weekly_wins_eco':
        return {
          'achievement': tr(context, 'question_eco_action'),
          'impact': tr(context, 'question_impact_think'),
          'inspiration': tr(context, 'question_inspire_others'),
        };
      case 'weekly_wins_mindful':
        return {
          'practice': tr(context, 'question_mindfulness_practice'),
          'insight': tr(context, 'question_insight_gained'),
          'gratitude': tr(context, 'question_grateful_for'),
        };
      case 'milestone_weight_loss':
        return {
          'amount': tr(context, 'question_weight_lost'),
          'unit': tr(context, 'question_weight_unit'),
          'journey': tr(context, 'question_journey_time'),
          'motivation': tr(context, 'question_motivation'),
          'next_goal': tr(context, 'question_next_milestone'),
        };
      case 'first_race':
        return {
          'race_type': tr(context, 'question_race_type'),
          'time': tr(context, 'question_finish_time'),
          'emotion': tr(context, 'question_feeling_now'),
          'challenge': tr(context, 'question_biggest_challenge'),
          'proud_moment': tr(context, 'question_proudest_moment'),
          'advice': tr(context, 'question_advice_others'),
        };
      case 'habit_streak':
        return {
          'streak_days': tr(context, 'question_streak_days'),
          'habit': tr(context, 'question_habit_tracking'),
          'start_story': tr(context, 'question_habit_started'),
          'current_feeling': tr(context, 'question_current_feeling'),
          'tips': tr(context, 'question_success_tips'),
          'next_milestone': tr(context, 'question_next_milestone'),
        };
      case 'daily_gratitude':
        return {
          'gratitude_1': tr(context, 'question_gratitude_1'),
          'gratitude_2': tr(context, 'question_gratitude_2'),
          'gratitude_3': tr(context, 'question_gratitude_3'),
          'reason': tr(context, 'question_why_meaningful'),
          'call_to_action': tr(context, 'question_call_to_action'),
        };
      case 'progress_before_after':
        return {
          'timeframe': tr(context, 'question_timeframe'),
          'changes': tr(context, 'question_changes_notice'),
          'challenge': tr(context, 'question_hardest_part'),
          'highlight': tr(context, 'question_highlight'),
          'encouragement': tr(context, 'question_encouragement'),
        };
      case 'strength_pr':
        return {
          'exercise': tr(context, 'question_exercise'),
          'new_record': tr(context, 'question_new_record'),
          'old_record': tr(context, 'question_old_record'),
          'feeling': tr(context, 'question_pr_feeling'),
          'success_factor': tr(context, 'question_success_factor'),
          'next_goal': tr(context, 'question_next_pr_goal'),
        };
      case 'recipe_share':
        return {
          'recipe_name': tr(context, 'question_recipe_name'),
          'why_love': tr(context, 'question_why_love_recipe'),
          'ingredients': tr(context, 'question_key_ingredients'),
          'prep_time': tr(context, 'question_prep_time'),
          'nutrition': tr(context, 'question_nutrition_highlight'),
          'cooking_tip': tr(context, 'question_cooking_tip'),
        };
      case 'nutrition_challenge':
        return {
          'challenge_name': tr(context, 'question_challenge_name'),
          'duration': tr(context, 'question_challenge_duration'),
          'change': tr(context, 'question_biggest_change'),
          'benefit': tr(context, 'question_unexpected_benefit'),
          'would_repeat': tr(context, 'question_would_repeat'),
          'advice': tr(context, 'question_advice_starting'),
        };
      case 'sustainable_swap':
        return {
          'product_name': tr(context, 'question_product_name'),
          'old_product': tr(context, 'question_old_product'),
          'reason': tr(context, 'question_switch_reason'),
          'difference': tr(context, 'question_product_difference'),
          'cost': tr(context, 'question_cost_comparison'),
          'recommendation': tr(context, 'question_recommendation'),
        };
      case 'carbon_reduction':
        return {
          'action': tr(context, 'question_carbon_action'),
          'impact': tr(context, 'question_carbon_impact'),
          'easy_part': tr(context, 'question_easy_part'),
          'challenge': tr(context, 'question_carbon_challenge'),
          'next_action': tr(context, 'question_next_eco_action'),
          'call_to_action': tr(context, 'question_eco_call_to_action'),
        };
      default:
        return fallbackPrompts;
    }
  }

  static List<PostTemplate> getLocalizedTemplates(
    BuildContext context,
    List<PostTemplate> templates,
  ) {
    return templates
        .map((template) => localizeTemplate(context, template))
        .toList();
  }
}
