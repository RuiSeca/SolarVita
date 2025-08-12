import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';

/// Currency purchase screen with real money options
class CurrencyPurchaseScreen extends ConsumerStatefulWidget {
  const CurrencyPurchaseScreen({super.key});

  @override
  ConsumerState<CurrencyPurchaseScreen> createState() => _CurrencyPurchaseScreenState();
}

class _CurrencyPurchaseScreenState extends ConsumerState<CurrencyPurchaseScreen> {
  bool _isLoading = false;
  String? _selectedPackage;
  
  // Currency packages with their real money prices and coin amounts
  final List<CurrencyPackage> _packages = [
    CurrencyPackage(
      id: 'small',
      title: 'Small Pack',
      coins: 100,
      price: 3.0,
      currencySymbol: '£',
      description: 'Perfect for getting started',
      color: Colors.blue,
      popular: false,
    ),
    CurrencyPackage(
      id: 'medium',
      title: 'Medium Pack',
      coins: 350,
      price: 10.0,
      currencySymbol: '£',
      description: 'Great value for regular users',
      color: Colors.green,
      popular: false,
    ),
    CurrencyPackage(
      id: 'large',
      title: 'Large Pack',
      coins: 900,
      price: 25.0,
      currencySymbol: '£',
      description: 'Best value - 10% bonus coins!',
      color: Colors.orange,
      popular: true,
    ),
    CurrencyPackage(
      id: 'mega',
      title: 'Mega Pack',
      coins: 1300,
      price: 35.0,
      currencySymbol: '£',
      description: 'Premium pack with 15% bonus!',
      color: Colors.purple,
      popular: false,
    ),
    CurrencyPackage(
      id: 'ultimate',
      title: 'Ultimate Pack',
      coins: 2000,
      price: 50.0,
      currencySymbol: '£',
      description: 'Maximum value - 25% bonus coins!',
      color: Colors.red,
      popular: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildPackageGrid()),
            SliverToBoxAdapter(child: _buildPaymentInfo()),
            SliverToBoxAdapter(child: const SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.9),
                AppColors.secondary.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.gold, Colors.amber.shade700],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buy Coins',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Unlock avatar customizations',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'About Solar Coins',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Solar Coins are the primary currency for purchasing avatar customizations and exclusive content. Earn coins through daily goals or purchase them to unlock premium features instantly.',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Package',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _packages.length,
            itemBuilder: (context, index) {
              final package = _packages[index];
              final isSelected = _selectedPackage == package.id;
              
              return GestureDetector(
                onTap: () => _selectPackage(package.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        package.color.withValues(alpha: isSelected ? 0.2 : 0.1),
                        package.color.withValues(alpha: isSelected ? 0.1 : 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? package.color 
                          : package.color.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected 
                        ? [
                            BoxShadow(
                              color: package.color.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (package.popular)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.red],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: package.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.monetization_on,
                                color: package.color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              package.title,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '🪙',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${package.coins}',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              package.description,
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${package.currencySymbol}${package.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: package.color,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    if (_selectedPackage == null) return const SizedBox.shrink();
    
    final selectedPack = _packages.firstWhere((p) => p.id == _selectedPackage);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Purchase Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Package',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      selectedPack.title,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Coins',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '${selectedPack.coins}',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${selectedPack.currencySymbol}${selectedPack.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: selectedPack.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Purchase Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [selectedPack.color, selectedPack.color.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: selectedPack.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _handlePurchase(selectedPack),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Purchase ${selectedPack.currencySymbol}${selectedPack.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment Methods Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Secure Payment',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPaymentMethod('💳', 'Card'),
                    const SizedBox(width: 16),
                    _buildPaymentMethod('📱', 'Apple Pay'),
                    const SizedBox(width: 16),
                    _buildPaymentMethod('🟢', 'Google Pay'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Payments are processed securely through the app store',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(String emoji, String name) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _selectPackage(String packageId) {
    setState(() {
      _selectedPackage = packageId;
    });
  }

  Future<void> _handlePurchase(CurrencyPackage package) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual payment processing
      // This would integrate with app store payment systems
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing
      
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: Text(
              'Purchase Successful!',
              style: TextStyle(color: AppColors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🪙',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  'You received ${package.coins} coins!',
                  style: TextStyle(color: AppColors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close purchase screen
                },
                child: Text(
                  'Awesome!',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: Text(
              'Purchase Failed',
              style: TextStyle(color: Colors.red),
            ),
            content: Text(
              'Unable to process payment. Please try again.',
              style: TextStyle(color: AppColors.white.withValues(alpha: 0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
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
}

/// Currency package model
class CurrencyPackage {
  final String id;
  final String title;
  final int coins;
  final double price;
  final String currencySymbol;
  final String description;
  final Color color;
  final bool popular;

  const CurrencyPackage({
    required this.id,
    required this.title,
    required this.coins,
    required this.price,
    required this.currencySymbol,
    required this.description,
    required this.color,
    this.popular = false,
  });
}