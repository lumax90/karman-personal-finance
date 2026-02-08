import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/subscription_tier.dart';
import '../services/revenuecat_service.dart';
import 'ai_provider.dart';

/// Shows RevenueCat paywall and updates subscription tier on purchase.
Future<bool> showPaywall(WidgetRef ref) async {
  if (kIsWeb) {
    // Web doesn't support in-app purchases
    return false;
  }

  try {
    final result = await RevenueCatUI.presentPaywallIfNeeded(
      RevenueCatService.entitlementId,
      displayCloseButton: true,
    );

    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      ref.read(subscriptionTierProvider.notifier).state = SubscriptionTier.premium;
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('Paywall error: $e');
    return false;
  }
}

/// Checks RevenueCat entitlements and syncs subscription tier.
Future<void> syncSubscriptionStatus(WidgetRef ref) async {
  final isPremium = await RevenueCatService.isPremium();
  ref.read(subscriptionTierProvider.notifier).state =
      isPremium ? SubscriptionTier.premium : SubscriptionTier.free;
}

/// Restores purchases and updates tier.
Future<bool> restorePurchases(WidgetRef ref) async {
  final info = await RevenueCatService.restorePurchases();
  if (info != null) {
    final isPremium = info.entitlements.active.containsKey(RevenueCatService.entitlementId);
    ref.read(subscriptionTierProvider.notifier).state =
        isPremium ? SubscriptionTier.premium : SubscriptionTier.free;
    return isPremium;
  }
  return false;
}
