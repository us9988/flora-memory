import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/memory_provider.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/theme_service.dart';
import '../services/attendance_service.dart';
import '../services/analytics_service.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isAdRemoved = PurchaseService.isAdRemoved;
  bool _isPurchasing = false;
  Future<Map<String, dynamic>>? _attendanceFuture;
  Future<List<bool>>? _themeUnlockFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _getAttendanceData();
    _themeUnlockFuture = Future.wait([
      AttendanceService.isRewardUnlocked('sunflower'),
      AttendanceService.isRewardUnlocked('daisy'),
    ]);
    AnalyticsService.logScreenView('settings');
    PurchaseService.onPurchaseUpdated = () {
      if (mounted) setState(() => _isAdRemoved = PurchaseService.isAdRemoved);
    };
  }

  @override
  void dispose() {
    PurchaseService.onPurchaseUpdated = null;
    super.dispose();
  }

  Future<void> _buyRemoveAds() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);
    await PurchaseService.buyRemoveAds();
    if (mounted) setState(() => _isPurchasing = false);
  }

  Future<void> _restorePurchases() async {
    await PurchaseService.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.restoreRequested),
          backgroundColor: const Color(0xFF2D2520),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _selectTheme(
    String themeId,
    Map<String, int> seasonCounts,
  ) async {
    // 출석 보상 테마
    if (themeId == 'sunflower' || themeId == 'daisy') {
      final unlocked = await AttendanceService.isRewardUnlocked(themeId);
      if (unlocked) {
        await ThemeService.setTheme(themeId);
        AnalyticsService.logThemeChanged(themeId: themeId);
        if (mounted) setState(() {});
      }
      return;
    }
    // 기본 + 계절 테마
    if (themeId == 'default' ||
        ThemeService.isThemeUnlocked(themeId, seasonCounts)) {
      await ThemeService.setTheme(themeId);
      AnalyticsService.logThemeChanged(themeId: themeId);
      if (mounted) setState(() {});
    }
  }

  Future<Map<String, dynamic>> _getAttendanceData() async {
    final streak = await AttendanceService.getCurrentStreak();
    final weekStatus = await AttendanceService.getWeekStatus();
    final nextReward = await AttendanceService.getNextReward();
    return {
      'streak': streak,
      'weekStatus': weekStatus,
      'nextReward': nextReward,
    };
  }

  @override
  Widget build(BuildContext context) {
    final memories = ref.watch(memoryProvider);
    final stats = ThemeService.getOverallStats(memories);
    final seasonCounts = ThemeService.getSeasonCounts(memories);
    final recentFlowers = ThemeService.getRecentFlowers(memories);
    final currentThemeId = ThemeService.currentThemeId;

    // 첫 기록 날짜
    String recordDate = '';
    if (memories.isNotEmpty) {
      final first = memories.last.date;
      recordDate = AppStrings.isKo
          ? '${first.year}년 ${first.month}월'
          : '${first.month}/${first.year}';
    }

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
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 뒤로가기
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EDE4),
                            borderRadius: BorderRadius.circular(14),
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
                    const SizedBox(height: 20),

                    // 프로필 상단
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFF0E8E0),
                                width: 3,
                              ),
                            ),
                            child: const Center(
                              child: Text('🌸', style: TextStyle(fontSize: 36)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppStrings.myInfo,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D2520),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            memories.isNotEmpty
                                ? AppStrings.recordingSince(recordDate)
                                : '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB5A89E),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),

                    // 통계 카드
                    Row(
                      children: [
                        _StatCard(
                          number: stats['species'] ?? 0,
                          label: '🌼 ${AppStrings.speciesFound}',
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          number: stats['total'] ?? 0,
                          label: '📸 ${AppStrings.totalRecords}',
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          number: stats['days'] ?? 0,
                          label: '📅 ${AppStrings.daysRecorded}',
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    const SizedBox(height: 16),

                    // 출석 현황 카드
                    FutureBuilder<Map<String, dynamic>>(
                      future: _attendanceFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final data = snapshot.data!;
                        final streak = data['streak'] as int;
                        final weekStatus = data['weekStatus'] as List<bool>;
                        final nextReward =
                            data['nextReward'] as Map<String, dynamic>;
                        final remaining = nextReward['remaining'] as int;
                        final targetDays = nextReward['targetDays'] as int;
                        final emoji = nextReward['emoji'] as String;
                        final themeName = AppStrings.isKo
                            ? nextReward['themeNameKo'] as String
                            : nextReward['themeNameEn'] as String;
                        final allDone = targetDays == 0;
                        final days = ['월', '화', '수', '목', '금', '토', '일'];
                        final daysEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF0E8E0),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '🔥',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '${streak}${AppStrings.isKo ? '일' : 'd'} ',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFE8877C),
                                          ),
                                        ),
                                        TextSpan(
                                          text: AppStrings.isKo
                                              ? '연속 출석 중!'
                                              : 'streak!',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2D2520),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: List.generate(7, (i) {
                                  final done = weekStatus[i];
                                  final isToday = i == 6;
                                  return Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        right: i < 6 ? 4 : 0,
                                      ),
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: done
                                            ? const Color(0xFF2D2520)
                                            : isToday
                                            ? const Color(0xFFFFF0EE)
                                            : const Color(0xFFF5EDE4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: isToday && !done
                                            ? Border.all(
                                                color: const Color(0xFFE8877C),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          AppStrings.isKo ? days[i] : daysEn[i],
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: done
                                                ? Colors.white
                                                : isToday
                                                ? const Color(0xFFE8877C)
                                                : const Color(0xFFB5A89E),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              if (!allDone) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF5F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.attendanceNextReward(
                                                themeName,
                                                remaining,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF2D2520),
                                              ),
                                            ),
                                            Text(
                                              AppStrings
                                                  .attendanceNextRewardTip,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFB5A89E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        '🏆',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppStrings.attendanceAllDone,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // 출석 보상 테마 해금 현황
                              const SizedBox(height: 14),
                              const Divider(
                                color: Color(0xFFF0E8E0),
                                height: 1,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                AppStrings.isKo
                                    ? '출석 보상 테마'
                                    : 'Attendance Themes',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB5A89E),
                                ),
                              ),
                              const SizedBox(height: 10),
                              FutureBuilder<List<bool>>(
                                future: _themeUnlockFuture,
                                builder: (context, snap) {
                                  final sunflowerUnlocked =
                                      snap.data?[0] ?? false;
                                  final daisyUnlocked = snap.data?[1] ?? false;
                                  return Column(
                                    children: [
                                      _AttendanceThemeRow(
                                        emoji: '🌻',
                                        name: AppStrings.isKo
                                            ? '해바라기 테마'
                                            : 'Sunflower Theme',
                                        condition: AppStrings.isKo
                                            ? '14일 연속 출석'
                                            : '14-day streak',
                                        unlocked: sunflowerUnlocked,
                                      ),
                                      const SizedBox(height: 8),
                                      _AttendanceThemeRow(
                                        emoji: '🌼',
                                        name: AppStrings.isKo
                                            ? '데이지 테마'
                                            : 'Daisy Theme',
                                        condition: AppStrings.isKo
                                            ? '28일 연속 출석'
                                            : '28-day streak',
                                        unlocked: daisyUnlocked,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
                      },
                    ),
                    const SizedBox(height: 20),

                    // 계절별 수집
                    Text(
                      AppStrings.seasonCollection,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB5A89E),
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: 12),
                    Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF0E8E0)),
                          ),
                          child: Column(
                            children: [
                              _SeasonProgress(
                                emoji: '🌷',
                                name: AppStrings.filterSpring,
                                count: seasonCounts['봄'] ?? 0,
                                themeEmoji: '🌸',
                                themeName: AppStrings.isKo
                                    ? '벚꽃 테마'
                                    : 'Cherry Blossom',
                                color: const Color(0xFFE91E63),
                              ),
                              const SizedBox(height: 14),
                              _SeasonProgress(
                                emoji: '☀️',
                                name: AppStrings.filterSummer,
                                count: seasonCounts['여름'] ?? 0,
                                themeEmoji: '🌊',
                                themeName: AppStrings.isKo ? '바다 테마' : 'Ocean',
                                color: const Color(0xFF0288D1),
                              ),
                              const SizedBox(height: 14),
                              _SeasonProgress(
                                emoji: '🍂',
                                name: AppStrings.filterAutumn,
                                count: seasonCounts['가을'] ?? 0,
                                themeEmoji: '🍁',
                                themeName: AppStrings.isKo ? '단풍 테마' : 'Autumn',
                                color: const Color(0xFFF57C00),
                              ),
                              const SizedBox(height: 14),
                              _SeasonProgress(
                                emoji: '❄️',
                                name: AppStrings.filterWinter,
                                count: seasonCounts['겨울'] ?? 0,
                                themeEmoji: '❄️',
                                themeName: AppStrings.isKo
                                    ? '눈꽃 테마'
                                    : 'Snowflake',
                                color: const Color(0xFF42A5F5),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),

                    // 최근 발견한 꽃
                    if (recentFlowers.isNotEmpty) ...[
                      Text(
                        AppStrings.isKo ? '최근 발견한 꽃' : 'Recently Found',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB5A89E),
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentFlowers
                            .map(
                              (name) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFF0E8E0),
                                  ),
                                ),
                                child: Text(
                                  '🌼 $name',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF5A4F48),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                      const SizedBox(height: 20),
                    ],

                    // 테마 컬렉션
                    Text(
                      AppStrings.themeCollection,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB5A89E),
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 450.ms),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: IntrinsicHeight(
                        child: FutureBuilder<List<bool>>(
                          future: _themeUnlockFuture,
                          builder: (context, snap) {
                            final sunflowerUnlocked = snap.data?[0] ?? false;
                            final daisyUnlocked = snap.data?[1] ?? false;

                            return Row(
                              children: ThemeService.themes.map((theme) {
                                // 해금 여부 판별
                                bool isUnlocked;
                                String lockLabel;
                                if (theme.id == 'default') {
                                  isUnlocked = true;
                                  lockLabel = '';
                                } else if (theme.id == 'sunflower') {
                                  isUnlocked = sunflowerUnlocked;
                                  lockLabel = AppStrings.isKo
                                      ? '14일 출석'
                                      : '14d streak';
                                } else if (theme.id == 'daisy') {
                                  isUnlocked = daisyUnlocked;
                                  lockLabel = AppStrings.isKo
                                      ? '28일 출석'
                                      : '28d streak';
                                } else {
                                  isUnlocked = ThemeService.isThemeUnlocked(
                                    theme.id,
                                    seasonCounts,
                                  );
                                  lockLabel = _getUnlockCondition(theme);
                                }

                                final isActive = currentThemeId == theme.id;
                                return GestureDetector(
                                  onTap: () =>
                                      _selectTheme(theme.id, seasonCounts),
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? theme.bgColor
                                          : const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isActive
                                            ? theme.accentColor
                                            : (isUnlocked
                                                  ? const Color(0xFFF0E8E0)
                                                  : const Color(0xFFE0E0E0)),
                                        width: isActive ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (!isUnlocked)
                                          const Text(
                                            '🔒',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        Text(
                                          theme.emoji,
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppStrings.isKo
                                              ? theme.nameKo
                                              : theme.nameEn,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isUnlocked
                                                ? const Color(0xFF2D2520)
                                                : const Color(0xFFBDBDBD),
                                          ),
                                        ),
                                        if (isActive)
                                          Text(
                                            AppStrings.inUse,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: theme.accentColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        else if (!isUnlocked)
                                          Text(
                                            lockLabel,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFFBDBDBD),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

                    // 구분선
                    Container(
                      height: 1,
                      color: const Color(0xFFEBE3D8),
                      margin: const EdgeInsets.symmetric(vertical: 20),
                    ),

                    // 광고 제거
                    if (!_isAdRemoved) ...[
                      Text(
                        AppStrings.premium,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB5A89E),
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 550.ms),
                      const SizedBox(height: 12),
                      Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFF0E8E0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '🚫',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppStrings.removeAds,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2D2520),
                                            ),
                                          ),
                                          Text(
                                            AppStrings.removeAdsPrice,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFFB5A89E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isPurchasing
                                        ? null
                                        : _buyRemoveAds,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2D2520),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFFB5A89E,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      _isPurchasing
                                          ? AppStrings.processing
                                          : AppStrings.buyRemoveAds,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 600.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('✅', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Text(
                              AppStrings.adsRemoved,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 550.ms),
                      const SizedBox(height: 12),
                    ],

                    // 추가 인식권
                    _ExtraScansCard(
                          onPurchase: () async {
                            await PurchaseService.buyExtraScans();
                          },
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 650.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _restorePurchases,
                        child: Text(
                          AppStrings.restorePurchases,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB5A89E),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 700.ms),

                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'v1.0.0',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFCCC3B8),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUnlockCondition(AppTheme theme) {
    final seasonName = AppStrings.isKo
        ? {'봄': '봄', '여름': '여름', '가을': '가을', '겨울': '겨울'}[theme.season] ?? ''
        : {
                '봄': 'Spring',
                '여름': 'Summer',
                '가을': 'Autumn',
                '겨울': 'Winter',
              }[theme.season] ??
              '';
    return '$seasonName 10${AppStrings.isKo ? '종' : ' spp.'}';
  }
}

class _StatCard extends StatelessWidget {
  final int number;
  final String label;
  const _StatCard({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0E8E0)),
        ),
        child: Column(
          children: [
            Text(
              '$number',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2520),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFFB5A89E)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonProgress extends StatelessWidget {
  final String emoji;
  final String name;
  final int count;
  final String themeEmoji;
  final String themeName;
  final Color color;

  const _SeasonProgress({
    required this.emoji,
    required this.name,
    required this.count,
    required this.themeEmoji,
    required this.themeName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final goal = ThemeService.getGoal(count);
    final progress = (count / goal).clamp(0.0, 1.0);
    final isUnlocked = count >= 10;
    final remaining = 10 - count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2520),
                  ),
                ),
              ],
            ),
            Text(
              '$count / $goal${AppStrings.isKo ? '종' : ''}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A7F72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: count > goal ? 1.0 : progress,
            backgroundColor: const Color(0xFFF0E8E0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        if (isUnlocked)
          Text(
            '$themeEmoji $themeName ${AppStrings.unlocked}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          )
        else if (remaining <= 5)
          Text(
            AppStrings.moreToUnlock(remaining, '$themeEmoji $themeName'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF57C00),
            ),
          )
        else
          Text(
            '🔒 $themeEmoji $themeName',
            style: const TextStyle(fontSize: 11, color: Color(0xFFBDBDBD)),
          ),
      ],
    );
  }
}

class _ExtraScansCard extends StatefulWidget {
  final VoidCallback onPurchase;
  const _ExtraScansCard({required this.onPurchase});
  @override
  State<_ExtraScansCard> createState() => _ExtraScansCardState();
}

class _ExtraScansCardState extends State<_ExtraScansCard> {
  int _bonusCredits = 0;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadBonus();
  }

  Future<void> _loadBonus() async {
    final bonus = await UsageService.getBonusCredits();
    if (mounted) setState(() => _bonusCredits = bonus);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E8E0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('📷', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.isKo ? '추가 인식권 5회' : '5 Extra Scans',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2520),
                      ),
                    ),
                    Text(
                      AppStrings.isKo ? '₩1,900' : '\$1.49',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB5A89E),
                      ),
                    ),
                  ],
                ),
              ),
              if (_bonusCredits > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${AppStrings.isKo ? '잔여' : ''} $_bonusCredits${AppStrings.isKo ? '회' : ' left'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPurchasing
                  ? null
                  : () async {
                      setState(() => _isPurchasing = true);
                      widget.onPurchase();
                      await Future.delayed(const Duration(seconds: 2));
                      await _loadBonus();
                      if (mounted) setState(() => _isPurchasing = false);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB5A89E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _isPurchasing
                    ? AppStrings.processing
                    : (AppStrings.isKo ? '인식권 구매하기' : 'Purchase Scans'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceThemeRow extends StatelessWidget {
  final String emoji;
  final String name;
  final String condition;
  final bool unlocked;

  const _AttendanceThemeRow({
    required this.emoji,
    required this.name,
    required this.condition,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFF0FBF0) : const Color(0xFFF8F5F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2520),
                  ),
                ),
                Text(
                  condition,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB5A89E),
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppStrings.isKo ? '해금됨' : 'Unlocked',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          else
            Text('🔒', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
