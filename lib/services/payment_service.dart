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
  
  // Use a separate flag for forced debug mode (for emulator testing only)
  // IMPORTANT: Set this to FALSE before real device testing or production!
  final bool _forceDebugMode = false;
  
  // Calculated debug mode - true only when in development AND forced debug is on
  bool get _debugMode => kDebugMode && _forceDebugMode;

  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  bool get loading => _loading;
  List<ProductDetails> get products => _products;
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
    
    // Initialize store info for all devices
    initStoreInfo();
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
    // Check if we're using debug mode for emulators
    if (_debugMode) {
      _isAvailable = true;
      _products = _getDebugProducts();
      _loading = false;
      notifyListeners();
      return;
    }
    
    // Real device flow - check if billing is actually available
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _isAvailable = false;
      _products = [];
      _purchases = [];
      _purchasePending = false;
      _loading = false;
      _queryProductError = 'Store not available on this device';
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
      // Query real product details from the store
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
        _queryProductError = 'No products found. Make sure products are configured in Google Play Console.';
        _isAvailable = false;
        _loading = false;
        notifyListeners();
        return;
      }

      print('Products found: ${productDetailResponse.productDetails.length}');
      productDetailResponse.productDetails.forEach((product) {
        print('Product: ${product.id} - ${product.title} - ${product.price}');
      });

      _products = productDetailResponse.productDetails;
      _isAvailable = true;
      _loading = false;
      
      // Check existing purchases
      _inAppPurchase.restorePurchases();
      
      notifyListeners();
    } catch (e) {
      print('Error initializing store: $e');
      _queryProductError = e.toString();
      _isAvailable = false;
      _loading = false;
      notifyListeners();
    }
  }

  // Debug helper - only used in debug mode
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

  // Purchase credits
  Future<bool> purchaseCredits(ProductDetails productDetails) async {
    if (_debugMode) {
      // Simulate purchase for debug mode
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
    
    // Real purchase flow
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );
      
      _purchasePending = true;
      notifyListeners();
      
      // Start the purchase flow with actual Google Play billing
      print('Starting purchase for ${productDetails.id}');
      final bool purchaseStarted = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );
      
      if (!purchaseStarted) {
        // If the purchase flow couldn't start
        _purchasePending = false;
        notifyListeners();
        return false;
      }
      
      // The purchase has started - result will come through purchaseStream
      return true;
    } catch (e) {
      print('Error purchasing credits: $e');
      _purchasePending = false;
      notifyListeners();
      return false;
    }
  }

  // Handle purchase updates from Google Play
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    print('Purchase update received: ${purchaseDetailsList.length} purchases');
    
    for (final purchaseDetails in purchaseDetailsList) {
      print('Purchase status: ${purchaseDetails.status} for ${purchaseDetails.productID}');
      
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          notifyListeners();
          break;
          
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify purchase if needed (with your backend)
          // For security, you should verify purchases server-side
          
          print('Purchase completed: ${purchaseDetails.productID}');
          
          // Add credits based on the product purchased
          if (purchaseDetails.productID == _credits10PackId) {
            await addCredits(10);
            print('Added 10 credits');
          } else if (purchaseDetails.productID == _credits50PackId) {
            await addCredits(50);
            print('Added 50 credits');
          } else if (purchaseDetails.productID == _credits100PackId) {
            await addCredits(120); // 100 + 20 bonus
            print('Added 120 credits');
          }
          
          // Complete the transaction
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
            print('Purchase marked as complete');
          }
          
          _purchasePending = false;
          notifyListeners();
          break;
          
        case PurchaseStatus.error:
          print('Error purchasing: ${purchaseDetails.error}');
          _purchasePending = false;
          notifyListeners();
          break;
          
        case PurchaseStatus.canceled:
          print('Purchase canceled');
          _purchasePending = false;
          notifyListeners();
          break;
      }
    }
  }

  // For debugging - ONLY when in debug mode
  Future<void> resetCredits() async {
    if (kDebugMode) {
      _credits = 0;
      await _saveCredits();
      notifyListeners();
    }
  }

  // For debugging - ONLY when in debug mode
  Future<void> addFreeCredits(int amount) async {
    if (kDebugMode) {
      await addCredits(amount);
    }
  }

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    print('Purchase stream error: $error');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}