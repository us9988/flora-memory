import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/flower_memory.dart';

class StorageService {
  static const String _boxName = 'memories';
  static const String _settingsBox = 'settings';

  // Box 캐싱 — 매번 open하지 않음
  static Box? _memoriesBox;
  static Box? _settingsBoxCache;

  static Future<Box> get _memories async {
    if (_memoriesBox == null || !_memoriesBox!.isOpen) {
      _memoriesBox = await Hive.openBox(_boxName);
    }
    return _memoriesBox!;
  }

  static Future<Box> get _settings async {
    if (_settingsBoxCache == null || !_settingsBoxCache!.isOpen) {
      _settingsBoxCache = await Hive.openBox(_settingsBox);
    }
    return _settingsBoxCache!;
  }

  // Hive 초기화
  static Future<void> init() async {
    await Hive.initFlutter();
    // 미리 box 열어놓기
    _memoriesBox = await Hive.openBox(_boxName);
    _settingsBoxCache = await Hive.openBox(_settingsBox);
  }

  // 저장된 추억 전부 불러오기
  static Future<List<FlowerMemory>> loadMemories() async {
    try {
      final box = await _memories;
      final List<FlowerMemory> memories = [];

      for (var key in box.keys) {
        try {
          final map = box.get(key);
          if (map != null) {
            memories.add(FlowerMemory.fromMap(Map<dynamic, dynamic>.from(map)));
          }
        } catch (e) {
          debugPrint('⚠️ 메모리 파싱 실패 (key: $key): $e');
          // 손상된 데이터 삭제
          await box.delete(key);
        }
      }

      memories.sort((a, b) => b.date.compareTo(a.date));
      return memories;
    } catch (e) {
      debugPrint('⚠️ 메모리 로드 실패: $e');
      return [];
    }
  }

  // 추억 저장
  static Future<void> saveMemory(FlowerMemory memory) async {
    try {
      final box = await _memories;
      await box.put(memory.id, memory.toMap());
    } catch (e) {
      debugPrint('⚠️ 메모리 저장 실패: $e');
    }
  }

  // 추억 삭제
  static Future<void> deleteMemory(String id) async {
    try {
      final box = await _memories;
      await box.delete(id);
    } catch (e) {
      debugPrint('⚠️ 메모리 삭제 실패: $e');
    }
  }

  // 전체 삭제 (디버그용)
  static Future<void> clearAll() async {
    try {
      final box = await _memories;
      await box.clear();
    } catch (e) {
      debugPrint('⚠️ 전체 삭제 실패: $e');
    }
  }

  // 온보딩 완료 여부 저장
  static Future<void> setOnboardingDone() async {
    try {
      final box = await _settings;
      await box.put('onboarding_done', true);
    } catch (e) {
      debugPrint('⚠️ 온보딩 상태 저장 실패: $e');
    }
  }

  // 온보딩 완료 여부 확인
  static Future<bool> isOnboardingDone() async {
    try {
      final box = await _settings;
      return box.get('onboarding_done', defaultValue: false);
    } catch (e) {
      debugPrint('⚠️ 온보딩 상태 확인 실패: $e');
      return false;
    }
  }
}
