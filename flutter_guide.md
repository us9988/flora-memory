# 🌸 마이플로라(MyFlora) 코드 해설서

> Flutter 초심자를 위한 파일별 사용 기술 가이드

---

## 📁 프로젝트 구조

```
lib/
├── main.dart                    # 앱 시작점
├── router/
│   └── app_router.dart          # 화면 이동(라우팅)
├── models/
│   └── flower_memory.dart       # 데이터 모델
├── providers/
│   └── memory_provider.dart     # 상태 관리
├── services/
│   ├── storage_service.dart     # 로컬 저장소
│   ├── ai_service.dart          # AI 꽃 인식
│   ├── location_service.dart    # GPS 위치
│   ├── camera_service.dart      # 카메라/갤러리
│   ├── ad_service.dart          # 광고
│   ├── purchase_service.dart    # 인앱 결제
│   ├── usage_service.dart       # 사용 횟수 제한
│   └── theme_service.dart       # 테마 관리
├── screens/
│   ├── onboarding_screen.dart   # 첫 실행 안내
│   ├── home_screen.dart         # 메인 홈
│   ├── capture_screen.dart      # 촬영 + AI 분석
│   ├── detail_screen.dart       # 기록 상세
│   └── settings_screen.dart     # 내 정보(프로필)
└── l10n/
    └── app_strings.dart         # 다국어 문자열
```

---

## 1. `main.dart` — 앱 시작점

### 역할
앱이 실행될 때 가장 먼저 호출되는 파일. 모든 서비스를 초기화하고 앱을 실행함.

### 사용된 기술

**`WidgetsFlutterBinding.ensureInitialized()`**
Flutter 엔진을 초기화. `main()` 안에서 비동기(async) 작업 전에 반드시 호출해야 함.
```dart
WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
```

**`FlutterNativeSplash`** (패키지: `flutter_native_splash`)
앱 로딩 중에 보여주는 스플래시 화면. `preserve()`로 유지하고 초기화 끝나면 `remove()`로 제거.
```dart
FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
// ... 초기화 작업 ...
FlutterNativeSplash.remove();
```

**`dotenv`** (패키지: `flutter_dotenv`)
API 키 같은 민감한 정보를 `.env` 파일에서 불러옴. 코드에 키를 직접 쓰면 위험하니까 분리함.
```dart
await dotenv.load(fileName: ".env");
```

**`ProviderScope`** (패키지: `flutter_riverpod`)
Riverpod 상태관리의 최상위 위젯. 앱 전체에서 상태(데이터)를 공유할 수 있게 해줌.
```dart
runApp(const ProviderScope(child: MyFloraApp()));
```

**`try-catch` 에러 처리**
각 서비스 초기화를 try-catch로 감싸서, 하나가 실패해도 앱이 죽지 않게 함.
```dart
try { await AdService.init(); } catch (e) { debugPrint('실패: $e'); }
```

---

## 2. `app_router.dart` — 화면 이동

### 역할
앱 안에서 어떤 화면으로 이동할지 정의. 웹사이트의 URL과 비슷한 개념.

### 사용된 기술

**`GoRouter`** (패키지: `go_router`)
Flutter의 라우팅(화면 전환) 라이브러리. 각 화면에 경로(path)를 지정.
```dart
GoRoute(path: '/home', ...)      // 홈 화면
GoRoute(path: '/capture', ...)   // 촬영 화면
GoRoute(path: '/detail/:id', ...)// 상세 화면 (id는 동적 파라미터)
```

**`CustomTransitionPage`**
화면 전환 시 애니메이션을 커스텀. 슬라이드(옆에서 밀려오기)와 페이드(서서히 나타나기) 사용.
```dart
// 오른쪽에서 밀려오는 애니메이션
SlideTransition(position: animation.drive(tween), child: child);
// 서서히 나타나는 애니메이션
FadeTransition(opacity: animation, child: child);
```

**화면 이동 방법 3가지**
```dart
context.push('/capture');    // 새 화면을 위에 쌓기 (뒤로가기 가능)
context.pop();               // 이전 화면으로 돌아가기
context.go('/home');          // 화면 교체 (뒤로가기 불가)
```

---

## 3. `flower_memory.dart` — 데이터 모델

### 역할
꽃 기록 하나에 필요한 데이터를 정의. Android의 `data class`와 같은 개념.

### 사용된 기술

**Dart 클래스와 `required` 파라미터**
모든 필드가 필수값. 꽃 이름, 학명, 꽃말, 사진 경로, 위치, 날짜 등을 가짐.
```dart
class FlowerMemory {
  final String flowerName;     // final = 한번 넣으면 변경 불가
  final DateTime date;
  const FlowerMemory({required this.flowerName, required this.date, ...});
}
```

**`toMap()` / `fromMap()`**
Hive(로컬 DB)에 저장할 때는 Map(키-값 쌍)으로 변환해야 함. Android의 `Parcelable`과 비슷.
```dart
// 객체 → Map (저장용)
Map<String, dynamic> toMap() => {'flowerName': flowerName, ...};
// Map → 객체 (불러오기용)
factory FlowerMemory.fromMap(Map map) => FlowerMemory(flowerName: map['flowerName'] ?? '', ...);
```

**`??` (null 병합 연산자)**
값이 null이면 기본값 사용. 데이터 손상 시 앱이 죽지 않게 함.
```dart
flowerName: map['flowerName'] ?? '',  // null이면 빈 문자열
```

---

## 4. `memory_provider.dart` — 상태 관리

### 역할
앱 전체에서 꽃 기록 목록을 공유하고 관리. Android의 ViewModel과 비슷.

### 사용된 기술

**Riverpod `Notifier`**
상태(state)를 보관하고, 변경되면 UI를 자동으로 다시 그려줌.
```dart
class MemoryNotifier extends Notifier<List<FlowerMemory>> {
  @override
  List<FlowerMemory> build() {  // 초기 상태 반환
    _loadFromStorage();
    return [];
  }
  
  Future<void> addMemory(FlowerMemory memory) async {
    state = [memory, ...state]; // state를 바꾸면 UI가 자동 갱신됨
  }
}
```

**`Provider` vs `NotifierProvider`**
```dart
// NotifierProvider: 변경 가능한 상태 (읽기+쓰기)
final memoryProvider = NotifierProvider<MemoryNotifier, List<FlowerMemory>>(...);

// Provider: 다른 상태를 조합한 읽기 전용 상태
final filteredMemoriesProvider = Provider<List<FlowerMemory>>((ref) {
  final memories = ref.watch(memoryProvider);  // 원본 데이터 구독
  final filter = ref.watch(seasonFilterProvider); // 필터 구독
  return memories.where((m) => m.season == filter).toList();
});
```

**`ref.watch()` vs `ref.read()`**
```dart
ref.watch(provider)  // 값이 바뀌면 위젯을 다시 그림 (build 안에서 사용)
ref.read(provider)   // 현재 값만 한 번 읽기 (이벤트 핸들러에서 사용)
```

---

## 5. `storage_service.dart` — 로컬 저장소

### 역할
꽃 기록을 기기에 영구적으로 저장/불러오기. 앱을 꺼도 데이터가 유지됨.

### 사용된 기술

**Hive** (패키지: `hive_flutter`)
Flutter용 경량 로컬 DB. SQLite보다 설정이 간단하고 빠름. Key-Value 저장 방식.
```dart
await Hive.initFlutter();              // 초기화
final box = await Hive.openBox('memories'); // Box = 테이블 개념
await box.put('key', data);            // 저장
final data = box.get('key');           // 읽기
await box.delete('key');               // 삭제
```

**Box 캐싱 패턴**
매번 `Hive.openBox()`를 호출하면 느려지니까, 한 번 열어놓고 재사용.
```dart
static Box? _memoriesBox;  // 캐시 변수
static Future<Box> get _memories async {
  _memoriesBox ??= await Hive.openBox(_boxName);  // ??= : null이면 할당
  return _memoriesBox!;
}
```

---

## 6. `ai_service.dart` — AI 꽃 인식

### 역할
사진을 찍으면 (1) Plant.id API로 꽃 종류 판별 → (2) Claude AI로 꽃 정보 생성.

### 사용된 기술

**HTTP 요청** (패키지: `http`)
외부 API 서버와 통신. REST API 호출.
```dart
final response = await http.post(
  Uri.parse('https://api.anthropic.com/v1/messages'),
  headers: {'x-api-key': apiKey, 'content-type': 'application/json'},
  body: jsonEncode({...}),
);
```

**Base64 인코딩**
사진 파일을 텍스트로 변환해서 API에 전송. 바이너리(이미지) → 문자열.
```dart
final bytes = await photo.readAsBytes();
final base64Image = base64Encode(bytes);
```

**`.timeout()`**
API 응답이 너무 오래 걸리면 30초 후 강제 중단.
```dart
.timeout(const Duration(seconds: 30), 
  onTimeout: () => http.Response('timeout', 408));
```

**JSON 파싱**
API 응답(JSON 문자열)을 Dart 객체로 변환.
```dart
final data = jsonDecode(response.body);  // 문자열 → Map
final name = data['result']['classification']['suggestions'][0]['name'];
```

---

## 7. `location_service.dart` — GPS 위치

### 역할
현재 위치의 주소를 가져옴 (예: "여의도 윤중로").

### 사용된 기술

**Geolocator** (패키지: `geolocator`)
GPS 좌표(위도/경도)를 가져옴. 권한 체크 포함.
```dart
// 1단계: 위치 서비스 켜져있는지 확인
final serviceEnabled = await Geolocator.isLocationServiceEnabled();

// 2단계: 권한 확인 및 요청
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}

// 3단계: 좌표 가져오기
final position = await Geolocator.getCurrentPosition(...);
```

**Geocoding** (패키지: `geocoding`)
GPS 좌표 → 사람이 읽을 수 있는 주소로 변환 (역 지오코딩).
```dart
final placemarks = await placemarkFromCoordinates(위도, 경도);
// → "서울시 영등포구 여의도동" 같은 주소 반환
```

---

## 8. `ad_service.dart` — 광고

### 역할
Google AdMob 배너 광고와 전면(인터스티셜) 광고를 관리.

### 사용된 기술

**Google Mobile Ads** (패키지: `google_mobile_ads`)
```dart
// 배너 광고: 화면 하단에 항상 보이는 작은 광고
BannerAd(adUnitId: '광고ID', size: AdSize.banner, ...);

// 전면 광고: 화면 전체를 덮는 큰 광고 (저장 시 1회 노출)
InterstitialAd.load(adUnitId: '광고ID', ...);
```

**콜백 패턴 (FullScreenContentCallback)**
광고가 닫히거나 실패했을 때 실행할 동작을 미리 등록.
```dart
ad.fullScreenContentCallback = FullScreenContentCallback(
  onAdDismissedFullScreenContent: (ad) {
    ad.dispose();           // 광고 메모리 해제
    loadInterstitialAd();   // 다음 광고 미리 로드
    onAdDone?.call();       // 저장 완료 처리
  },
);
```

---

## 9. `purchase_service.dart` — 인앱 결제

### 역할
광고 제거(₩4,900, 영구), 추가 인식권 5회(₩1,900, 소모품) 구매 처리.

### 사용된 기술

**InAppPurchase** (패키지: `in_app_purchase`)
Google Play 결제 연동. 비소모품과 소모품 구매 방식이 다름.
```dart
// 비소모품: 한 번 사면 영구 (광고 제거)
await _iap.buyNonConsumable(purchaseParam: param);

// 소모품: 여러 번 구매 가능 (추가 인식권)
await _iap.buyConsumable(purchaseParam: param);
```

**`Stream` (스트림)**
결제 상태가 바뀔 때마다 자동으로 알림을 받음. 실시간 이벤트 처리.
```dart
_subscription = _iap.purchaseStream.listen(_onPurchaseUpdated);
// → 결제 완료/실패/취소 시 자동 호출됨
```

**`completePurchase()`**
Google Play에 "결제 처리 완료"를 알려야 함. 안 하면 3일 후 자동 환불됨.
```dart
if (purchase.pendingCompletePurchase) {
  await _iap.completePurchase(purchase);
}
```

---

## 10. `usage_service.dart` — 사용 횟수 제한

### 역할
하루 3회 무료 제한 + 추가 크레딧(구매) 관리.

### 사용된 기술

**날짜 기반 키 생성**
오늘 날짜를 키로 사용해서 하루 단위로 사용량을 추적.
```dart
static String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';  // "2026-02-16"
}
```

**`.clamp()` 범위 제한**
값을 최소~최대 범위 안에 가둠.
```dart
return (dailyLimit - count).clamp(0, dailyLimit);
// 예: 5번 사용해도 남은 횟수는 최소 0 (음수 방지)
```

**자동 정리 (7일 이상 된 기록 삭제)**
오래된 사용 기록을 자동으로 삭제해서 저장 공간을 절약.

---

## 11. `theme_service.dart` — 테마 관리

### 역할
계절별 테마(벚꽃/바다/단풍/눈꽃) 정의, 해금 조건 확인, 현재 테마 저장.

### 사용된 기술

**`const` 생성자와 불변 객체**
테마 데이터는 변하지 않으므로 `const`로 선언해서 메모리 최적화.
```dart
const AppTheme({
  required this.id,
  required this.bgColor,
  this.bgImage,  // 선택 파라미터 (없을 수도 있음)
});
```

**`Set` (집합)으로 중복 제거**
같은 꽃을 여러 번 촬영해도 1종으로 카운트.
```dart
final Map<String, Set<String>> seasonFlowers = {'봄': <String>{}, ...};
seasonFlowers['봄']!.add('벚꽃');  // Set이므로 중복 자동 제거
```

**`firstWhere()`와 `orElse`**
리스트에서 조건에 맞는 첫 번째 항목 찾기. 못 찾으면 기본값 반환.
```dart
themes.firstWhere((t) => t.id == themeId, orElse: () => themes.first);
```

---

## 12. `app_strings.dart` — 다국어 지원

### 역할
모든 UI 텍스트를 한/영 두 가지 언어로 관리.

### 사용된 기술

**기기 언어 감지**
사용자 기기의 언어 설정을 읽어서 자동으로 한국어/영어 전환.
```dart
final locale = WidgetsBinding.instance.platformDispatcher.locale;
AppStrings.setLocale(locale);  // 'ko'면 한국어, 그 외 영어
```

**정적 getter로 다국어 문자열**
```dart
static bool get isKo => _locale.languageCode == 'ko';
static String get appName => isKo ? '마이플로라' : 'MyFlora';
```

**문자열 보간과 함수형 문자열**
동적으로 바뀌는 값이 있는 문자열은 함수로 처리.
```dart
static String remainingCount(int count) => isKo
    ? '오늘 남은 횟수: $count회'    // $변수명으로 값 삽입
    : '$count uses left today';
```

---

## 13. `onboarding_screen.dart` — 첫 실행 안내

### 역할
앱 처음 설치 시 사용법을 안내하는 4페이지 슬라이드.

### 사용된 기술

**`PageView`와 `PageController`**
좌우로 넘기는 페이지 뷰. 인스타그램 스토리와 비슷.
```dart
PageView.builder(
  controller: _pageController,
  itemCount: _pages.length,
  onPageChanged: (index) { setState(() { _currentPage = index; }); },
);
```

**`AnimatedContainer`**
속성이 바뀌면 자동으로 부드럽게 애니메이션. 페이지 인디케이터 점에 사용.
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  width: _currentPage == index ? 24 : 8,  // 현재 페이지면 넓게
);
```

**`dispose()` 메모리 정리**
화면이 사라질 때 Controller의 메모리를 해제. 메모리 누수 방지.
```dart
@override
void dispose() { _pageController.dispose(); super.dispose(); }
```

---

## 14. `home_screen.dart` — 메인 홈 화면

### 역할
저장된 꽃 기록 목록 표시, 계절 필터, 테마 배경 적용.

### 사용된 기술

**`CustomScrollView`와 `Sliver`**
여러 종류의 스크롤 가능한 위젯을 하나로 합침. 성능이 좋음.
```dart
CustomScrollView(slivers: [
  SliverToBoxAdapter(child: ...),  // 고정 헤더 영역
  SliverList(delegate: ...),       // 스크롤되는 카드 목록
]);
```

**`Stack`과 `Positioned`**
위젯을 겹쳐서 배치. 배경 이미지 위에 콘텐츠, 하단에 카메라 버튼.
```dart
Stack(children: [
  Positioned.fill(child: Image.asset('배경.png')),  // 배경: 전체 채움
  CustomScrollView(...),                             // 콘텐츠: 위에 겹침
  Positioned(bottom: 32, child: 카메라버튼()),        // 카메라: 하단 고정
]);
```

**`flutter_animate`** (패키지)
선언적 애니메이션. 위젯 뒤에 `.animate()` 체이닝.
```dart
Text('꽃').animate()
  .fadeIn(duration: 400.ms)       // 서서히 나타남
  .slideY(begin: 0.1, end: 0)    // 아래에서 위로 슬라이드
```

**`ConsumerStatefulWidget`** (Riverpod)
Riverpod 상태를 구독하면서 `setState`도 사용 가능한 위젯.
```dart
class HomeScreen extends ConsumerStatefulWidget { ... }
class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ref.watch()로 상태 구독 + setState()로 로컬 상태 관리
}
```

**`Opacity` 위젯으로 투명 배경**
배경 이미지를 25% 투명도로 깔아서 은은하게 보이게 함.
```dart
Opacity(opacity: 0.25, child: Image.asset('assets/themes/spring.png', fit: BoxFit.cover));
```

---

## 15. `capture_screen.dart` — 촬영 + AI 분석

### 역할
카메라 촬영 → AI 분석 → 결과 표시 → 메모 작성 → 저장. 앱의 핵심 화면.

### 사용된 기술

**상태 머신 (Phase 패턴)**
화면의 현재 상태를 문자열로 관리. 상태에 따라 다른 UI를 보여줌.
```dart
String _phase = 'choose';    // choose → scanning → result / error
// build() 안에서:
switch (_phase) {
  case 'choose': return _buildChooseView();
  case 'scanning': return _buildScanningView();
  case 'result': return _buildResultView();
  case 'error': return _buildErrorView();
}
```

**`mounted` 체크**
비동기 작업(AI 분석) 중에 사용자가 화면을 나갈 수 있음. `mounted`로 화면이 아직 살아있는지 확인.
```dart
final result = await _aiService.getFlowerStory(name);
if (!mounted) return;  // 화면이 사라졌으면 중단
setState(() { _result = result; });  // 화면이 있을 때만 상태 변경
```

**`TextEditingController`**
텍스트 입력 필드(메모)의 내용을 읽고 관리.
```dart
final _memoController = TextEditingController();
// 읽기: _memoController.text
// 정리: _memoController.dispose() (메모리 해제)
```

**`TweenAnimationBuilder`**
커스텀 애니메이션 위젯. 스캔 중 돋보기 아이콘 크기가 커졌다 작아짐.
```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.9, end: 1.1),  // 0.9배 ↔ 1.1배 반복
  duration: const Duration(milliseconds: 1200),
  builder: (context, value, child) => Transform.scale(scale: value, child: child),
);
```

---

## 16. `detail_screen.dart` — 기록 상세 화면

### 역할
저장된 꽃 기록을 상세하게 보여줌. 사진, 꽃 정보, 메모, 공유 기능.

### 사용된 기술

**`ConsumerWidget`** (Riverpod)
StatelessWidget + Riverpod 구독. 상태만 읽고 자체 상태는 없음.
```dart
class DetailScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoryProvider);
  }
}
```

**`Share Plus`** (패키지: `share_plus`)
OS의 공유 기능을 호출. 사진+텍스트를 카톡, 메시지 등으로 공유.
```dart
await SharePlus.instance.share(
  ShareParams(text: '공유 텍스트', files: [XFile(사진경로)]),
);
```

**`SingleChildScrollView` 수평 스크롤**
긴 텍스트가 잘리지 않고 좌우로 스크롤되게 함.
```dart
Expanded(
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Text('긴 텍스트...'),
  ),
)
```

**`File.existsSync()`**
사진 파일이 실제로 존재하는지 확인. 삭제된 사진 참조 시 에러 방지.
```dart
if (memory.photoPath.isNotEmpty && File(memory.photoPath).existsSync())
  Image.file(File(memory.photoPath))  // 파일 있으면 이미지 표시
else
  Text('🌼')  // 없으면 이모지로 대체
```

---

## 17. `settings_screen.dart` — 내 정보(프로필)

### 역할
통계(발견한 종, 기록 수), 계절별 수집 진행도, 테마 선택, 인앱 구매 UI.

### 사용된 기술

**`LinearProgressIndicator`**
수평 진행 바. 계절별 꽃 수집 진행도를 시각적으로 표시.
```dart
LinearProgressIndicator(
  value: 7 / 10,  // 0.0~1.0 사이 값 (70% 진행)
  backgroundColor: Colors.grey,
  valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
);
```

**`IntrinsicHeight`**
자식 위젯들의 높이를 가장 큰 것에 맞춤. 테마 카드들의 높이를 통일.
```dart
IntrinsicHeight(
  child: Row(children: [카드1, 카드2, 카드3]),  // 모두 같은 높이
)
```

**`setState(() {})`로 즉시 UI 갱신**
테마 선택 시 배경이 바로 바뀜.
```dart
void _selectTheme(String themeId) {
  ThemeService.setTheme(themeId);  // 저장
  setState(() {});                  // UI 다시 그리기
}
```

---

## 🔑 자주 쓰이는 Flutter 패턴 정리

### `async / await` (비동기 처리)
시간이 걸리는 작업(API 호출, 파일 읽기)을 기다리는 동안 앱이 멈추지 않게 함.
```dart
Future<void> loadData() async {
  final data = await StorageService.loadMemories();  // 기다림
  setState(() => _data = data);                       // 완료 후 UI 갱신
}
```

### `StatelessWidget` vs `StatefulWidget`
```
StatelessWidget: 변하지 않는 화면 (상세 화면, 정보 카드)
StatefulWidget:  변하는 화면 (입력 폼, 로딩 상태, 애니메이션)
                 setState()로 화면을 다시 그릴 수 있음
```

### `const` 키워드 최적화
변하지 않는 위젯에 `const`를 붙이면 매번 새로 만들지 않고 재사용 → 성능 향상.
```dart
const Text('변하지 않는 텍스트')        // ✅ 재사용됨
Text('$count회')                       // ❌ 값이 바뀌므로 const 불가
```

### `?.` (null 안전 접근)과 `!` (null 아님 단언)
```dart
place.locality?.isNotEmpty    // locality가 null이면 전체가 null 반환
_photo!                       // null이 아님을 확신할 때 (주의해서 사용)
```

---

## 📦 사용된 주요 패키지 목록

| 패키지 | 용도 |
|--------|------|
| `flutter_riverpod` | 상태 관리 (데이터 공유) |
| `go_router` | 화면 이동 (라우팅) |
| `hive_flutter` | 로컬 데이터 저장 |
| `http` | API 통신 (HTTP 요청) |
| `flutter_dotenv` | 환경 변수 (.env 파일) |
| `google_mobile_ads` | AdMob 광고 |
| `in_app_purchase` | 인앱 결제 |
| `geolocator` | GPS 위치 |
| `geocoding` | 좌표 → 주소 변환 |
| `image_picker` | 카메라/갤러리 |
| `share_plus` | 공유 기능 |
| `flutter_animate` | 선언적 애니메이션 |
| `flutter_native_splash` | 스플래시 화면 |
