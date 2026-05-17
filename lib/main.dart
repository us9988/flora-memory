import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'services/theme_service.dart';
import 'services/attendance_service.dart';
import 'l10n/app_strings.dart';

late final bool onboardingDone;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Firebase 초기화 (최우선)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint('✅ Firebase 초기화 완료');
  } catch (e) {
    debugPrint('⚠️ Firebase 초기화 실패: $e');
  }

  // 기기 언어 감지
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  AppStrings.setLocale(locale);

  // ── 필수 초기화 (순차, 앱 실행에 반드시 필요) ──
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ .env 로드 실패: $e');
  }
  await StorageService.init();
  onboardingDone = await StorageService.isOnboardingDone();

  // ── 비필수 초기화 (병렬 + 5초 타임아웃, 실패해도 앱 실행 가능) ──
  await Future.wait([
    _safeInit('ThemeService', () => ThemeService.init()),
    _safeInit('AttendanceService', () => AttendanceService.init()),
    _safeInit('AdService', () => AdService.init()),
    _safeInit('PurchaseService', () => PurchaseService.init()),
  ]);

  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: MyFloraApp()));
}

/// 각 서비스를 5초 타임아웃 + try-catch로 안전 실행
Future<void> _safeInit(String name, Future<void> Function() init) async {
  try {
    await init().timeout(
      const Duration(seconds: 5),
      onTimeout: () => debugPrint('⚠️ $name 초기화 타임아웃 (5초)'),
    );
  } catch (e) {
    debugPrint('⚠️ $name 초기화 실패: $e');
  }
}

class MyFloraApp extends ConsumerWidget {
  const MyFloraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF5),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
