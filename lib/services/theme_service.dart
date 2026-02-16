import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class AppTheme {
  final String id;
  final String nameKo;
  final String nameEn;
  final String emoji;
  final String season; // 해금 조건 계절 ('봄','여름','가을','겨울'), 'default'는 기본
  final Color bgColor;
  final Color cardColor;
  final Color accentColor;
  final String? bgImage; // assets/themes/xxx.png

  const AppTheme({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.emoji,
    required this.season,
    required this.bgColor,
    required this.cardColor,
    required this.accentColor,
    this.bgImage,
  });
}

class ThemeService {
  static const String _boxName = 'theme';
  static Box? _box;
  static String _currentThemeId = 'default';

  static final List<AppTheme> themes = [
    const AppTheme(
      id: 'default',
      nameKo: '기본',
      nameEn: 'Default',
      emoji: '🌿',
      season: 'default',
      bgColor: Color(0xFFFFFBF5),
      cardColor: Colors.white,
      accentColor: Color(0xFF2D2520),
    ),
    const AppTheme(
      id: 'spring',
      nameKo: '벚꽃',
      nameEn: 'Cherry Blossom',
      emoji: '🌸',
      season: '봄',
      bgColor: Color(0xFFFFF5F8),
      cardColor: Color(0xFFFFFAFC),
      accentColor: Color(0xFFD4638F),
      bgImage: 'assets/themes/spring.png',
    ),
    const AppTheme(
      id: 'summer',
      nameKo: '바다',
      nameEn: 'Ocean',
      emoji: '🌊',
      season: '여름',
      bgColor: Color(0xFFF2F9FF),
      cardColor: Color(0xFFF8FCFF),
      accentColor: Color(0xFF1E88C8),
      bgImage: 'assets/themes/summer.png',
    ),
    const AppTheme(
      id: 'autumn',
      nameKo: '단풍',
      nameEn: 'Autumn',
      emoji: '🍁',
      season: '가을',
      bgColor: Color(0xFFFFF7F0),
      cardColor: Color(0xFFFFFBF7),
      accentColor: Color(0xFFD47530),
      bgImage: 'assets/themes/autumn.png',
    ),
    const AppTheme(
      id: 'winter',
      nameKo: '눈꽃',
      nameEn: 'Snowflake',
      emoji: '❄️',
      season: '겨울',
      bgColor: Color(0xFFF0F4FA),
      cardColor: Color(0xFFF7F9FD),
      accentColor: Color(0xFF4A7FBD),
      bgImage: 'assets/themes/winter.png',
    ),
  ];

  static Future<Box> get _themeBox async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  static Future<void> init() async {
    try {
      final box = await _themeBox;
      _currentThemeId = box.get('current_theme', defaultValue: 'default');
    } catch (e) {
      debugPrint('⚠️ ThemeService 초기화 실패: $e');
    }
  }

  static String get currentThemeId => _currentThemeId;

  static AppTheme get currentTheme => themes.firstWhere(
    (t) => t.id == _currentThemeId,
    orElse: () => themes.first,
  );

  static Future<void> setTheme(String themeId) async {
    try {
      _currentThemeId = themeId;
      final box = await _themeBox;
      await box.put('current_theme', themeId);
    } catch (e) {
      debugPrint('⚠️ 테마 저장 실패: $e');
    }
  }

  /// 계절별 고유 꽃 종류 수 계산
  static Map<String, int> getSeasonCounts(List<dynamic> memories) {
    final Map<String, Set<String>> seasonFlowers = {
      '봄': <String>{},
      '여름': <String>{},
      '가을': <String>{},
      '겨울': <String>{},
    };

    for (final memory in memories) {
      final season = memory.season as String;
      final name = memory.flowerName as String;
      if (seasonFlowers.containsKey(season)) {
        seasonFlowers[season]!.add(name);
      }
    }

    return {
      '봄': seasonFlowers['봄']!.length,
      '여름': seasonFlowers['여름']!.length,
      '가을': seasonFlowers['가을']!.length,
      '겨울': seasonFlowers['겨울']!.length,
    };
  }

  /// 목표 단계 계산
  static int getGoal(int count) {
    if (count < 10) return 10;
    if (count < 50) return 50;
    if (count < 100) return 100;
    return 100; // 100 이상은 상한 없이 표시
  }

  /// 테마 해금 여부
  static bool isThemeUnlocked(String themeId, Map<String, int> seasonCounts) {
    if (themeId == 'default') return true;
    // TODO: 테스트 후 10으로 되돌리기
    final theme = themes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => themes.first,
    );
    final count = seasonCounts[theme.season] ?? 0;
    return count >= 10; // 테마 테스트: count >= 0
  }

  /// 전체 통계
  static Map<String, int> getOverallStats(List<dynamic> memories) {
    final uniqueFlowers = <String>{};
    final uniqueDays = <String>{};

    for (final memory in memories) {
      uniqueFlowers.add(memory.flowerName as String);
      final date = memory.date as DateTime;
      uniqueDays.add('${date.year}-${date.month}-${date.day}');
    }

    return {
      'species': uniqueFlowers.length,
      'total': memories.length,
      'days': uniqueDays.length,
    };
  }

  /// 최근 발견한 꽃 이름 (중복 제거, 최대 5개)
  static List<String> getRecentFlowers(List<dynamic> memories) {
    final seen = <String>{};
    final recent = <String>[];
    for (final memory in memories) {
      final name = memory.flowerName as String;
      if (!seen.contains(name)) {
        seen.add(name);
        recent.add(name);
        if (recent.length >= 5) break;
      }
    }
    return recent;
  }
}
