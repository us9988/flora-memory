import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_strings.dart';

class FlowerResult {
  final String flowerName;
  final String scientificName;
  final String family;
  final String flowerLang;
  final String aiNote;
  final String tip;
  final String season;

  FlowerResult({
    required this.flowerName,
    required this.scientificName,
    required this.family,
    required this.flowerLang,
    required this.aiNote,
    required this.tip,
    required this.season,
  });

  /// 캐시 저장용 Map 변환
  Map<String, dynamic> toMap() => {
    'flowerName': flowerName,
    'scientificName': scientificName,
    'family': family,
    'flowerLang': flowerLang,
    'aiNote': aiNote,
    'tip': tip,
    'season': season,
  };

  /// 캐시에서 복원
  factory FlowerResult.fromMap(Map<dynamic, dynamic> map) => FlowerResult(
    flowerName: map['flowerName'] ?? '',
    scientificName: map['scientificName'] ?? '',
    family: map['family'] ?? '',
    flowerLang: map['flowerLang'] ?? '',
    aiNote: map['aiNote'] ?? '',
    tip: map['tip'] ?? '',
    season: map['season'] ?? '봄',
  );
}

class AiService {
  // ── 꽃 캐시 ──
  static const String _cacheBoxName = 'flower_cache';
  static Box? _cacheBox;

  static Future<Box> get _cache async {
    if (_cacheBox == null || !_cacheBox!.isOpen) {
      _cacheBox = await Hive.openBox(_cacheBoxName);
    }
    return _cacheBox!;
  }

  /// 캐시 키 정규화: 소문자 + 특수문자 제거
  String _cacheKey(String plantName) {
    return plantName
        .toLowerCase()
        .trim()
        .replaceAll('×', 'x') // 학명 기호 통일
        .replaceAll(RegExp(r'\s+'), ' '); // 중복 공백 제거
  }

  /// 캐시에서 꽃 이야기 조회
  Future<FlowerResult?> _getFromCache(String plantName) async {
    try {
      final box = await _cache;
      final key = _cacheKey(plantName);
      final cached = box.get(key);
      if (cached != null) {
        debugPrint('🌸 캐시 히트: $plantName');
        return FlowerResult.fromMap(Map<dynamic, dynamic>.from(cached));
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ 캐시 조회 실패: $e');
      return null;
    }
  }

  /// 캐시에 꽃 이야기 저장
  Future<void> _saveToCache(String plantName, FlowerResult result) async {
    try {
      final box = await _cache;
      final key = _cacheKey(plantName);
      await box.put(key, result.toMap());
      debugPrint('💾 캐시 저장: $plantName (총 ${box.length}종)');
    } catch (e) {
      debugPrint('⚠️ 캐시 저장 실패: $e');
    }
  }

  /// 캐시 통계 (디버그용)
  static Future<Map<String, int>> getCacheStats() async {
    try {
      final box = await _cache;
      return {'cachedSpecies': box.length};
    } catch (e) {
      return {'cachedSpecies': 0};
    }
  }

  // ── Plant.id: 꽃 식별 ──
  Future<Map<String, String>?> identifyPlant(File photo) async {
    final apiKey = dotenv.env['PLANT_ID_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('⚠️ PLANT_ID_API_KEY가 설정되지 않았습니다');
      return null;
    }

    try {
      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);
      debugPrint('Plant.id 요청: 이미지 ${bytes.length} bytes');

      final response = await http
          .post(
            Uri.parse('https://plant.id/api/v3/identification'),
            headers: {'Api-Key': apiKey, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'images': ['data:image/jpg;base64,$base64Image'],
              'similar_images': true,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => http.Response('timeout', 408),
          );

      debugPrint('Plant.id 응답: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final isPlant = data['result']?['is_plant']?['binary'] ?? true;
        if (!isPlant) {
          debugPrint('식물이 아님 → null 반환');
          return null;
        }

        final suggestions = data['result']?['classification']?['suggestions'];
        if (suggestions != null && suggestions.isNotEmpty) {
          final top = suggestions[0];
          final probability = (top['probability'] as num?)?.toDouble() ?? 0.0;
          final name = top['name'] as String? ?? 'Unknown';
          return {
            'name': name,
            'probability': (probability * 100).toStringAsFixed(1),
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Plant.id 에러: $e');
      return null;
    }
  }

  // ── Claude: 꽃 이야기 (캐시 우선) ──
  Future<FlowerResult?> getFlowerStory(String plantName) async {
    // 1. 캐시 확인
    final cached = await _getFromCache(plantName);
    if (cached != null) return cached;

    // 2. 캐시 미스 → Claude API 호출
    debugPrint('🌐 캐시 미스: $plantName → Claude API 호출');
    final apiKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('⚠️ CLAUDE_API_KEY가 설정되지 않았습니다');
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': 'claude-haiku-4-5-20251001',
              'max_tokens': 1024,
              'messages': [
                {
                  'role': 'user',
                  'content': '"$plantName"${AppStrings.claudePrompt}',
                },
              ],
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => http.Response('timeout', 408),
          );

      debugPrint('Claude 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'];
        if (content == null || content.isEmpty) return null;
        final text = content[0]['text'] as String? ?? '';
        if (text.isEmpty) return null;

        String jsonStr = text;
        if (jsonStr.contains('```')) {
          jsonStr = jsonStr
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
        }

        final flower = jsonDecode(jsonStr);
        final result = FlowerResult(
          flowerName: flower['koreanName'] ?? flower['commonName'] ?? plantName,
          scientificName: flower['scientificName'] ?? '',
          family: flower['family'] ?? '',
          flowerLang: flower['flowerLang'] ?? '',
          aiNote: flower['aiNote'] ?? '',
          tip: flower['tip'] ?? '',
          season: _normalizeSeason(flower['season'] ?? ''),
        );

        // 3. 결과를 캐시에 저장
        await _saveToCache(plantName, result);

        return result;
      }
      return null;
    } catch (e) {
      debugPrint('Claude 에러: $e');
      return null;
    }
  }

  String _normalizeSeason(String season) {
    switch (season.toLowerCase()) {
      case 'spring':
      case '봄':
        return '봄';
      case 'summer':
      case '여름':
        return '여름';
      case 'autumn':
      case 'fall':
      case '가을':
        return '가을';
      case 'winter':
      case '겨울':
        return '겨울';
      default:
        return '봄';
    }
  }

  Future<FlowerResult?> analyzeFlower(File photo) async {
    final plantInfo = await identifyPlant(photo);
    if (plantInfo == null) return null;
    return await getFlowerStory(plantInfo['name']!);
  }
}
