import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AttendanceService {
  static const String _boxName = 'attendance';
  static Box? _box;

  /// 초기화된 box 반환 (중복 open 방지)
  static Future<Box> get _attendanceBox async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }

  static Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      debugPrint('⚠️ AttendanceService 초기화 실패: $e');
    }
  }

  /// 날짜 → 키 변환
  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 오늘 출석 여부
  static Future<bool> isTodayChecked() async {
    try {
      final box = await _attendanceBox;
      return box.get('check_${_dateKey(DateTime.now())}', defaultValue: false)
          as bool;
    } catch (e) {
      debugPrint('⚠️ 출석 확인 실패: $e');
      return false;
    }
  }

  /// 오늘 출석 체크
  static Future<void> checkIn() async {
    try {
      final box = await _attendanceBox;
      final today = _dateKey(DateTime.now());

      // 이미 체크했으면 무시
      if (box.get('check_$today', defaultValue: false) == true) return;

      // 출석 기록
      await box.put('check_$today', true);

      // 연속 출석 계산 (오늘 포함)
      final streak = _calculateStreakSync(
        box,
        DateTime.now(),
        includeToday: true,
      );
      await box.put('current_streak', streak);

      // 최대 연속 기록 갱신
      final maxStreak = box.get('max_streak', defaultValue: 0) as int;
      if (streak > maxStreak) {
        await box.put('max_streak', streak);
      }

      // 보상 체크: >= 로 놓친 보상 방지
      if (streak >= 14 &&
          box.get('reward_sunflower', defaultValue: false) == false) {
        await box.put('reward_sunflower', true);
      }
      if (streak >= 28 &&
          box.get('reward_daisy', defaultValue: false) == false) {
        await box.put('reward_daisy', true);
      }

      debugPrint('✅ 출석 체크 완료: ${streak}일 연속');
    } catch (e) {
      debugPrint('⚠️ 출석 체크 실패: $e');
    }
  }

  /// 연속 출석 일수 계산 (동기, box 직접 접근)
  static int _calculateStreakSync(
    Box box,
    DateTime from, {
    required bool includeToday,
  }) {
    int streak = 0;
    final startOffset = includeToday ? 0 : 1;

    for (int i = startOffset; i < 365; i++) {
      final date = from.subtract(Duration(days: i));
      final key = 'check_${_dateKey(date)}';
      if (box.get(key, defaultValue: false) == true) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// 현재 연속 출석 일수
  static Future<int> getCurrentStreak() async {
    try {
      final box = await _attendanceBox;
      final now = DateTime.now();
      final todayChecked =
          box.get('check_${_dateKey(now)}', defaultValue: false) == true;

      if (todayChecked) {
        return box.get('current_streak', defaultValue: 0) as int;
      }

      // 오늘 아직 안 했으면 어제까지 계산
      return _calculateStreakSync(box, now, includeToday: false);
    } catch (e) {
      debugPrint('⚠️ 연속 출석 조회 실패: $e');
      return 0;
    }
  }

  /// 다음 보상까지 남은 일수 & 보상 정보
  static Future<Map<String, dynamic>> getNextReward() async {
    try {
      final box = await _attendanceBox;
      final streak = await getCurrentStreak();
      final todayChecked =
          box.get('check_${_dateKey(DateTime.now())}', defaultValue: false) ==
          true;

      // 오늘 아직 안 했으면 체크 시 +1 될 예정
      final effectiveStreak = todayChecked ? streak : streak + 1;

      final sunflowerUnlocked =
          box.get('reward_sunflower', defaultValue: false) == true;
      final daisyUnlocked =
          box.get('reward_daisy', defaultValue: false) == true;

      if (!sunflowerUnlocked && effectiveStreak <= 14) {
        return {
          'targetDays': 14,
          'remaining': 14 - streak,
          'themeId': 'sunflower',
          'themeNameKo': '해바라기 테마',
          'themeNameEn': 'Sunflower Theme',
          'emoji': '🌻',
        };
      } else if (!daisyUnlocked && effectiveStreak <= 28) {
        return {
          'targetDays': 28,
          'remaining': 28 - streak,
          'themeId': 'daisy',
          'themeNameKo': '데이지 테마',
          'themeNameEn': 'Daisy Theme',
          'emoji': '🌼',
        };
      } else {
        return {
          'targetDays': 0,
          'remaining': 0,
          'themeId': '',
          'themeNameKo': '모든 보상 달성!',
          'themeNameEn': 'All rewards claimed!',
          'emoji': '🏆',
        };
      }
    } catch (e) {
      debugPrint('⚠️ 다음 보상 조회 실패: $e');
      return {
        'targetDays': 14,
        'remaining': 14,
        'themeId': 'sunflower',
        'themeNameKo': '해바라기 테마',
        'themeNameEn': 'Sunflower Theme',
        'emoji': '🌻',
      };
    }
  }

  /// 보상 테마 해금 여부
  static Future<bool> isRewardUnlocked(String themeId) async {
    try {
      final box = await _attendanceBox;
      if (themeId == 'sunflower') {
        return box.get('reward_sunflower', defaultValue: false) as bool;
      }
      if (themeId == 'daisy') {
        return box.get('reward_daisy', defaultValue: false) as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 방금 보상을 받았는지 (축하 모달 표시용)
  static Future<String?> checkNewReward() async {
    try {
      final box = await _attendanceBox;
      final streak = box.get('current_streak', defaultValue: 0) as int;

      if (streak >= 14 &&
          box.get('reward_sunflower_shown', defaultValue: false) == false) {
        await box.put('reward_sunflower_shown', true);
        return 'sunflower';
      }
      if (streak >= 28 &&
          box.get('reward_daisy_shown', defaultValue: false) == false) {
        await box.put('reward_daisy_shown', true);
        return 'daisy';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 오늘 포함 최근 7일 출석 현황 (프로필용)
  static Future<List<bool>> getWeekStatus() async {
    try {
      final box = await _attendanceBox;
      final now = DateTime.now();
      final result = <bool>[];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = 'check_${_dateKey(date)}';
        result.add(box.get(key, defaultValue: false) as bool);
      }
      return result;
    } catch (e) {
      return List.filled(7, false);
    }
  }
}
