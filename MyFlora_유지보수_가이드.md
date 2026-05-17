# MyFlora 유지보수 가이드 v1.1

## 📁 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점, Firebase/서비스 초기화
├── firebase_options.dart        # Firebase 설정 (수동 생성)
├── l10n/
│   └── app_strings.dart         # 한/영 다국어 문자열
├── models/
│   └── flower_memory.dart       # 꽃 기억 데이터 모델 (Hive)
├── providers/
│   └── memory_provider.dart     # Riverpod 상태 관리
├── router/
│   └── app_router.dart          # GoRouter 라우팅
├── screens/
│   ├── home_screen.dart         # 홈 (꽃 목록 + 출석 모달)
│   ├── capture_screen.dart      # 촬영/AI 인식
│   ├── detail_screen.dart       # 꽃 상세 정보
│   ├── settings_screen.dart     # 프로필/테마/출석현황/구매
│   └── onboarding_screen.dart   # 온보딩
└── services/
    ├── analytics_service.dart   # Firebase Analytics + Crashlytics 로깅
    ├── attendance_service.dart  # 연속 출석 체크/보상 (Hive)
    ├── theme_service.dart       # 테마 관리 (7개 테마)
    ├── ai_service.dart          # OpenAI 꽃 인식 API
    ├── camera_service.dart      # 카메라/갤러리
    ├── location_service.dart    # GPS 위치
    ├── storage_service.dart     # Hive 초기화
    ├── usage_service.dart       # 일일 사용 제한
    ├── ad_service.dart          # AdMob 배너 광고
    └── purchase_service.dart    # 인앱 결제
```

## 🎨 테마 시스템

### 테마 목록 (7개)
| ID | 이름 | 해금 조건 | 배경 이미지 |
|---|---|---|---|
| `default` | 기본 | 항상 해금 | 없음 |
| `spring` | 벚꽃 | 봄 꽃 10종 발견 | `assets/themes/spring.png` |
| `summer` | 바다 | 여름 꽃 10종 발견 | `assets/themes/summer.png` |
| `autumn` | 단풍 | 가을 꽃 10종 발견 | `assets/themes/autumn.png` |
| `winter` | 눈꽃 | 겨울 꽃 10종 발견 | `assets/themes/winter.png` |
| `sunflower` | 해바라기 | 14일 연속 출석 | `assets/themes/sunflower.png` |
| `daisy` | 데이지 | 28일 연속 출석 | `assets/themes/daisy.png` |

### 테마 추가 방법
1. `theme_service.dart`의 `themes` 리스트에 `AppTheme` 추가
2. `assets/themes/`에 PNG 배경 이미지 추가
3. `pubspec.yaml`에 asset 등록
4. 계절 테마면 `season` 필드에 계절명, 출석 테마면 `'attendance'`

### 테마 색상 구조
- `bgColor`: 전체 배경색
- `cardColor`: 카드/모달 배경색
- `accentColor`: 버튼, 필터 칩, 아이콘 등 강조색

## 📅 출석 시스템

### 동작 방식
- 앱 실행 시 `home_screen` → `_showAttendanceModal()` 호출
- 오늘 미출석이면 출석 모달 표시
- 체크인 시 연속 출석 계산 + Hive에 저장
- 14일/28일 달성 시 축하 모달 + 테마 해금

### Hive 키 (box: `attendance`)
| 키 | 타입 | 설명 |
|---|---|---|
| `check_YYYY-MM-DD` | bool | 해당 날짜 출석 여부 |
| `current_streak` | int | 현재 연속 출석 일수 |
| `max_streak` | int | 최대 연속 출석 기록 |
| `reward_sunflower` | bool | 해바라기 테마 해금 여부 |
| `reward_daisy` | bool | 데이지 테마 해금 여부 |
| `reward_sunflower_shown` | bool | 해바라기 축하 모달 표시 완료 |
| `reward_daisy_shown` | bool | 데이지 축하 모달 표시 완료 |

### 출석 보상 추가 방법
1. `attendance_service.dart`의 `checkIn()`에 `>= N일` 조건 추가
2. `getNextReward()`에 보상 정보 추가
3. `checkNewReward()`에 축하 모달 조건 추가
4. `theme_service.dart`에 테마 추가
5. `settings_screen.dart`의 `_AttendanceThemeRow` 항목 추가

## 🔥 Firebase 연동

### 구성 파일
- `android/app/google-services.json` — Firebase Android 설정
- `lib/firebase_options.dart` — Dart용 Firebase 설정

### Analytics 이벤트 목록
| 이벤트 | 파라미터 | 발생 시점 |
|---|---|---|
| `screen_view` | screenName | 각 화면 진입 |
| `flower_recognized` | flower_name, season, location | 꽃 인식 완료 |
| `attendance_check_in` | streak | 출석 체크 |
| `attendance_reward_unlocked` | theme_id, streak_days | 출석 보상 달성 |
| `theme_changed` | theme_id | 테마 변경 |
| `theme_unlocked` | theme_id, season | 계절 테마 해금 |
| `photo_taken` | — | 사진 촬영 |
| `purchase` | itemId, price | 인앱 구매 |
| `daily_limit_reached` | — | 일일 제한 도달 |
| `onboarding_complete` | — | 온보딩 완료 |
| `share` | contentType | 꽃 정보 공유 |

### Crashlytics
- `main.dart`에서 Flutter 에러 + 비동기 에러 자동 수집
- `analytics_service.dart`의 `logScreenView`에서 화면 브레드크럼 기록
- 크래시 발생 시 Firebase Console → Crashlytics에서 화면 이동 흐름 확인 가능

### Firebase Console 확인
- Analytics: Console → Analytics → DebugView (실시간 디버그)
- Crashlytics: Console → Crashlytics (크래시 리포트)
- 디버그 모드: `adb shell setprop debug.firebase.analytics.app com.usnine.myflora`

## 💰 수익화

### AdMob
- 배너 광고: `home_screen` 하단
- 광고 제거 인앱 구매 시 비활성화

### 인앱 결제
- 광고 제거: 영구 구매
- 추가 인식권 5회: 소모성 구매
- `purchase_service.dart`에서 관리

## 📱 빌드 & 배포

### 패키지 정보
- 패키지명: `com.usnine.myflora`
- 현재 버전: `v1.0.0+2`

### 필수 환경 변수 (.env)
```
OPENAI_API_KEY=sk-xxxxx
```

### 빌드 명령어
```bash
# 디버그
flutter run

# 릴리즈 APK
flutter build apk --release

# 릴리즈 AAB (Play Store)
flutter build appbundle --release
```

### Play Store 배포
1. `flutter build appbundle --release`
2. Play Console → 앱 → 프로덕션 → 새 버전 만들기
3. AAB 업로드 → 출시

## 🔧 주요 의존성

```yaml
# 상태관리
flutter_riverpod: ^2.6.1

# 로컬 저장소
hive_flutter: ^1.1.0

# 라우팅
go_router: ^14.8.1

# Firebase
firebase_core: ^3.8.1
firebase_analytics: ^11.4.1
firebase_crashlytics: ^4.3.1

# 광고/결제
google_mobile_ads: ^5.3.0
in_app_purchase: ^3.2.0

# AI
flutter_dotenv: ^5.2.1

# UI
flutter_animate: ^4.5.2
share_plus: ^10.1.4
```

## ⚠️ 트러블슈팅

### Hive box 이미 열려있는 에러
- `_box == null || !_box!.isOpen` 체크 후 open (이미 적용됨)

### Firebase 초기화 실패
- `google-services.json`이 `android/app/`에 있는지 확인
- `android/app/build.gradle`에 `apply plugin: 'com.google.gms.google-services'` 확인

### 출석 보상 누락
- `>=` 조건으로 구현되어 있어 14일/28일 넘겨도 보상 받음
- 이미 해금된 보상은 `reward_xxx` 키로 중복 방지

### 빌드 에러 시
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```
