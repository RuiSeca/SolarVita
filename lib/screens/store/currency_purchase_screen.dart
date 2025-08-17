import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../models/store/currency_package.dart';
import '../../services/payment_service.dart';
import '../../utils/translation_helper.dart';

/// Currency purchase screen with real money options
class CurrencyPurchaseScreen extends ConsumerStatefulWidget {
  const CurrencyPurchaseScreen({super.key});

  @override
  ConsumerState<CurrencyPurchaseScreen> createState() => _CurrencyPurchaseScreenState();
}

class _CurrencyPurchaseScreenState extends ConsumerState<CurrencyPurchaseScreen> {
  String? _selectedPackage;
  late PaymentService _paymentService;
  bool _isApplePayAvailable = false;
  bool _isGooglePayAvailable = false;
  
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
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _initializePaymentService();
  }

  Future<void> _initializePaymentService() async {
    await _paymentService.initialize();
    
    // Check payment method availability
    if (Platform.isIOS) {
      _isApplePayAvailable = await PaymentService.isApplePayAvailable();
    }
    if (Platform.isAndroid) {
      _isGooglePayAvailable = await PaymentService.isGooglePayAvailable();
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildPackageGrid()),
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
      foregroundColor: AppTheme.textColor(context),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
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
                AppTheme.surfaceColor(context).withValues(alpha: 0.8),
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
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: AppTheme.textColor(context),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(context, 'purchase_screen_title'),
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            tr(context, 'purchase_screen_subtitle'),
                            style: TextStyle(
                              color: AppTheme.textColor(context).withValues(alpha: 0.8),
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
                tr(context, 'purchase_about_title'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr(context, 'purchase_about_description'),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.8),
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
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                tr(context, 'purchase_choose_package'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'purchase_packages_subtitle'),
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
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
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? package.color
                        : AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white 
                          : AppColors.primary,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? package.color.withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.2),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      
                      // Popular badge
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
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tr(context, 'purchase_popular'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      
                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Package icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : package.color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: isSelected ? package.color : Colors.white,
                                size: 20,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Package title
                            Text(
                              tr(context, 'purchase_package_${package.id}'),
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textColor(context),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 6),
                            
                            // Coin count
                            Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: AppColors.gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${package.coins} coins',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            
                            const Spacer(),
                            
                            // Description
                            Text(
                              tr(context, 'purchase_description_${package.id}'),
                              style: TextStyle(
                                color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppTheme.textColor(context).withValues(alpha: 0.7),
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Price
                            Text(
                              '${package.currencySymbol}${package.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : package.color,
                                fontSize: 16,
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


  void _selectPackage(String packageId) {
    setState(() {
      _selectedPackage = packageId;
    });
    
    // Trigger immediate purchase flow for better engagement
    final selectedPackage = _packages.firstWhere((p) => p.id == packageId);
    _showPurchaseConfirmation(selectedPackage);
  }
  
  void _showPurchaseConfirmation(CurrencyPackage package) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: package.color,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: package.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Package title
              Text(
                tr(context, 'purchase_package_${package.id}'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Coin info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${package.coins} COINS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                tr(context, 'purchase_description_${package.id}'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Price display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: package.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: package.color,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${package.currencySymbol}${package.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: package.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.textColor(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.textColor(context).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          tr(context, 'purchase_cancel_button'),
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Purchase button
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: package.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _handlePurchase(package);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: AppColors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tr(context, 'purchase_buy_button'),
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(CurrencyPackage package) async {
    try {
      // Show payment method selection dialog
      final paymentMethod = await _showPaymentMethodDialog();
      
      if (paymentMethod == null) {
        return;
      }

      PaymentResult result;
      
      switch (paymentMethod) {
        case 'apple_pay':
          if (!mounted) return;
          result = await _paymentService.processApplePayPayment(context, package);
          break;
        case 'google_pay':
          if (!mounted) return;
          result = await _paymentService.processGooglePayPayment(context, package);
          break;
        case 'in_app':
          result = await _paymentService.processInAppPurchase(package);
          break;
        default:
          result = PaymentResult.error;
      }

      if (mounted) {
        switch (result) {
          case PaymentResult.success:
            _showSuccessDialog(package);
            break;
          case PaymentResult.error:
            _showErrorDialog('Unable to process payment. Please try again.');
            break;
          case PaymentResult.cancelled:
            // User cancelled, no action needed
            break;
          case PaymentResult.pending:
            _showPendingDialog();
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Payment error: ${e.toString()}');
      }
    }
  }

  Future<String?> _showPaymentMethodDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, 'purchase_secure_payment'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isApplePayAvailable && Platform.isIOS)
              ListTile(
                leading: const Text('🍎', style: TextStyle(fontSize: 24)),
                title: Text(
                  tr(context, 'purchase_payment_apple'),
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                onTap: () => Navigator.of(context).pop('apple_pay'),
              ),
            if (_isGooglePayAvailable && Platform.isAndroid)
              ListTile(
                leading: const Text('🟢', style: TextStyle(fontSize: 24)),
                title: Text(
                  tr(context, 'purchase_payment_google'),
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                onTap: () => Navigator.of(context).pop('google_pay'),
              ),
            ListTile(
              leading: const Text('💳', style: TextStyle(fontSize: 24)),
              title: Text(
                tr(context, 'purchase_payment_card'),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              subtitle: Text(
                'App Store / Play Store',
                style: TextStyle(color: AppTheme.textColor(context).withValues(alpha: 0.6)),
              ),
              onTap: () => Navigator.of(context).pop('in_app'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              tr(context, 'purchase_failed_button'),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(CurrencyPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, 'purchase_success_title'),
          style: TextStyle(color: AppTheme.textColor(context)),
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
              tr(context, 'purchase_success_message').replaceAll('{coins}', '${package.coins}'),
              style: TextStyle(color: AppTheme.textColor(context).withValues(alpha: 0.8)),
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
              tr(context, 'purchase_success_button'),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, 'purchase_failed_title'),
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          message,
          style: TextStyle(color: AppTheme.textColor(context).withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              tr(context, 'purchase_failed_button'),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, 'purchase_processing_title'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Your payment is being processed. You will receive your coins shortly.',
              style: TextStyle(color: AppTheme.textColor(context).withValues(alpha: 0.8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              tr(context, 'purchase_failed_button'),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}