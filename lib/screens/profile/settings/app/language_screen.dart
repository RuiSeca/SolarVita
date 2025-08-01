// lib/screens/profile/settings/app/language_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/riverpod/language_provider.dart';
import '../../../../theme/app_theme.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import '../../../../widgets/common/lottie_loading_widget.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageData = ref.watch(languageNotifierProvider);
    final languageNotifier = ref.read(languageNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          tr(context, 'language'),
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
      body: languageData.when(
        loading: () => const Center(child: LottieLoadingWidget()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (languageState) {
          final supportedLanguages = ref.watch(supportedLanguagesProvider);
          final currentLanguage = ref.watch(currentLanguageProvider);

          return Scrollbar(
            thumbVisibility: true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: supportedLanguages.length,
              itemBuilder: (context, index) {
              final language = supportedLanguages[index];
              final isSelected = language.code == currentLanguage.code;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (AppTheme.isDarkMode(context) 
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppTheme.textColor(context).withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: () => languageNotifier.setLanguage(language.code),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Text(
                    language.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    translateCountry(context, language.code),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 24,
                        )
                      : null,
                ),
              );
            },
            ),
          );
        },
      ),
    );
  }
}