// lib/screens/profile/settings/app/language_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../theme/app_theme.dart';
import 'package:solar_vitas/utils/translation_helper.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
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
          body: languageProvider.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: languageProvider.supportedLanguages.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppTheme.textColor(context).withValues(alpha: 26),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final language = languageProvider.supportedLanguages[index];
                        final isSelected =
                            language.code == languageProvider.locale.languageCode;

                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.primary.withValues(alpha: 26)
                                : Colors.transparent,
                            borderRadius: index == 0
                                ? const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  )
                                : index == languageProvider.supportedLanguages.length - 1
                                    ? const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      )
                                    : BorderRadius.zero,
                          ),
                          child: ListTile(
                            onTap: () {
                              languageProvider.setLanguage(language.code);
                            },
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.textFieldBackground(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  language.flag,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
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
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }
}
