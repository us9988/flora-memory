import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'usage_service.dart';

class PurchaseService {
  static const String removeAdsId = 'remove_ads';
  static const String extraScansId = 'extra_scans_5';
  static const String _boxName = 'purchases';
  static Box? _box;

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isAdRemoved = false;
  static Function? onPurchaseUpdated;

  static bool get isAdRemoved => _isAdRemoved;

  static Future<Box> get _purchaseBox async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }

  static Future<void> init() async {
    try {
      final box = await _purchaseBox;
      _isAdRemoved = box.get('ad_removed', defaultValue: false);

      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('⚠️ 인앱 결제 사용 불가');
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onError: (error) => debugPrint('⚠️ 결제 스트림 에러: $error'),
      );
    } catch (e) {
      debugPrint('⚠️ PurchaseService 초기화 실패: $e');
    }
  }

  static void dispose() {
    _subscription?.cancel();
  }

  static Future<void> _onPurchaseUpdated(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint('⚠️ 결제 에러: ${purchase.error}');
          break;
        case PurchaseStatus.canceled:
          debugPrint('결제 취소됨');
          break;
        default:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  static Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    if (purchase.productID == removeAdsId) {
      _isAdRemoved = true;
      final box = await _purchaseBox;
      await box.put('ad_removed', true);
      onPurchaseUpdated?.call();
      debugPrint('✅ 광고 제거 완료');
    } else if (purchase.productID == extraScansId) {
      await UsageService.addBonusCredits(5);
      onPurchaseUpdated?.call();
      debugPrint('✅ 추가 인식권 5회 지급 완료');
    }
  }

  /// 광고 제거 구매
  static Future<bool> buyRemoveAds() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return false;

      final response = await _iap.queryProductDetails({removeAdsId});
      if (response.productDetails.isEmpty) {
        debugPrint('⚠️ 상품을 찾을 수 없음');
        return false;
      }

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('⚠️ 구매 실패: $e');
      return false;
    }
  }

  /// 추가 인식권 구매 (소모품)
  static Future<bool> buyExtraScans() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return false;

      final response = await _iap.queryProductDetails({extraScansId});
      if (response.productDetails.isEmpty) {
        debugPrint('⚠️ 상품을 찾을 수 없음');
        return false;
      }

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      return await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('⚠️ 구매 실패: $e');
      return false;
    }
  }

  /// 구매 복원 (비소모품만)
  static Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('⚠️ 복원 실패: $e');
    }
  }
}
