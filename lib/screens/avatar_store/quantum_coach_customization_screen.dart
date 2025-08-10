import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/avatar_customization.dart';
import '../../services/store/avatar_customization_service.dart';

class QuantumCoachCustomizationScreen extends ConsumerStatefulWidget {
  const QuantumCoachCustomizationScreen({super.key});

  @override
  ConsumerState<QuantumCoachCustomizationScreen> createState() => 
      _QuantumCoachCustomizationScreenState();
}

class _QuantumCoachCustomizationScreenState 
    extends ConsumerState<QuantumCoachCustomizationScreen> {
  final AvatarCustomizationService _customizationService = AvatarCustomizationService();
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _customizationService.initialize();
    } catch (e) {
      debugPrint('Error initializing customization service: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCustomizations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // The customization widget automatically saves changes through the service
      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'customization_saved')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving customizations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'reset_customizations')),
        content: Text(tr(context, 'reset_customizations_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr(context, 'reset')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _customizationService.resetCustomizations('quantum_coach');
        setState(() {
          _hasUnsavedChanges = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'customizations_reset')),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Trigger rebuild of customization widget
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting customizations: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'avatar_quantum_coach_name')),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        actions: [
          // Reset button
          IconButton(
            onPressed: _isLoading ? null : _resetToDefaults,
            icon: const Icon(Icons.restore),
            tooltip: tr(context, 'reset_customizations'),
          ),
          // Save indicator
          if (_hasUnsavedChanges)
            IconButton(
              onPressed: _isLoading ? null : _saveCustomizations,
              icon: const Icon(Icons.save),
              tooltip: tr(context, 'save_customizations'),
            ),
        ],
      ),
      backgroundColor: AppTheme.surfaceColor(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade800, Colors.purple.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.psychology,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr(context, 'avatar_quantum_coach_name'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    tr(context, 'customize_your_quantum_coach'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Warning about missing assets
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asset Status Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Some clothing assets may not display due to missing image files. Working customizations will function normally.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textColor(context).withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Customization Widget
                  AvatarCustomization(
                    avatarId: 'quantum_coach',
                    width: double.infinity,
                    height: 300,
                    onCustomizationChanged: () {
                      setState(() {
                        _hasUnsavedChanges = true;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Usage Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.help_outline, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'How to Customize',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionItem('👁️', 'Eyes: Adjust eye color and effects'),
                          _buildInstructionItem('🧑', 'Skin: Change skin tone and texture'),
                          _buildInstructionItem('👕', 'Clothing: Toggle outfits and accessories'),
                          _buildInstructionItem('💇', 'Hair: Modify hairstyle options'),
                          _buildInstructionItem('💎', 'Accessories: Add jewelry and extras'),
                          const SizedBox(height: 12),
                          Text(
                            '⚠️ Items marked as "Missing Assets" have working controls but may not show visual changes due to missing image files in the RIVE animation.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textColor(context).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer note
                  Center(
                    child: Text(
                      'Customizations are automatically saved',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInstructionItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor(context).withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}