import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../../../../providers/riverpod/user_profile_provider.dart';
import '../../../../widgets/common/lottie_loading_widget.dart';
import '../../../../services/dashboard/dashboard_image_service.dart';
import '../../../onboarding/models/onboarding_models.dart' show IntentType, IntentOption;
import '../../../onboarding/components/animated_waves.dart' show WavePersonality;

class PersonalIntentPreferencesScreen extends ConsumerStatefulWidget {
  const PersonalIntentPreferencesScreen({super.key});

  @override
  ConsumerState<PersonalIntentPreferencesScreen> createState() =>
      _PersonalIntentPreferencesScreenState();
}

class _PersonalIntentPreferencesScreenState
    extends ConsumerState<PersonalIntentPreferencesScreen> {
  bool _isLoading = false;
  Set<IntentType> _selectedIntents = {};
  bool _hasChanges = false;

  List<IntentOption> get intentOptions => [
    IntentOption(
      type: IntentType.eco,
      icon: Icons.eco,
      label: tr(context, 'intent_eco_label'),
      description: tr(context, 'intent_eco_description'),
      wavePersonality: WavePersonality.eco,
    ),
    IntentOption(
      type: IntentType.fitness,
      icon: Icons.fitness_center,
      label: tr(context, 'intent_fitness_label'),
      description: tr(context, 'intent_fitness_description'),
      wavePersonality: WavePersonality.fitness,
    ),
    IntentOption(
      type: IntentType.nutrition,
      icon: Icons.restaurant,
      label: tr(context, 'intent_nutrition_label'),
      description: tr(context, 'intent_nutrition_description'),
      wavePersonality: WavePersonality.wellness,
    ),
    IntentOption(
      type: IntentType.community,
      icon: Icons.people,
      label: tr(context, 'intent_community_label'),
      description: tr(context, 'intent_community_description'),
      wavePersonality: WavePersonality.community,
    ),
    IntentOption(
      type: IntentType.mindfulness,
      icon: Icons.self_improvement,
      label: tr(context, 'intent_mindfulness_label'),
      description: tr(context, 'intent_mindfulness_description'),
      wavePersonality: WavePersonality.mindfulness,
    ),
    IntentOption(
      type: IntentType.adventure,
      icon: Icons.terrain,
      label: tr(context, 'intent_adventure_label'),
      description: tr(context, 'intent_adventure_description'),
      wavePersonality: WavePersonality.adventure,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserIntents();
    });
  }

  void _loadUserIntents() {
    final userProfile = ref.read(userProfileNotifierProvider).value;
    if (userProfile != null && userProfile.selectedIntents.isNotEmpty) {
      setState(() {
        _selectedIntents = Set.from(userProfile.selectedIntents);
      });
    }
  }

  void _onIntentTapped(IntentType intent) {
    setState(() {
      if (_selectedIntents.contains(intent)) {
        _selectedIntents.remove(intent);
      } else {
        _selectedIntents.add(intent);
      }
      _hasChanges = true;
    });
  }

  Future<void> _savePreferences() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Clear image cache BEFORE updating preferences to prevent stale data
      await DashboardImageService.clearCacheOnPreferenceChange();

      // Update the user preferences
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updatePersonalIntents(_selectedIntents);

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'personal_intents_updated')),
            backgroundColor: AppColors.primary,
            action: SnackBarAction(
              label: tr(context, 'dashboard_will_update'),
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_updating_preferences').replaceAll('{error}', '$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          tr(context, 'personal_intents'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textColor(context).withAlpha(26),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr(context, 'customize_your_experience'),
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(context, 'personal_intents_description'),
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (_selectedIntents.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_selectedIntents.length} ${_selectedIntents.length == 1 ? tr(context, 'intent_selected_singular') : tr(context, 'intent_selected_plural')}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Intent Options Grid
                Text(
                  tr(context, 'select_your_intents'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: intentOptions.length,
                  itemBuilder: (context, index) {
                    final option = intentOptions[index];
                    final isSelected = _selectedIntents.contains(option.type);

                    return GestureDetector(
                      onTap: () => _onIntentTapped(option.type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? option.color.withAlpha(25)
                              : AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? option.color
                                : AppTheme.textColor(context).withAlpha(26),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: option.color.withAlpha(51),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? option.color
                                    : AppTheme.textColor(context).withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                option.icon,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textColor(context).withAlpha(153),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              option.label,
                              style: TextStyle(
                                color: isSelected
                                    ? option.color
                                    : AppTheme.textColor(context),
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.description,
                              style: TextStyle(
                                color: isSelected
                                    ? option.color.withAlpha(179)
                                    : AppTheme.textColor(context).withAlpha(128),
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: LottieLoadingWidget(),
              ),
            ),
        ],
      ),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _savePreferences,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(tr(context, 'save_changes')),
            )
          : null,
    );
  }
}