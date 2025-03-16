import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService with ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Credit pack product IDs
  static const String _credits10PackId = 'animal_identifier_10_credits';
  static const String _credits50PackId = 'animal_identifier_50_credits';
  static const String _credits100PackId = 'animal_identifier_100_credits';
  
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;
  
  // Current credits balance
  int _credits = 0;
  
  // Debug mode for emulator testing
  final bool _debugMode = kDebugMode;

  bool get isAvailable => _debugMode ? true : _isAvailable;
  bool get purchasePending => _purchasePending;
  bool get loading => _loading;
  List<ProductDetails> get products => _debugMode ? _getDebugProducts() : _products;
  List<PurchaseDetails> get purchases => _purchases;
  String? get queryProductError => _queryProductError;
  int get credits => _credits;

  PaymentService() {
    // Load credits balance from shared preferences
    _loadCredits();
    
    final Stream<List<PurchaseDetails>> purchaseUpdated = 
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
    
    // Don't try to connect to real billing if in debug mode
    if (!_debugMode) {
      initStoreInfo();
    } else {
      _loading = false;
      notifyListeners();
    }
  }

  // Debug helper methods
  List<ProductDetails> _getDebugProducts() {
    // Create fake credit pack products for testing
    return [
      ProductDetails(
        id: _credits10PackId,
        title: '10 Credits',
        description: 'Purchase 10 credits for animal identification',
        price: '\$0.99',
        rawPrice: 0.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      ),
      ProductDetails(
        id: _credits50PackId,
        title: '50 Credits',
        description: 'Purchase 50 credits for animal identification',
        price: '\$3.99',
        rawPrice: 3.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      ),
      ProductDetails(
        id: _credits100PackId,
        title: '100 Credits + 20 Bonus',
        description: 'Purchase 120 credits for animal identification',
        price: '\$6.99',
        rawPrice: 6.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      ),
    ];
  }

  Future<void> _loadCredits() async {
    final prefs = await SharedPreferences.getInstance();
    _credits = prefs.getInt('credits_balance') ?? 0;
    notifyListeners();
  }

  Future<void> _saveCredits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('credits_balance', _credits);
  }

  // Add credits to the user's balance
  Future<void> addCredits(int amount) async {
    _credits += amount;
    await _saveCredits();
    notifyListeners();
  }

  // Use credits for an identification
  Future<bool> useCredits(int amount) async {
    if (_credits >= amount) {
      _credits -= amount;
      await _saveCredits();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Normal store initialization
  Future<void> initStoreInfo() async {
    if (_debugMode) {
      _isAvailable = true;
      _loading = false;
      notifyListeners();
      return;
    }
    
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _isAvailable = false;
      _products = [];
      _purchases = [];
      _purchasePending = false;
      _loading = false;
      notifyListeners();
      return;
    }

    // For Android: Configure the billing client
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition = 
          _inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      
      // Set up billing client parameters if needed
      await androidAddition.isFeatureSupported(BillingClientFeature.subscriptions);
    }

    // Set up product identifiers for credit packs
    const Set<String> productIds = {
      _credits10PackId,
      _credits50PackId,
      _credits100PackId,
    };

    try {
      final ProductDetailsResponse productDetailResponse = 
          await _inAppPurchase.queryProductDetails(productIds);
      
      if (productDetailResponse.error != null) {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = false;
        _products = [];
        _loading = false;
        notifyListeners();
        return;
      }

      if (productDetailResponse.productDetails.isEmpty) {
        _queryProductError = 'No products found';
        _isAvailable = false;
        _loading = false;
        notifyListeners();
        return;
      }

      _products = productDetailResponse.productDetails;
      _isAvailable = true;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _queryProductError = e.toString();
      _isAvailable = false;
      _loading = false;
      notifyListeners();
    }
  }

  // Purchase credits
  Future<bool> purchaseCredits(ProductDetails productDetails) async {
    // Handle debug mode purchases
    if (_debugMode) {
      _purchasePending = true;
      notifyListeners();
      
      // Simulate network delay
      await Future.delayed(Duration(seconds: 2));
      
      // Add credits based on the product purchased
      if (productDetails.id == _credits10PackId) {
        await addCredits(10);
      } else if (productDetails.id == _credits50PackId) {
        await addCredits(50);
      } else if (productDetails.id == _credits100PackId) {
        await addCredits(120); // 100 + 20 bonus
      }
      
      _purchasePending = false;
      notifyListeners();
      return true;
    }
    
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );
      
      _purchasePending = true;
      notifyListeners();
      
      // Use consumable purchase for credits
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      print('Error purchasing credits: $e');
      _purchasePending = false;
      notifyListeners();
      return false;
    }
  }

  // Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Add credits based on the product purchased
          if (purchaseDetails.productID == _credits10PackId) {
            await addCredits(10);
          } else if (purchaseDetails.productID == _credits50PackId) {
            await addCredits(50);
          } else if (purchaseDetails.productID == _credits100PackId) {
            await addCredits(120); // 100 + 20 bonus
          }
          
          // Complete the transaction
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          
          _purchasePending = false;
          break;
        case PurchaseStatus.error:
          print('Error purchasing: ${purchaseDetails.error}');
          _purchasePending = false;
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          break;
      }
    }
    notifyListeners();
  }

  // For debugging - reset credits to 0
  Future<void> resetCredits() async {
    if (_debugMode) {
      _credits = 0;
      await _saveCredits();
      notifyListeners();
    }
  }

  // For debugging - add free credits
  Future<void> addFreeCredits(int amount) async {
    if (_debugMode) {
      await addCredits(amount);
    }
  }

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    print('Stream error: $error');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}