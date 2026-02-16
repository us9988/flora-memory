import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'router/app_router.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'services/theme_service.dart';
import 'l10n/app_strings.dart';

late final bool onboardingDone;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 기기 언어 감지
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  AppStrings.setLocale(locale);

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ .env 로드 실패: $e');
  }
  await StorageService.init();
  try {
    await AdService.init();
  } catch (e) {
    debugPrint('⚠️ AdMob 초기화 실패: $e');
  }
  try {
    await PurchaseService.init();
  } catch (e) {
    debugPrint('⚠️ 인앱결제 초기화 실패: $e');
  }
  try {
    await ThemeService.init();
  } catch (e) {
    debugPrint('⚠️ 테마 초기화 실패: $e');
  }

  onboardingDone = await StorageService.isOnboardingDone();
  FlutterNativeSplash.remove();

  runApp(const ProviderScope(child: MyFloraApp()));
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
