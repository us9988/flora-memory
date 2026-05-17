import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/memory_provider.dart';
import '../services/analytics_service.dart';
import '../l10n/app_strings.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final String memoryId;
  const DetailScreen({super.key, required this.memoryId});
  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('detail');
  }

  @override
  Widget build(BuildContext context) {
    final memories = ref.watch(memoryProvider);
    if (memories.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                AppStrings.notFound,
                style: const TextStyle(fontSize: 16, color: Color(0xFF8A7F72)),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(AppStrings.goBack),
              ),
            ],
          ),
        ),
      );
    }

    final memory = memories.firstWhere(
      (m) => m.id == widget.memoryId,
      orElse: () => memories.first,
    );

    final hour24 = memory.date.hour;
    final timePeriod = hour24 >= 12 ? AppStrings.pm : AppStrings.am;
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final time =
        '$timePeriod $hour12:${memory.date.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${memory.date.year}.${memory.date.month.toString().padLeft(2, '0')}.${memory.date.day.toString().padLeft(2, '0')}';

    final seasonEmoji = {'봄': '🌷', '여름': '☀️', '가을': '🍂', '겨울': '❄️'};
    final flowerEmoji = {'벚꽃': '🌸', '진달래': '🌺', '동백꽃': '🔴', '해바라기': '🌻'};
    final gradientColors = {
      '벚꽃': [const Color(0xFFFFB6C1), const Color(0xFFFF85A2)],
      '진달래': [const Color(0xFFF48FB1), const Color(0xFFE91E63)],
      '동백꽃': [const Color(0xFFEF5350), const Color(0xFFC62828)],
      '해바라기': [const Color(0xFFFFF176), const Color(0xFFFDD835)],
    };

    final colors =
        gradientColors[memory.flowerName] ??
        [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)];
    final emoji = flowerEmoji[memory.flowerName] ?? '🌼';
    final flowerLangLabel = AppStrings.isKo ? '꽃말' : 'Flower Language';
    final photoDateLabel = AppStrings.isKo
        ? '📷 $dateStr 촬영'
        : '📷 Taken $dateStr';
    final myRecordLabel = AppStrings.isKo ? '나의 기록' : 'MY RECORD';
    final aboutFlowerLabel = AppStrings.isKo
        ? '🌿 이 꽃에 대해'
        : '🌿 ABOUT THIS FLOWER';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF0E8E0)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF5A4F48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child:
                  Container(
                        height: 260,
                        decoration: BoxDecoration(
                          gradient: memory.photoPath.isEmpty
                              ? LinearGradient(
                                  colors: colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Stack(
                          children: [
                            if (memory.photoPath.isNotEmpty &&
                                File(memory.photoPath).existsSync())
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.file(
                                    File(memory.photoPath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        Center(
                                          child: Text(
                                            emoji,
                                            style: const TextStyle(
                                              fontSize: 88,
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              )
                            else
                              Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 88),
                                ),
                              ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  photoDateLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        curve: Curves.easeOut,
                      ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        seasonEmoji[memory.season] ?? '🌿',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            '$dateStr  |  $time  |  📍 ${memory.location}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB5A89E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 16),
                  Text(
                        memory.flowerName,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2520),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    memory.scientificName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB5A89E),
                      fontStyle: FontStyle.italic,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    '$flowerLangLabel: ${memory.flowerLang}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8A7F72),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                  const SizedBox(height: 24),
                  Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DFD5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (memory.memo.isNotEmpty) ...[
                    Text(
                      myRecordLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB5A89E),
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                    const SizedBox(height: 12),
                    Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF0E8E0)),
                          ),
                          child: Text(
                            memory.memo,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF3A302A),
                              height: 2.0,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 700.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    aboutFlowerLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB5A89E),
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                  const SizedBox(height: 12),
                  Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFAF6F0), Color(0xFFF5EDE4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEBE3D8)),
                        ),
                        child: Text(
                          memory.aiNote,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF5A4F48),
                            height: 1.9,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 900.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 14),
                  Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FAF0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.tipLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D2520),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              memory.tip,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5A4F48),
                                height: 1.75,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 1000.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _shareMemory(context, memory, dateStr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2520),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppStrings.shareMemory,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 1100.ms),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF5EDE4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        AppStrings.goBack,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A7F72),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 1200.ms),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareMemory(
    BuildContext context,
    dynamic memory,
    String dateStr,
  ) async {
    final text = AppStrings.shareText(
      date: dateStr,
      flowerName: memory.flowerName,
      scientificName: memory.scientificName,
      flowerLang: memory.flowerLang,
      location: memory.location,
      memo: memory.memo,
      aiNote: memory.aiNote,
    );

    if (memory.photoPath.isNotEmpty && await File(memory.photoPath).exists()) {
      await SharePlus.instance.share(
        ShareParams(text: text, files: [XFile(memory.photoPath)]),
      );
    } else {
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }
}
