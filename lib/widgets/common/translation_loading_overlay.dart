import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class TranslationLoadingOverlay extends StatefulWidget {
  final String language;
  final String category;
  final int totalItems;
  final int translatedItems;
  final bool isVisible;
  final VoidCallback? onCancel;

  const TranslationLoadingOverlay({
    super.key,
    required this.language,
    required this.category,
    required this.totalItems,
    required this.translatedItems,
    required this.isVisible,
    this.onCancel,
  });

  @override
  State<TranslationLoadingOverlay> createState() => _TranslationLoadingOverlayState();
}

class _TranslationLoadingOverlayState extends State<TranslationLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.isVisible) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(TranslationLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final progress = widget.totalItems > 0 ? widget.translatedItems / widget.totalItems : 0.0;

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        color: Colors.black.withAlpha(128),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading icon with rotation
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * 3.14159,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.translate,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  tr(context, 'downloading_translations'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle with language and category
                Text(
                  '${_getLanguageDisplayName(widget.language)} • ${widget.category}',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Progress bar
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.textColor(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Progress text
                Text(
                  '${widget.translatedItems} / ${widget.totalItems} ${tr(context, 'meals').toLowerCase()}',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Cancel button (optional)
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textColor(context).withAlpha(179),
                    ),
                    child: Text(tr(context, 'cancel')),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'pt':
        return 'Português';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'ru':
        return 'Русский';
      case 'hi':
        return 'हिन्दी';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'zh':
        return '中文';
      default:
        return languageCode.toUpperCase();
    }
  }
}