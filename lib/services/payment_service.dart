import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store/currency_package.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  // Apple Pay configuration for testing
  static const String _applePayMerchantId = 'merchant.com.solarVita.test';
  static const String _googlePayMerchantId = 'solar-vita-test';
  static const String _googlePayGateway = 'example';
  static const String _googlePayGatewayMerchantId = 'solar-vita-gateway-test';

  // Product IDs for in-app purchases (these should match your app store configuration)
  static const Set<String> _productIds = {
    'solar_coins_small_pack',
    'solar_coins_medium_pack', 
    'solar_coins_large_pack',
    'solar_coins_mega_pack',
    'solar_coins_ultimate_pack',
  };

  Future<void> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      debugPrint('In-app purchase availability: $_isAvailable');
      
      if (_isAvailable) {
        final ProductDetailsResponse response = 
            await _inAppPurchase.queryProductDetails(_productIds);
        
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('⚠️ Products not found in store: ${response.notFoundIDs}');
          debugPrint('💡 These products need to be configured in:');
          debugPrint('   • Google Play Console (for Android)');
          debugPrint('   • App Store Connect (for iOS)');
          debugPrint('📋 Missing product IDs: ${response.notFoundIDs.join(", ")}');
        }
        
        _products = response.productDetails;
        debugPrint('✅ Available products: ${_products.length}');
        for (final product in _products) {
          debugPrint('   • ${product.id}: ${product.price}');
        }
        
        if (_products.isEmpty) {
          debugPrint('⚠️ No products available! In-app purchases will not work.');
          debugPrint('🔧 For testing, consider using debug mode or test products.');
        }
      } else {
        debugPrint('❌ In-app purchases not available on this device');
      }
    } catch (e) {
      debugPrint('💥 Error initializing payment service: $e');
      _isAvailable = false;
    }
  }

  bool get isAvailable => _isAvailable;

  List<ProductDetails> get products => _products;

  // Apple Pay payment configuration
  static final ApplePayButton applePayButton = ApplePayButton(
    paymentConfiguration: PaymentConfiguration.fromJsonString('''
    {
      "provider": "apple_pay",
      "data": {
        "merchantIdentifier": "$_applePayMerchantId",
        "displayName": "SolarVita",
        "merchantCapabilities": ["3DS", "debit", "credit"],
        "supportedNetworks": ["amex", "visa", "discover", "masterCard"],
        "countryCode": "US",
        "currencyCode": "USD",
        "requiredBillingContactFields": ["emailAddress", "name"],
        "requiredShippingContactFields": [],
        "shippingMethods": []
      }
    }
    '''),
    paymentItems: [],
    style: ApplePayButtonStyle.automatic,
    type: ApplePayButtonType.buy,
    margin: EdgeInsets.only(top: 15.0),
    onPaymentResult: _onApplePayResult,
    loadingIndicator: Center(
      child: CircularProgressIndicator(),
    ),
  );

  // Google Pay payment configuration  
  static final GooglePayButton googlePayButton = GooglePayButton(
    paymentConfiguration: PaymentConfiguration.fromJsonString('''
    {
      "provider": "google_pay",
      "data": {
        "environment": "TEST",
        "apiVersion": 2,
        "apiVersionMinor": 0,
        "allowedPaymentMethods": [
          {
            "type": "CARD",
            "tokenizationSpecification": {
              "type": "PAYMENT_GATEWAY",
              "parameters": {
                "gateway": "$_googlePayGateway",
                "gatewayMerchantId": "$_googlePayGatewayMerchantId"
              }
            },
            "parameters": {
              "allowedCardNetworks": ["VISA", "MASTERCARD", "AMEX"],
              "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
              "billingAddressRequired": true,
              "billingAddressParameters": {
                "format": "FULL",
                "phoneNumberRequired": true
              }
            }
          }
        ],
        "merchantInfo": {
          "merchantId": "$_googlePayMerchantId",
          "merchantName": "SolarVita"
        },
        "transactionInfo": {
          "countryCode": "US",
          "currencyCode": "USD"
        }
      }
    }
    '''),
    paymentItems: [],
    type: GooglePayButtonType.buy,
    margin: EdgeInsets.only(top: 15.0),
    onPaymentResult: _onGooglePayResult,
    loadingIndicator: Center(
      child: CircularProgressIndicator(),
    ),
  );

  static void _onApplePayResult(paymentResult) {
    debugPrint('Apple Pay Result: $paymentResult');
    // Handle Apple Pay result
  }

  static void _onGooglePayResult(paymentResult) {
    debugPrint('Google Pay Result: $paymentResult');
    // Handle Google Pay result
  }


  // Process payment using Apple Pay
  Future<PaymentResult> processApplePayPayment(
    BuildContext context,
    CurrencyPackage package,
  ) async {
    try {
      // For now, we'll handle Apple Pay through the debug simulation below
      // TODO: Implement proper Apple Pay integration when needed

      // For testing, simulate a successful payment
      if (kDebugMode) {
        await Future.delayed(const Duration(seconds: 2));
        await _handlePaymentSuccess(package, 'apple_pay_test', {'test': true});
        return PaymentResult.success;
      }

      return PaymentResult.success;
    } catch (e) {
      debugPrint('Apple Pay error: $e');
      return PaymentResult.error;
    }
  }

  // Process payment using Google Pay
  Future<PaymentResult> processGooglePayPayment(
    BuildContext context,
    CurrencyPackage package,
  ) async {
    try {
      // For now, we'll handle Google Pay through the debug simulation below
      // TODO: Implement proper Google Pay integration when needed

      // For testing, simulate a successful payment
      if (kDebugMode) {
        await Future.delayed(const Duration(seconds: 2));
        await _handlePaymentSuccess(package, 'google_pay_test', {'test': true});
        return PaymentResult.success;
      }

      return PaymentResult.success;
    } catch (e) {
      debugPrint('Google Pay error: $e');
      return PaymentResult.error;
    }
  }

  // Process payment using in-app purchase (App Store/Play Store)
  Future<PaymentResult> processInAppPurchase(CurrencyPackage package) async {
    try {
      if (!_isAvailable) {
        debugPrint('❌ In-app purchases not available');
        return PaymentResult.error;
      }

      final productId = _getProductIdForPackage(package.id);
      final product = _products.where((p) => p.id == productId).firstOrNull;
      
      if (product == null) {
        debugPrint('❌ Product not found: $productId');
        debugPrint('💡 This product needs to be configured in the app store');
        debugPrint('🔧 Available products: ${_products.map((p) => p.id).join(", ")}');
        
        // In debug mode, simulate the purchase for testing
        if (kDebugMode) {
          debugPrint('🧪 Debug mode: simulating purchase for testing');
          await Future.delayed(const Duration(seconds: 1));
          await _handlePaymentSuccess(package, 'debug_in_app', {'test': true});
          return PaymentResult.success;
        }
        
        return PaymentResult.error;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: FirebaseAuth.instance.currentUser?.uid,
      );

      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (success) {
        // The purchase will be handled by the purchase stream listener
        return PaymentResult.pending;
      } else {
        return PaymentResult.error;
      }
    } catch (e) {
      debugPrint('In-app purchase error: $e');
      return PaymentResult.error;
    }
  }

  // Handle successful payment and award coins
  Future<void> _handlePaymentSuccess(
    CurrencyPackage package,
    String paymentMethod,
    dynamic paymentResult,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // Award coins to user
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDoc);
        final currentCoins = userSnapshot.data()?['coins'] ?? 0;
        final newCoins = currentCoins + package.coins;
        
        transaction.update(userDoc, {'coins': newCoins});
        
        // Log transaction
        transaction.set(
          userDoc.collection('transactions').doc(),
          {
            'type': 'purchase',
            'amount': package.coins,
            'packageId': package.id,
            'packageTitle': package.title,
            'price': package.price,
            'paymentMethod': paymentMethod,
            'timestamp': FieldValue.serverTimestamp(),
            'paymentResult': paymentResult.toString(),
          },
        );
      });

      debugPrint('Payment successful: ${package.coins} coins awarded');
    } catch (e) {
      debugPrint('Error handling payment success: $e');
      rethrow;
    }
  }

  // Map package ID to product ID
  String _getProductIdForPackage(String packageId) {
    switch (packageId) {
      case 'small':
        return 'solar_coins_small_pack';
      case 'medium':
        return 'solar_coins_medium_pack';
      case 'large':
        return 'solar_coins_large_pack';
      case 'mega':
        return 'solar_coins_mega_pack';
      case 'ultimate':
        return 'solar_coins_ultimate_pack';
      default:
        return 'solar_coins_small_pack';
    }
  }

  // Check if payment method is available
  static Future<bool> isApplePayAvailable() async {
    try {
      // For now, return false as Apple Pay setup requires proper configuration
      // TODO: Implement proper Apple Pay availability check when needed
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isGooglePayAvailable() async {
    try {
      // For now, return false as Google Pay setup requires proper configuration
      // TODO: Implement proper Google Pay availability check when needed
      return false;
    } catch (e) {
      return false;
    }
  }
}

enum PaymentResult {
  success,
  error,
  cancelled,
  pending,
}