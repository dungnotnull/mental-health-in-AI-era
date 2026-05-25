import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';

class SubscriptionRepository {
  final SupabaseClient _supabase;
  static const _entitlementId = 'premium';

  SubscriptionRepository(this._supabase);

  // Helper flag
  bool get isConfigured {
    const androidKey = "goog_your_android_key";
    const iosKey = "appl_your_ios_key";
    if (Platform.isAndroid && androidKey.contains('your_')) return false;
    if (Platform.isIOS && iosKey.contains('your_')) return false;
    return true;
  }

  // 1. Khởi tạo SDK
  Future<void> init() async {
    if (!isConfigured) return;
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration("goog_your_android_key");
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration("appl_your_ios_key");
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
      // Login User ID vào RevenueCat để đồng bộ hóa
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) await Purchases.logIn(userId);
    }
  }

  // 2. Kiểm tra quyền lợi Premium
  Future<bool> checkPremiumStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      bool isPremium =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;

      // Đồng bộ trạng thái vào Supabase (để hiện Badge VIP chẳng hạn)
      if (isPremium) {
        final expiry =
            customerInfo.entitlements.all[_entitlementId]!.expirationDate;
        await _supabase
            .from('profiles')
            .update({'is_premium': true, 'premium_until': expiry})
            .eq('id', _supabase.auth.currentUser!.id);
      }
      return isPremium;
    } catch (e) {
      return false;
    }
  }

  // 3. Thực hiện mua hàng
  Future<bool> purchaseMonthly() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.monthly != null) {
        await Purchases.purchasePackage(offerings.current!.monthly!);
        ToastService.showSuccess("Congratulations! You are now a VIP.");
        return true;
      }
    } catch (e) {
      ToastService.showError("Payment failed: $e");
    }
    return false;
  }
}
