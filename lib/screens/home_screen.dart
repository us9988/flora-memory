import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/flower_memory.dart';
import '../providers/memory_provider.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import '../services/theme_service.dart';
import '../services/attendance_service.dart';
import '../services/analytics_service.dart';
import '../l10n/app_strings.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('home');
    if (!PurchaseService.isAdRemoved) {
      try {
        _bannerAd = AdService.createBannerAd()
          ..load().then((_) {
            if (mounted) setState(() => _isBannerReady = true);
          });
      } catch (e) {
        debugPrint('⚠️ 배너 광고 로드 실패: $e');
      }
    }
    // 출석 체크 모달
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAttendanceModal();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memories = ref.watch(filteredMemoriesProvider);
    final currentFilter = ref.watch(seasonFilterProvider);
    final theme = ThemeService.currentTheme;

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Stack(
        children: [
          if (theme.bgImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset(
                  theme.bgImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                              children: [
                                Text(
                                  AppStrings.appName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2D2520),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Image.asset(
                                  'assets/icon/flora.png',
                                  width: 28,
                                  height: 28,
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    await context.push('/settings');
                                    if (mounted) setState(() {});
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 20,
                                        color: theme.accentColor.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.1, end: 0),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.appSubtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB5A89E),
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                        const SizedBox(height: 18),
                        Text(
                          AppStrings.isKo
                              ? '🌷 개화 계절별 모아보기'
                              : '🌷 Browse by bloom season',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB5A89E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SeasonFilter(
                              currentFilter: currentFilter,
                              accentColor: theme.accentColor,
                              chipBgColor: theme.cardColor,
                              onChanged: (season) {
                                ref
                                    .read(seasonFilterProvider.notifier)
                                    .setFilter(season);
                              },
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              if (memories.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                      ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 160),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final memory = memories[index];
                      final showDateHeader =
                          index == 0 ||
                          _formatDate(memory.date) !=
                              _formatDate(memories[index - 1].date);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader)
                            _DateHeader(date: memory.date).animate().fadeIn(
                              duration: 400.ms,
                              delay: (100 * index).ms,
                            ),
                          _MemoryCard(
                                memory: memory,
                                cardColor: theme.cardColor,
                                onTap: () =>
                                    context.push('/detail/${memory.id}'),
                                onLongPress: () {
                                  _showDeleteDialog(context, ref, memory);
                                },
                              )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: (150 * index).ms)
                              .slideY(
                                begin: 0.15,
                                end: 0,
                                duration: 500.ms,
                                delay: (150 * index).ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      );
                    }, childCount: memories.length),
                  ),
                ),
            ],
          ),
          Positioned(
            bottom: (_isBannerReady && !PurchaseService.isAdRemoved) ? 110 : 32,
            left: 0,
            right: 0,
            child: Center(
              child:
                  GestureDetector(
                        onTap: () => context.push('/capture'),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: theme.bgColor, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: theme.accentColor.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('📷', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        delay: 400.ms,
                        curve: Curves.elasticOut,
                      ),
            ),
          ),
          if (_isBannerReady &&
              _bannerAd != null &&
              !PurchaseService.isAdRemoved)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  color: theme.bgColor,
                  width: double.infinity,
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 출석 체크 모달 ──
  Future<void> _showAttendanceModal() async {
    if (!mounted) return;
    final alreadyChecked = await AttendanceService.isTodayChecked();
    if (alreadyChecked) return; // 이미 출석했으면 모달 안 띄움

    final streak = await AttendanceService.getCurrentStreak();
    final nextReward = await AttendanceService.getNextReward();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AttendanceModal(
        currentStreak: streak,
        nextReward: nextReward,
        onCheckIn: () async {
          await AttendanceService.checkIn();
          final currentStreak = await AttendanceService.getCurrentStreak();
          AnalyticsService.logAttendanceCheckIn(streak: currentStreak);
          Navigator.pop(ctx);
          // 보상 달성 체크
          final newReward = await AttendanceService.checkNewReward();
          if (newReward != null && mounted) {
            AnalyticsService.logAttendanceReward(
              themeId: newReward,
              days: newReward == 'sunflower' ? 14 : 28,
            );
            _showRewardModal(newReward);
          }
        },
      ),
    );
  }

  void _showRewardModal(String themeId) {
    final themeData = ThemeService.themes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => ThemeService.themes.first,
    );
    final targetDays = themeId == 'sunflower' ? 14 : 28;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF5),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                '$targetDays${AppStrings.attendanceCongrats}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D2520),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.attendanceCongratsMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB5A89E),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              // 테마 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF0F3), Color(0xFFFFE0E8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFB8C9),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8877C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppStrings.attendanceNewTheme,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${themeData.emoji} ${AppStrings.isKo ? themeData.nameKo : themeData.nameEn}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2520),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '✨ ${themeData.emoji} ✨',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ThemeService.setTheme(themeId);
                    AnalyticsService.logThemeChanged(themeId: themeId);
                    if (mounted) {
                      Navigator.pop(ctx);
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2520),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '${AppStrings.attendanceApplyTheme} ${themeData.emoji}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    FlowerMemory memory,
  ) {
    final theme = ThemeService.currentTheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                AppStrings.deleteTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.accentColor,
                ),
              ),
              content: Text(
                AppStrings.deleteMessage(memory.flowerName),
                style: const TextStyle(fontSize: 14, color: Color(0xFF8A7F72)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppStrings.cancel,
                    style: const TextStyle(
                      color: Color(0xFFB5A89E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(memoryProvider.notifier).removeMemory(memory.id);
                    Navigator.pop(context);
                  },
                  child: Text(
                    AppStrings.delete,
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
            .animate()
            .fadeIn(duration: 200.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 200.ms,
              curve: Curves.easeOutBack,
            );
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

class _SeasonFilter extends StatelessWidget {
  final String currentFilter;
  final Color accentColor;
  final Color chipBgColor;
  final ValueChanged<String> onChanged;
  const _SeasonFilter({
    required this.currentFilter,
    required this.accentColor,
    required this.chipBgColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': '전체', 'label': AppStrings.filterAll, 'emoji': ''},
      {'key': '봄', 'label': AppStrings.filterSpring, 'emoji': '🌷 '},
      {'key': '여름', 'label': AppStrings.filterSummer, 'emoji': '☀️ '},
      {'key': '가을', 'label': AppStrings.filterAutumn, 'emoji': '🍂 '},
      {'key': '겨울', 'label': AppStrings.filterWinter, 'emoji': '❄️ '},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = currentFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(filter['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : chipBgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '${filter['emoji']}${filter['label']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF8A7F72),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});
  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB5A89E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: const Color(0xFFEBE3D8))),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final FlowerMemory memory;
  final Color cardColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _MemoryCard({
    required this.memory,
    required this.cardColor,
    required this.onTap,
    required this.onLongPress,
  });

  String _getFlowerEmoji(String name) {
    switch (name) {
      case '벚꽃':
        return '🌸';
      case '진달래':
        return '🌺';
      case '동백꽃':
        return '🔴';
      case '해바라기':
        return '🌻';
      case '수국':
        return '💜';
      case '코스모스':
        return '🌸';
      default:
        return '🌼';
    }
  }

  List<Color> _getGradientColors(String name) {
    switch (name) {
      case '벚꽃':
        return [const Color(0xFFFFB6C1), const Color(0xFFFF85A2)];
      case '진달래':
        return [const Color(0xFFF48FB1), const Color(0xFFE91E63)];
      case '동백꽃':
        return [const Color(0xFFEF5350), const Color(0xFFC62828)];
      case '해바라기':
        return [const Color(0xFFFFF176), const Color(0xFFFDD835)];
      default:
        return [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour24 = memory.date.hour;
    final period = hour24 >= 12 ? AppStrings.pm : AppStrings.am;
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final time =
        '$period $hour12:${memory.date.minute.toString().padLeft(2, '0')}';
    final colors = _getGradientColors(memory.flowerName);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF78645A).withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: memory.photoPath.isEmpty
                    ? LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  if (memory.photoPath.isNotEmpty &&
                      File(memory.photoPath).existsSync())
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Image.file(
                          File(memory.photoPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Center(
                            child: Text(
                              _getFlowerEmoji(memory.flowerName),
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        _getFlowerEmoji(memory.flowerName),
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${memory.date.month}.${memory.date.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A302A),
                            ),
                          ),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9A8F85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        memory.flowerName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2520),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          memory.flowerLang,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB5A89E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (memory.memo.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      memory.memo,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF5A4F48),
                        height: 1.8,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('📍', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        memory.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFB5A89E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            AppStrings.emptyTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A7F72),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.emptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB5A89E),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 출석 체크 모달 위젯 ──
class _AttendanceModal extends StatelessWidget {
  final int currentStreak;
  final Map<String, dynamic> nextReward;
  final VoidCallback onCheckIn;

  const _AttendanceModal({
    required this.currentStreak,
    required this.nextReward,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final targetDays = nextReward['targetDays'] as int;
    final remaining = nextReward['remaining'] as int;
    final emoji = nextReward['emoji'] as String;
    final themeName = AppStrings.isKo
        ? nextReward['themeNameKo'] as String
        : nextReward['themeNameEn'] as String;
    final allDone = targetDays == 0;

    // 현재 타겟 기준 진행도
    final progressDays = allDone ? 0 : targetDays - remaining;
    final progressRatio = allDone
        ? 1.0
        : (progressDays / targetDays).clamp(0.0, 1.0);
    final streakInCycle = progressDays;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌼', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              AppStrings.attendanceTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2520),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.attendanceSub,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFFB5A89E)),
            ),
            const SizedBox(height: 22),

            // 7일 원형 진행도 (스크롤 가능)
            SizedBox(
              height: 70,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(7, (i) {
                    final dayNum = i + 1;
                    final isChecked =
                        i <
                        (streakInCycle % 7 == 0 && streakInCycle > 0
                            ? 7
                            : streakInCycle % 7);
                    final isToday =
                        i ==
                        (streakInCycle % 7 == 0 && streakInCycle > 0
                            ? 6
                            : (streakInCycle % 7));
                    final isRewardDay = i == 6;

                    final widget = isRewardDay
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: isChecked
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFFFD700),
                                            Color(0xFFFFA500),
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFFEBE3D8),
                                            Color(0xFFD4CCC2),
                                          ],
                                        ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '🎁',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppStrings.isKo ? '보상' : 'Gift',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB5A89E),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isChecked
                                      ? const Color(0xFF2D2520)
                                      : isToday
                                      ? const Color(0xFFFFF0EE)
                                      : const Color(0xFFFFFBF5),
                                  border: Border.all(
                                    color: isChecked
                                        ? const Color(0xFF2D2520)
                                        : isToday
                                        ? const Color(0xFFE8877C)
                                        : const Color(0xFFEBE3D8),
                                    width: 2.5,
                                  ),
                                ),
                                child: Center(
                                  child: isChecked
                                      ? const Text(
                                          '✓',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : Text(
                                          '$dayNum',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isToday
                                                ? const Color(0xFFE8877C)
                                                : const Color(0xFFB5A89E),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isToday
                                    ? (AppStrings.isKo ? '오늘' : 'Today')
                                    : '${dayNum}${AppStrings.isKo ? '일' : ''}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isToday
                                      ? const Color(0xFFE8877C)
                                      : const Color(0xFFB5A89E),
                                ),
                              ),
                            ],
                          );

                    return Padding(
                      padding: EdgeInsets.only(right: i < 6 ? 14 : 0),
                      child: widget,
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 진행 바
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    backgroundColor: const Color(0xFFEBE3D8),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2D2520),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    allDone
                        ? '완료!'
                        : '$progressDays / $targetDays${AppStrings.isKo ? '일' : ' days'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB5A89E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 보상 미리보기
            if (!allDone)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF5F8), Color(0xFFFFE8EE)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD4DE),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            themeName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2520),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.attendanceRewardAt(
                              targetDays,
                              themeName,
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB5A89E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppStrings.attendanceDaysLeft(remaining),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE8877C),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.attendanceAllDone,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),

            // 출석 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2520),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppStrings.attendanceChecked,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
