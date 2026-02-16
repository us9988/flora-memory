import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UsageService {
  static const String _boxName = 'usage';
  static const int dailyLimit = 3;
  static const String _bonusKey = 'bonus_credits';
  static Box? _box;

  static Future<Box> get _usageBox async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 오늘 성공한 인식 횟수
  static Future<int> getTodayCount() async {
    try {
      final box = await _usageBox;
      return box.get(_todayKey(), defaultValue: 0) as int;
    } catch (e) {
      debugPrint('⚠️ 사용량 조회 실패: $e');
      return 0;
    }
  }

  /// 추가 크레딧 잔여량
  static Future<int> getBonusCredits() async {
    try {
      final box = await _usageBox;
      return box.get(_bonusKey, defaultValue: 0) as int;
    } catch (e) {
      debugPrint('⚠️ 추가 크레딧 조회 실패: $e');
      return 0;
    }
  }

  /// 추가 크레딧 추가 (구매 시)
  static Future<void> addBonusCredits(int amount) async {
    try {
      final box = await _usageBox;
      final current = box.get(_bonusKey, defaultValue: 0) as int;
      await box.put(_bonusKey, current + amount);
    } catch (e) {
      debugPrint('⚠️ 추가 크레딧 추가 실패: $e');
    }
  }

  /// 오늘 남은 무료 횟수
  static Future<int> getRemainingCount() async {
    final count = await getTodayCount();
    return (dailyLimit - count).clamp(0, dailyLimit);
  }

  /// 사용 가능 여부 (무료 + 추가 크레딧)
  static Future<bool> canUseToday() async {
    final count = await getTodayCount();
    if (count < dailyLimit) return true;
    final bonus = await getBonusCredits();
    return bonus > 0;
  }

  /// 인식 성공 시 카운트 증가
  static Future<void> incrementCount() async {
    try {
      final box = await _usageBox;
      final key = _todayKey();
      final current = box.get(key, defaultValue: 0) as int;

      if (current < dailyLimit) {
        await box.put(key, current + 1);
      } else {
        // 추가 크레딧 차감
        final bonus = box.get(_bonusKey, defaultValue: 0) as int;
        if (bonus > 0) {
          await box.put(_bonusKey, bonus - 1);
        }
      }

      await _cleanOldRecords();
    } catch (e) {
      debugPrint('⚠️ 사용량 증가 실패: $e');
    }
  }

  /// 7일 이상 된 기록 삭제
  static Future<void> _cleanOldRecords() async {
    try {
      final box = await _usageBox;
      final now = DateTime.now();
      final keysToDelete = <String>[];

      for (var key in box.keys) {
        try {
          final keyStr = key as String;
          if (keyStr == _bonusKey) continue;
          final parts = keyStr.split('-');
          if (parts.length == 3) {
            final date = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            if (now.difference(date).inDays > 7) {
              keysToDelete.add(keyStr);
            }
          }
        } catch (_) {}
      }

      for (var key in keysToDelete) {
        await box.delete(key);
      }
    } catch (e) {
      debugPrint('⚠️ 오래된 기록 정리 실패: $e');
    }
  }
}
