import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/enhanced_avatar_customization.dart';
import '../../services/store/avatar_customization_service.dart';

class EnhancedQuantumCoachScreen extends ConsumerStatefulWidget {
  const EnhancedQuantumCoachScreen({super.key});

  @override
  ConsumerState<EnhancedQuantumCoachScreen> createState() =>
      _EnhancedQuantumCoachScreenState();
}

class _EnhancedQuantumCoachScreenState
    extends ConsumerState<EnhancedQuantumCoachScreen>
    with TickerProviderStateMixin {
  final AvatarCustomizationService _customizationService =
      AvatarCustomizationService();
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  // bool _hasUnsavedChanges = false; // Removed unused field
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
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

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('Reset All Customizations'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will reset all customizations to default values:'),
            const SizedBox(height: 12),
            _buildResetItem('👁️', 'Eyes → Default Eyes'),
            _buildResetItem('😊', 'Face → Playful Expression'),
            _buildResetItem('🎨', 'Skin → Medium Tone'),
            _buildResetItem('👕', 'Clothing → Default Outfit'),
            _buildResetItem('💎', 'Accessories → None'),
            _buildResetItem('⚙️', 'States → Default Values'),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All'),
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
        // Customizations reset successfully

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('All customizations reset to defaults!'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Trigger rebuild
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Error resetting: $e'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
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

  Widget _buildResetItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 16),
                  Text(
                    'Initializing Quantum Coach...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Animated Header
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: AnimatedBuilder(
                      animation: _headerAnimationController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.purple.shade800.withValues(
                                  alpha: 0.9 * _headerAnimationController.value,
                                ),
                                Colors.blue.shade900.withValues(
                                  alpha: 0.9 * _headerAnimationController.value,
                                ),
                                Colors.black.withValues(
                                  alpha: 0.7 * _headerAnimationController.value,
                                ),
                              ],
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  20 * (1 - _headerAnimationController.value),
                                ),
                                child: Opacity(
                                  opacity: _headerAnimationController.value,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.purple,
                                              Colors.blue,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.purple.withValues(
                                                alpha: 0.4,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.psychology,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Quantum Coach Studio',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Advanced AI Customization Laboratory',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reset All Customizations',
                    ),
                  ],
                ),

                // Feature Highlights
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _cardAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          30 * (1 - _cardAnimationController.value),
                        ),
                        child: Opacity(
                          opacity: _cardAnimationController.value,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.purple.shade900.withValues(alpha: 0.3),
                                  Colors.blue.shade900.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.purple.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Professional Features',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildFeatureChip('👁️ 13 Eye Options'),
                                    _buildFeatureChip('😊 5 Face Expressions'),
                                    _buildFeatureChip('🎨 5 Skin Tones'),
                                    _buildFeatureChip('👕 Dynamic Clothing'),
                                    _buildFeatureChip('💎 6 Accessories'),
                                    _buildFeatureChip('🎭 Interactive Touch'),
                                    _buildFeatureChip('🏆 Celebrations'),
                                    _buildFeatureChip('⚙️ State Controls'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Main Customization Widget
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _cardAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          40 * (1 - _cardAnimationController.value),
                        ),
                        child: Opacity(
                          opacity: _cardAnimationController.value,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: EnhancedAvatarCustomization(
                              width: MediaQuery.of(context).size.width - 64,
                              height: 300,
                              showActionsTab: false,
                              showStatesTab: false,
                              enableAutoSave: true,
                              onCustomizationChanged: () {
                                // Customization changes are auto-saved
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Status Footer
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Systems Operational',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Customizations auto-save • 153 animations loaded • Interactive touch enabled',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
