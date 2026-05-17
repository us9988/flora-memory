import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 화면 조회 + Crashlytics 브레드크럼
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      FirebaseCrashlytics.instance.log('screen_view: $screenName');
    } catch (e) {
      debugPrint('⚠️ Analytics logScreenView 실패: $e');
    }
  }

  /// 꽃 인식 완료
  static Future<void> logFlowerRecognized({
    required String flowerName,
    required String season,
    required String location,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'flower_recognized',
        parameters: {
          'flower_name': flowerName,
          'season': season,
          'location': location,
        },
      );
    } catch (e) {
      debugPrint('⚠️ Analytics logFlowerRecognized 실패: $e');
    }
  }

  /// 출석 체크
  static Future<void> logAttendanceCheckIn({required int streak}) async {
    try {
      await _analytics.logEvent(
        name: 'attendance_check_in',
        parameters: {'streak': streak},
      );
    } catch (e) {
      debugPrint('⚠️ Analytics logAttendanceCheckIn 실패: $e');
    }
  }

  /// 출석 보상 달성
  static Future<void> logAttendanceReward({
    required String themeId,
    required int days,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'attendance_reward_unlocked',
        parameters: {'theme_id': themeId, 'streak_days': days},
      );
    } catch (e) {
      debugPrint('⚠️ Analytics logAttendanceReward 실패: $e');
    }
  }

  /// 테마 변경
  static Future<void> logThemeChanged({required String themeId}) async {
    try {
      await _analytics.logEvent(
        name: 'theme_changed',
        parameters: {'theme_id': themeId},
      );
    } catch (e) {
      debugPrint('⚠️ Analytics logThemeChanged 실패: $e');
    }
  }

  /// 테마 해금 (계절)
  static Future<void> logThemeUnlocked({
    required String themeId,
    required String season,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'theme_unlocked',
        parameters: {'theme_id': themeId, 'season': season},
      );
    } catch (e) {
      debugPrint('⚠️ Analytics logThemeUnlocked 실패: $e');
    }
  }

  /// 사진 촬영
  static Future<void> logPhotoTaken() async {
    try {
      await _analytics.logEvent(name: 'photo_taken');
    } catch (e) {
      debugPrint('⚠️ Analytics logPhotoTaken 실패: $e');
    }
  }

  /// 인앱 구매
  static Future<void> logPurchase({
    required String itemId,
    required double price,
  }) async {
    try {
      await _analytics.logPurchase(
        currency: 'KRW',
        value: price,
        items: [
          AnalyticsEventItem(itemId: itemId, itemName: itemId, price: price),
        ],
      );
    } catch (e) {
      debugPrint('⚠️ Analytics logPurchase 실패: $e');
    }
  }

  /// 일일 사용 제한 도달
  static Future<void> logDailyLimitReached() async {
    try {
      await _analytics.logEvent(name: 'daily_limit_reached');
    } catch (e) {
      debugPrint('⚠️ Analytics logDailyLimitReached 실패: $e');
    }
  }

  /// 온보딩 완료
  static Future<void> logOnboardingComplete() async {
    try {
      await _analytics.logEvent(name: 'onboarding_complete');
    } catch (e) {
      debugPrint('⚠️ Analytics logOnboardingComplete 실패: $e');
    }
  }

  /// 공유
  static Future<void> logShare({required String contentType}) async {
    try {
      await _analytics.logShare(
        contentType: contentType,
        itemId: 'flower_memory',
        method: 'app_share',
      );
    } catch (e) {
      debugPrint('⚠️ Analytics logShare 실패: $e');
    }
  }
}
