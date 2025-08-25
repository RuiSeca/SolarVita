import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/translation/firebase_translation_provider.dart';
import '../../utils/translation_helper.dart';

/// Widget that displays Firebase-translated text with fallbacks
class FirebaseTranslationText extends ConsumerWidget {
  final String translationKey;
  final String? fallbackText;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Map<String, String>? parameters;

  const FirebaseTranslationText(
    this.translationKey, {
    super.key,
    this.fallbackText,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.parameters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    
    // Try to get Firebase translation first
    final firebaseTranslation = ref.watch(translationProvider(TranslationParams(
      key: translationKey,
      languageCode: languageCode,
      fallback: null,
    )));

    // Fallback to local translations
    String displayText = firebaseTranslation;
    if (displayText == translationKey) {
      // Firebase translation not found, try local translation
      displayText = fallbackText ?? tr(context, translationKey);
    }

    // Apply parameters if provided
    if (parameters != null) {
      for (final entry in parameters!.entries) {
        displayText = displayText.replaceAll('{${entry.key}}', entry.value);
      }
    }

    return Text(
      displayText,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Widget that displays localized avatar information
class LocalizedAvatarInfo extends ConsumerWidget {
  final String avatarId;
  final AvatarInfoType infoType;
  final TextStyle? style;
  final String? fallback;

  const LocalizedAvatarInfo({
    super.key,
    required this.avatarId,
    required this.infoType,
    this.style,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    
    final avatarData = ref.watch(localizedAvatarProvider(LocalizedAvatarParams(
      avatarId: avatarId,
      languageCode: languageCode,
    )));

    String displayText = fallback ?? avatarId;
    
    if (avatarData != null) {
      switch (infoType) {
        case AvatarInfoType.name:
          displayText = avatarData.name;
          break;
        case AvatarInfoType.description:
          displayText = avatarData.description;
          break;
        case AvatarInfoType.personality:
          displayText = avatarData.personality;
          break;
        case AvatarInfoType.speciality:
          displayText = avatarData.speciality;
          break;
      }
    }

    return Text(
      displayText,
      style: style,
    );
  }
}

/// Widget for managing translation updates (admin/developer use)
class TranslationManager extends ConsumerStatefulWidget {
  const TranslationManager({super.key});

  @override
  ConsumerState<TranslationManager> createState() => _TranslationManagerState();
}

class _TranslationManagerState extends ConsumerState<TranslationManager> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  String _selectedLanguage = 'en';

  final List<String> _supportedLanguages = [
    'en', 'de', 'es', 'fr', 'hi', 'it', 'ja', 'ko', 'pt', 'ru', 'zh'
  ];

  @override
  Widget build(BuildContext context) {
    final translationService = ref.watch(firebaseTranslationServiceProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Translation Manager',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: _supportedLanguages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Translation Key',
                border: OutlineInputBorder(),
                hintText: 'e.g., avatar_description_quantum',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Translation Value',
                border: OutlineInputBorder(),
                hintText: 'Enter the translated text...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (_keyController.text.isNotEmpty && _valueController.text.isNotEmpty) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        await translationService.setTranslation(
                          _selectedLanguage,
                          _keyController.text.trim(),
                          _valueController.text.trim(),
                        );
                        
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Translation saved successfully')),
                          );
                        }
                        
                        _keyController.clear();
                        _valueController.clear();
                      } catch (e) {
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Error saving translation: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Save Translation'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    _keyController.clear();
                    _valueController.clear();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}

/// Type of avatar information to display
enum AvatarInfoType {
  name,
  description,
  personality,
  speciality,
}

/// Helper function to get Firebase translation with fallback
String trFirebase(BuildContext context, WidgetRef ref, String key, {String? fallback}) {
  final languageCode = Localizations.localeOf(context).languageCode;
  
  final firebaseTranslation = ref.read(translationProvider(TranslationParams(
    key: key,
    languageCode: languageCode,
    fallback: null,
  )));

  if (firebaseTranslation != key) {
    return firebaseTranslation;
  }

  return fallback ?? tr(context, key);
}