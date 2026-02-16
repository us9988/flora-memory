import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String _bannerAdUnitId =
      'ca-app-pub-3895214124450611/8645008559';
  static const String _interstitialAdUnitId =
      'ca-app-pub-3895214124450611/6865023024';

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialReady = false;

  static Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      loadInterstitialAd();
    } catch (e) {
      debugPrint('⚠️ AdMob 초기화 실패: $e');
    }
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('배너 광고 로드 완료'),
        onAdFailedToLoad: (ad, error) {
          debugPrint('배너 광고 로드 실패: $error');
          ad.dispose();
        },
      ),
    );
  }

  static void loadInterstitialAd() {
    try {
      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialReady = true;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _isInterstitialReady = false;
                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _isInterstitialReady = false;
                loadInterstitialAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('전면 광고 로드 실패: $error');
            _isInterstitialReady = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('⚠️ 전면 광고 로드 에러: $e');
      _isInterstitialReady = false;
    }
  }

  static void showInterstitialAd({Function? onAdDone}) {
    try {
      if (_isInterstitialReady && _interstitialAd != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _isInterstitialReady = false;
            loadInterstitialAd();
            onAdDone?.call();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _isInterstitialReady = false;
            loadInterstitialAd();
            onAdDone?.call();
          },
        );
        _interstitialAd!.show();
      } else {
        onAdDone?.call();
      }
    } catch (e) {
      debugPrint('⚠️ 전면 광고 표시 에러: $e');
      onAdDone?.call();
    }
  }
}
