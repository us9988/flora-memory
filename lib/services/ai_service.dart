import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
}

class AiService {
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

  Future<FlowerResult?> getFlowerStory(String plantName) async {
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
        return FlowerResult(
          flowerName: flower['koreanName'] ?? flower['commonName'] ?? plantName,
          scientificName: flower['scientificName'] ?? '',
          family: flower['family'] ?? '',
          flowerLang: flower['flowerLang'] ?? '',
          aiNote: flower['aiNote'] ?? '',
          tip: flower['tip'] ?? '',
          season: _normalizeSeason(flower['season'] ?? ''),
        );
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
