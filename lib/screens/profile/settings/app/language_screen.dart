// lib/screens/profile/settings/app/language_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/language_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'Language',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: languageProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: languageProvider.supportedLanguages.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Colors.grey,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final language = languageProvider.supportedLanguages[index];
                    final isSelected =
                        language.code == languageProvider.currentCode;

                    return ListTile(
                      onTap: () {
                        languageProvider.setLanguage(language.code);
                      },
                      leading: Text(
                        language.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        language.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 20,
                            )
                          : null,
                    );
                  },
                ),
        );
      },
    );
  }
}
