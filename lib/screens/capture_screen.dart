import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../models/flower_memory.dart';
import '../providers/memory_provider.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/ai_service.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/analytics_service.dart';
import '../l10n/app_strings.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});
  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  String _phase = 'choose';
  File? _photo;
  FlowerResult? _result;
  String _location = '';
  String _scanningMessage = '';
  bool _isSaving = false;
  int _remainingCount = 3;
  int _bonusCredits = 0;
  final _memoController = TextEditingController();
  final _cameraService = CameraService();
  final _locationService = LocationService();
  final _aiService = AiService();

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('capture');
    _location = AppStrings.locationLoading;
    _scanningMessage = AppStrings.scanning;
    _loadRemainingCount();
  }

  Future<void> _loadRemainingCount() async {
    final count = await UsageService.getRemainingCount();
    final bonus = await UsageService.getBonusCredits();
    if (mounted)
      setState(() {
        _remainingCount = count;
        _bonusCredits = bonus;
      });
  }

  Future<bool> _checkLimit() async {
    final canUse = await UsageService.canUseToday();
    if (!canUse && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFFFBF5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppStrings.limitReachedTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2520),
            ),
          ),
          content: Text(
            AppStrings.limitReachedMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8A7F72),
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await PurchaseService.buyExtraScans();
                await _loadRemainingCount();
              },
              child: Text(
                AppStrings.isKo ? '추가 인식권 구매' : 'Buy Extra Scans',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppStrings.ok,
                style: const TextStyle(
                  color: Color(0xFF2D2520),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (!await _checkLimit()) return;
    final photo = await _cameraService.takePhoto();
    if (photo != null && mounted) {
      final compressed = await _compressImage(photo);
      setState(() => _photo = compressed);
      _fetchLocation();
      _startAnalysis();
    }
  }

  Future<void> _pickFromGallery() async {
    if (!await _checkLimit()) return;
    final photo = await _cameraService.pickFromGallery();
    if (photo != null && mounted) {
      final compressed = await _compressImage(photo);
      setState(() => _photo = compressed);
      _fetchLocation();
      _startAnalysis();
    }
  }

  /// 이미지 압축: 가로 1080px, JPEG 85% 품질
  Future<File> _compressImage(File original) async {
    try {
      final originalSize = await original.length();

      // 이미 1MB 이하면 압축 불필요
      if (originalSize < 1024 * 1024) {
        debugPrint('📷 압축 스킵: ${(originalSize / 1024).toStringAsFixed(0)}KB');
        return original;
      }

      final dir = await getApplicationDocumentsDirectory();
      final targetPath =
          '${dir.path}/flora_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        original.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (result == null) return original;

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      final saved = originalSize - compressedSize;
      final ratio = ((saved / originalSize) * 100).toStringAsFixed(0);

      debugPrint(
        '📷 압축 완료: ${(originalSize / 1024).toStringAsFixed(0)}KB → ${(compressedSize / 1024).toStringAsFixed(0)}KB ($ratio% 감소)',
      );

      return compressedFile;
    } catch (e) {
      debugPrint('⚠️ 이미지 압축 실패: $e');
      return original;
    }
  }

  Future<void> _fetchLocation() async {
    final address = await _locationService.getCurrentAddress();
    if (mounted) setState(() => _location = address);
  }

  Future<void> _startAnalysis() async {
    if (_photo == null || !await _photo!.exists()) {
      if (mounted) setState(() => _phase = 'error');
      return;
    }
    setState(() {
      _phase = 'scanning';
      _scanningMessage = AppStrings.scanning;
    });
    final plantInfo = await _aiService.identifyPlant(_photo!);
    if (!mounted) return;
    if (plantInfo == null) {
      setState(() => _phase = 'error');
      return;
    }
    setState(() {
      _scanningMessage = AppStrings.scanningFound;
    });
    final result = await _aiService.getFlowerStory(plantInfo['name']!);
    if (!mounted) return;
    if (result != null) {
      await UsageService.incrementCount();
      await _loadRemainingCount();
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = 'result';
      });
    } else {
      setState(() => _phase = 'error');
    }
  }

  void _saveMemory() {
    if (_result == null || _isSaving) return;
    setState(() => _isSaving = true);
    final newMemory = FlowerMemory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      photoPath: _photo?.path ?? '',
      flowerName: _result!.flowerName,
      flowerLang: _result!.flowerLang,
      scientificName: _result!.scientificName,
      family: _result!.family,
      aiNote: _result!.aiNote,
      tip: _result!.tip,
      memo: _memoController.text,
      location: _location,
      date: DateTime.now(),
      season: _result!.season,
    );
    ref.read(memoryProvider.notifier).addMemory(newMemory);
    if (PurchaseService.isAdRemoved) {
      if (mounted) context.go('/home');
    } else {
      AdService.showInterstitialAd(
        onAdDone: () {
          if (mounted) context.go('/home');
        },
      );
    }
  }

  String _formatTime(DateTime dt) {
    final hour24 = dt.hour;
    final period = hour24 >= 12 ? AppStrings.pm : AppStrings.am;
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    return '$period $hour12:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case 'choose':
        return _buildChooseView();
      case 'scanning':
        return _buildScanningView();
      case 'error':
        return _buildErrorView();
      default:
        return _buildResultView();
    }
  }

  Widget _buildChooseView() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
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
                        child: Text(
                          '✕',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF5A4F48),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Text('📷', style: TextStyle(fontSize: 64))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1, 1),
                  ),
              const SizedBox(height: 24),
              Text(
                AppStrings.captureTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D2520),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 8),
              Text(
                AppStrings.captureSubtitle,
                style: const TextStyle(fontSize: 15, color: Color(0xFFB5A89E)),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _bonusCredits > 0
                      ? '${AppStrings.remainingCount(_remainingCount)} (+${AppStrings.isKo ? '추가 $_bonusCredits회' : '$_bonusCredits bonus'})'
                      : AppStrings.remainingCount(_remainingCount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF6F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEBE3D8)),
                ),
                child: Text(
                  AppStrings.captureTip,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A7F72),
                    height: 1.6,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const Spacer(),
              SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _takePhoto,
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
                        AppStrings.takePhoto,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 10),
              SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _pickFromGallery,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF5EDE4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        AppStrings.pickGallery,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A7F72),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 500.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanningView() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_photo != null)
              Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      image: DecorationImage(
                        image: FileImage(_photo!),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: const Color(0xFFE8F5E9),
                        width: 3,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1500.ms, color: Colors.white24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('🔍', style: TextStyle(fontSize: 36)),
                  ),
                ),
              ),
              onEnd: () {
                if (mounted && _phase == 'scanning') setState(() {});
              },
            ),
            const SizedBox(height: 24),
            Text(
              _scanningMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2520),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.scanningWait,
              style: const TextStyle(fontSize: 14, color: Color(0xFFB5A89E)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 40,
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  3,
                  (i) => TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.3, end: 1.0),
                    duration: Duration(milliseconds: 600 + i * 150),
                    curve: Curves.easeInOut,
                    builder: (context, value, _) => Opacity(
                      opacity: value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8BC34A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    onEnd: () {
                      if (mounted && _phase == 'scanning') setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '😅',
                  style: TextStyle(fontSize: 64),
                ).animate().fadeIn(duration: 300.ms).shake(duration: 500.ms),
                const SizedBox(height: 20),
                Text(
                  AppStrings.errorTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2520),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  AppStrings.errorSubtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFB5A89E),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _photo = null;
                        _phase = 'choose';
                      });
                    },
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
                      AppStrings.retry,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
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
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
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
                          child: Text(
                            '✕',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF5A4F48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_photo != null)
                  Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: DecorationImage(
                            image: FileImage(_photo!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        curve: Curves.easeOut,
                      ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.aiFound,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB5A89E),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                      result.flowerName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2520),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 300.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 4),
                Text(
                  result.scientificName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB5A89E),
                    fontStyle: FontStyle.italic,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                const SizedBox(height: 8),
                Text(
                  '"${result.flowerLang}"',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8A7F72),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                const SizedBox(height: 20),
                Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6F0),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEBE3D8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.didYouKnow,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB5A89E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.aiNote,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5A4F48),
                              height: 1.8,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 600.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF0E8E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.locationLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB5A89E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _location,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3A302A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF0E8E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.timeLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB5A89E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3A302A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _InfoChip(
                      icon: '🌼',
                      text: result.flowerLang.split(',').first,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(icon: '🌱', text: result.family),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                const SizedBox(height: 24),
                TextField(
                  controller: _memoController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: AppStrings.memoHint,
                    hintStyle: const TextStyle(
                      color: Color(0xFFCCC3B8),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFF8BC34A)),
                    ),
                    contentPadding: const EdgeInsets.all(18),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF3A302A),
                    height: 1.8,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
                const SizedBox(height: 24),
                SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveMemory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2520),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFB5A89E),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isSaving ? AppStrings.saving : AppStrings.saveMemory,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 1000.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      _memoController.clear();
                      setState(() {
                        _photo = null;
                        _phase = 'choose';
                        _location = AppStrings.locationLoading;
                        _isSaving = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF5EDE4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      AppStrings.retry,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A7F72),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 1100.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDE4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$icon $text',
        style: const TextStyle(fontSize: 13, color: Color(0xFF5A524A)),
      ),
    );
  }
}
