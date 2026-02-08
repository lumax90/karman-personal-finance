import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat configuration and service.
/// Set your API keys from the RevenueCat dashboard.
class RevenueCatService {
  // TODO: Replace with your actual RevenueCat API keys
  static const String _appleApiKey = 'appl_YOUR_APPLE_KEY';
  static const String _googleApiKey = 'goog_YOUR_GOOGLE_KEY';

  static const String entitlementId = 'premium';

  static bool _initialized = false;

  /// Initialize RevenueCat SDK. Call once at app startup.
  static Future<void> init({String? appUserId}) async {
    if (_initialized) return;
    // Skip on web — RevenueCat only works on iOS/Android
    if (kIsWeb) return;

    await Purchases.setLogLevel(LogLevel.debug);

    final String apiKey;
    if (Platform.isIOS || Platform.isMacOS) {
      apiKey = _appleApiKey;
    } else {
      apiKey = _googleApiKey;
    }

    final config = PurchasesConfiguration(apiKey)
      ..appUserID = appUserId;

    await Purchases.configure(config);
    _initialized = true;
  }

  /// Login user to RevenueCat (sync with your auth system)
  static Future<CustomerInfo?> login(String userId) async {
    if (kIsWeb) return null;
    try {
      final result = await Purchases.logIn(userId);
      return result.customerInfo;
    } catch (e) {
      debugPrint('RevenueCat login error: $e');
      return null;
    }
  }

  /// Logout user from RevenueCat
  static Future<void> logout() async {
    if (kIsWeb) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    }
  }

  /// Check if user has premium entitlement
  static Future<bool> isPremium() async {
    if (kIsWeb) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      debugPrint('RevenueCat check premium error: $e');
      return false;
    }
  }

  /// Get current customer info
  static Future<CustomerInfo?> getCustomerInfo() async {
    if (kIsWeb) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat getCustomerInfo error: $e');
      return null;
    }
  }

  /// Restore purchases (for device transfer / reinstall)
  static Future<CustomerInfo?> restorePurchases() async {
    if (kIsWeb) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('RevenueCat restore error: $e');
      return null;
    }
  }
}
