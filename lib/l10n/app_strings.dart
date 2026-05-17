import 'package:flutter/material.dart';

class AppStrings {
  static Locale _locale = const Locale('ko');

  static void setLocale(Locale locale) {
    _locale = locale;
  }

  static Locale get currentLocale => _locale;
  static bool get isKo => _locale.languageCode == 'ko';

  // ── 앱 공통 ──
  static String get appName => isKo ? '마이플로라' : 'MyFlora';
  static String get appSubtitle => isKo
      ? '산책에서 만난 꽃을 소중히 간직해드려요'
      : 'Cherish the flowers you meet on your walk';

  // ── 홈 화면 ──
  static String get emptyTitle => isKo ? '아직 기록이 없어요' : 'No records yet';
  static String get emptySubtitle => isKo
      ? '산책길에서 꽃을 만나면\n사진을 찍어보세요'
      : 'Take a photo when you\nfind a flower on your walk';
  static String get filterAll => isKo ? '전체' : 'All';
  static String get filterSpring => isKo ? '봄' : 'Spring';
  static String get filterSummer => isKo ? '여름' : 'Summer';
  static String get filterAutumn => isKo ? '가을' : 'Autumn';
  static String get filterWinter => isKo ? '겨울' : 'Winter';
  static String get deleteTitle => isKo ? '추억을 삭제할까요?' : 'Delete this memory?';
  static String deleteMessage(String name) => isKo
      ? '$name 기록이 영구적으로 삭제됩니다.'
      : 'The $name record will be permanently deleted.';
  static String get cancel => isKo ? '취소' : 'Cancel';
  static String get delete => isKo ? '삭제' : 'Delete';
  static String get am => isKo ? '오전' : 'AM';
  static String get pm => isKo ? '오후' : 'PM';

  // ── 촬영 화면 ──
  static String get captureTitle =>
      isKo ? '꽃을 촬영해주세요' : 'Take a photo of a flower';
  static String get captureSubtitle => isKo
      ? 'AI가 꽃 이름과 이야기를 알려드려요'
      : 'AI will tell you the flower name and story';
  static String get captureTip => isKo
      ? '💡 꽃이 화면 가운데 오도록 찍으면\n더 정확하게 인식해요!'
      : '💡 Center the flower in frame\nfor better recognition!';
  static String get takePhoto => isKo ? '📷 카메라로 촬영하기' : '📷 Take a Photo';
  static String get pickGallery =>
      isKo ? '🖼️ 사진첩에서 고르기' : '🖼️ Pick from Gallery';
  static String get scanning => isKo ? '꽃을 살펴보고 있어요' : 'Analyzing the flower';
  static String get scanningFound => isKo
      ? '꽃을 찾았어요!\n정보를 불러오고 있어요...'
      : 'Flower found!\nLoading information...';
  static String get scanningWait => isKo ? '잠시만 기다려주세요...' : 'Please wait...';
  static String get errorTitle => isKo ? '인식에 실패했어요' : 'Recognition failed';
  static String get errorSubtitle =>
      isKo ? '꽃이 잘 보이도록 다시 찍어보세요' : 'Try again with a clearer photo';
  static String get retry => isKo ? '다시 찍기' : 'Try Again';
  static String get goBack => isKo ? '돌아가기' : 'Go Back';
  static String get aiFound => isKo ? 'AI가 찾았어요' : 'AI found it';
  static String get didYouKnow => isKo ? '🌿 알고 보면' : '🌿 Did you know?';
  static String get locationLabel => isKo ? '📍 장소' : '📍 Location';
  static String get timeLabel => isKo ? '🕐 시간' : '🕐 Time';
  static String get memoHint =>
      isKo ? '✏️ 이 순간을 기록해보세요' : '✏️ Write about this moment';
  static String get saveMemory => isKo ? '🌸 추억 저장하기' : '🌸 Save Memory';
  static String get saving => isKo ? '저장 중...' : 'Saving...';

  // ── 상세 화면 ──
  static String get tipLabel => isKo ? '🔍 구별 꿀팁' : '🔍 Quick Tip';
  static String get memoLabel => isKo ? '📝 그날의 메모' : '📝 My Memo';
  static String get shareMemory =>
      isKo ? '💌 이 추억 공유하기' : '💌 Share this Memory';
  static String get backToHome => isKo ? '🏠 홈으로 돌아가기' : '🏠 Back to Home';
  static String get notFound => isKo ? '기록을 찾을 수 없어요' : 'Record not found';

  // ── 온보딩 ──
  static String get onboardingTitle => isKo ? '마이플로라' : 'MyFlora';
  static String get onboardingSubtitle => isKo
      ? '산책에서 만난 꽃을\n소중히 간직해드려요'
      : 'Cherish the flowers\nyou meet on your walk';
  static String get step1Title =>
      isKo ? '산책길에서 꽃을 만나면\n찍어보세요' : 'Take a photo when you\nfind a flower';
  static String get step1Sub =>
      isKo ? '카메라 버튼 한 번이면 됩니다' : 'Just one tap on the camera';
  static String get step2Title => isKo
      ? 'AI가 꽃 이름과\n이야기를 알려드려요'
      : 'AI tells you the name\nand story of the flower';
  static String get step2Sub =>
      isKo ? '꽃말, 재미있는 역사, 구별법까지' : 'Flower language, history, and tips';
  static String get step3Title => isKo
      ? '계절마다 쌓이는\n나만의 꽃 이야기'
      : 'Your own flower story\ngrowing each season';
  static String get step3Sub => isKo
      ? '봄의 벚꽃, 여름의 수국…\n그날이 떠오를 거예요'
      : 'Cherry blossoms in spring,\nhydrangeas in summer...';
  static String get start => isKo ? '시작하기' : 'Get Started';
  static String get next => isKo ? '다음' : 'Next';
  static String get startRecording =>
      isKo ? '꽃 기록 시작하기 🌸' : 'Start Recording 🌸';
  static String get skip => isKo ? '건너뛰기' : 'Skip';

  // ── 위치 서비스 ──
  static String get locationOff => isKo ? '위치 서비스 꺼짐' : 'Location service off';
  static String get locationNoPermission =>
      isKo ? '위치 권한 없음' : 'No location permission';
  static String get locationUnknown => isKo ? '알 수 없는 위치' : 'Unknown location';
  static String get locationError => isKo ? '위치 정보 없음' : 'No location info';
  static String get locationLoading =>
      isKo ? '위치 확인 중...' : 'Getting location...';

  // ── 사용 제한 ──
  static String get limitReachedTitle =>
      isKo ? '오늘의 인식 횟수를 다 썼어요' : 'Daily limit reached';
  static String get limitReachedMessage => isKo
      ? '하루 3회까지 무료로 이용할 수 있어요.\n내일 다시 만나요! 🌸'
      : 'You can use up to 3 times per day for free.\nSee you tomorrow! 🌸';
  static String get ok => isKo ? '확인' : 'OK';
  static String remainingCount(int count) =>
      isKo ? '오늘 남은 횟수: $count회' : '$count uses left today';

  // ── 프로필 / 내 정보 ──
  static String get myInfo => isKo ? '나의 꽃 기록' : 'My Flower Record';
  static String recordingSince(String date) =>
      isKo ? '$date부터 기록 중' : 'Recording since $date';
  static String get speciesFound => isKo ? '발견한 종' : 'Species';
  static String get totalRecords => isKo ? '총 기록' : 'Records';
  static String get daysRecorded => isKo ? '기록한 날' : 'Days';
  static String get seasonCollection =>
      isKo ? '🏆 계절별 꽃 수집' : '🏆 Seasonal Collection';
  static String get themeCollection =>
      isKo ? '🎨 테마 컬렉션' : '🎨 Theme Collection';
  static String get premium => isKo ? '프리미엄' : 'PREMIUM';
  static String get removeAds => isKo ? '광고 제거 (평생)' : 'Remove Ads (Lifetime)';
  static String get removeAdsPrice =>
      isKo ? '₩4,900 · 일회성 결제' : '\$3.99 · One-time';
  static String get removeAdsDesc => isKo
      ? '한 번 구매하면 모든 광고가 영구적으로 제거됩니다.'
      : 'Purchase once to remove all ads permanently.';
  static String get buyRemoveAds => isKo ? '광고 제거 구매하기' : 'Purchase Ad Removal';
  static String get processing => isKo ? '처리 중...' : 'Processing...';
  static String get adsRemoved => isKo ? '광고가 제거되었어요' : 'Ads have been removed';
  static String get restorePurchases => isKo ? '이전 구매 복원' : 'Restore Purchases';
  static String get restoreRequested =>
      isKo ? '구매 복원을 요청했어요' : 'Restore requested';
  static String get inUse => isKo ? '✓ 사용 중' : '✓ In Use';
  static String get unlocked => isKo ? '해금됨' : 'Unlocked';
  static String moreToUnlock(int count, String theme) =>
      isKo ? '$count종 더 모으면 $theme!' : '$count more to unlock $theme!';
  static String seasonGoal(String season, int count) =>
      isKo ? '$season $count종' : '$season $count';
  static String get defaultTheme => isKo ? '기본' : 'Default';

  // ── AI 프롬프트 ──
  static String get claudePrompt => isKo
      ? '''
에 대해 아래 JSON 형식으로 답해주세요. 반드시 JSON만 출력하세요.

{
  "koreanName": "한국어 이름 (일반적으로 부르는 이름)",
  "scientificName": "학명",
  "family": "과 이름 (예: 장미과)",
  "flowerLang": "꽃말 (2~3개, 쉼표로 구분)",
  "aiNote": "이 식물에 대한 흥미로운 이야기 2~3문장. 한국 문화나 역사와 연결하면 좋음.",
  "tip": "이 식물을 구별하는 꿀팁이나 비슷한 식물과 차이점 1~2문장",
  "season": "봄/여름/가을/겨울 중 하나 (주로 피는 계절)"
}
'''
      : '''
About this plant, respond in the JSON format below. Output only JSON. All values must be in English.

{
  "commonName": "Common English name",
  "scientificName": "Scientific name",
  "family": "Family name (e.g. Rosaceae)",
  "flowerLang": "Flower language (2-3 meanings, comma separated)",
  "aiNote": "2-3 interesting sentences about this plant. Cultural or historical stories are welcome.",
  "tip": "1-2 sentences on how to distinguish this plant from similar ones",
  "season": "Spring/Summer/Autumn/Winter (main blooming season)"
}
''';

  // ── 계절 매핑 ──
  static String seasonName(String season) {
    if (isKo) return season;
    switch (season) {
      case '봄':
        return 'Spring';
      case '여름':
        return 'Summer';
      case '가을':
        return 'Autumn';
      case '겨울':
        return 'Winter';
      default:
        return season;
    }
  }

  // ── 공유 텍스트 ──
  static String shareText({
    required String date,
    required String flowerName,
    required String scientificName,
    required String flowerLang,
    required String location,
    required String memo,
    required String aiNote,
  }) => isKo
      ? '''
🌸 마이플로라 - 꽃 기록

📅 $date
🌼 $flowerName ($scientificName)
💐 꽃말: $flowerLang
📍 $location

✏️ $memo

🌿 $aiNote

마이플로라 앱에서 기록했어요 🌸
'''
      : '''
🌸 MyFlora - Flower Memory

📅 $date
🌼 $flowerName ($scientificName)
💐 Flower Language: $flowerLang
📍 $location

✏️ $memo

🌿 $aiNote

Recorded with MyFlora 🌸
''';

  // ── 출석 보상 ──
  static String get attendanceTitle => isKo ? '오늘도 찾아와줬군요!' : 'Welcome back!';
  static String get attendanceSub =>
      isKo ? '연속 출석하면 특별한 테마를 드려요' : 'Keep your streak for a special theme';
  static String get attendanceChecked =>
      isKo ? '오늘 출석 완료! 🌸' : 'Checked in! 🌸';
  static String get attendanceAlready =>
      isKo ? '내일 또 만나요! 🌸' : 'See you tomorrow! 🌸';
  static String attendanceDaysLeft(int days) => isKo ? 'D-$days' : 'D-$days';
  static String attendanceStreak(int days) =>
      isKo ? '${days}일 연속 출석 중!' : '$days day streak!';
  static String attendanceRewardAt(int days, String themeName) =>
      isKo ? '$days일 출석 달성 시 해금' : 'Unlock at $days-day streak';
  static String get attendanceCongrats =>
      isKo ? '연속 출석 달성!' : 'Streak achieved!';
  static String get attendanceCongratsMsg => isKo
      ? '꾸준히 찾아와 주셔서 감사해요.\n특별한 테마를 선물로 드릴게요!'
      : 'Thanks for visiting!\nHere\'s a special theme for you!';
  static String get attendanceNewTheme =>
      isKo ? 'NEW 테마 해금' : 'NEW Theme Unlocked';
  static String get attendanceApplyTheme => isKo ? '테마 적용하기' : 'Apply Theme';
  static String attendanceNextReward(String themeName, int days) =>
      isKo ? '$themeName까지 ${days}일 남았어요' : '$days days left for $themeName';
  static String get attendanceNextRewardTip =>
      isKo ? '매일 접속해서 테마를 해금하세요!' : 'Visit daily to unlock!';
  static String get attendanceAllDone =>
      isKo ? '모든 출석 보상을 달성했어요! 🏆' : 'All rewards claimed! 🏆';
}
