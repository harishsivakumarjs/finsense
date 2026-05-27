# FinSense Mobile

Flutter mobile client for the FinSense personal finance platform.

## Requirements

- Flutter 3.22+
- Dart 3.4+
- Android emulator or iOS simulator
- FinSense backend running on port 8001

## Setup

```bash
cd mobile
flutter pub get
flutter run
```

The app auto-selects the API base URL:
- **Android emulator** → `http://10.0.2.2:8001/api`
- **iOS simulator** → `http://127.0.0.1:8001/api`

Override via `.env` if needed:
```
API_BASE_URL_ANDROID=http://10.0.2.2:8001/api
API_BASE_URL_IOS=http://127.0.0.1:8001/api
JWT_KEY=finsense_jwt_token
USER_KEY=finsense_user
```

## Architecture

```
lib/
├── core/
│   ├── constants/       # FSColors, text styles, API endpoint paths
│   ├── router/          # GoRouter with auth guard
│   ├── theme/           # MaterialTheme (dark, warm navy)
│   └── utils/           # formatINR (Indian grouping), date helpers
├── models/              # 13 typed models with computed getters
├── network/             # DioClient with JWT interceptor
├── providers/           # Riverpod AsyncNotifier providers per feature
├── screens/             # 15 screens (one per feature)
├── services/            # API service layer + NotificationService
└── widgets/
    ├── charts/          # FSBarChart, FSAreaChart, FSDonutChart, FSLineChart
    ├── common/          # FSCard, FSButton, FSTextField, FSMetricCard, …
    └── navigation/      # FSBottomNavBar (5 tabs + More sheet)
```

## Screens

| Screen | Route | Tab |
|--------|-------|-----|
| Splash | `/` | — |
| Login | `/login` | — |
| Register | `/register` | — |
| Dashboard | `/dashboard` | Home |
| Income | `/income` | Money |
| Expenses | `/expenses` | Money |
| Debt | `/debt` | More |
| Trading | `/trading` | Portfolio |
| Investments | `/investments` | Portfolio |
| Insurance | `/insurance` | Insurance |
| Creator | `/creator` | More |
| Tax | `/tax` | More |
| Net Worth | `/networth` | More |
| Friends | `/friends` | More |
| Simulator | `/simulator` | More |

## Key Behaviors

- **JWT** stored in `flutter_secure_storage` (never SharedPreferences)
- **401 response** → token cleared → redirect to `/login`
- **Simulator** runs entirely in Dart — no API call
- **Indian number format** — ₹1,24,500 (not ₹124,500)
- **Friend ledger** — `amount > 0` = they owe you; `amount < 0` = you owe them
- **Insurance → tax auto-fill** — health policy → 80D, life/term → 80C
- **LTCG thresholds** — stocks/MF: 365 days; gold/silver/land: 730 days
- **Local notifications** — EMI (5 days before), credit card (3 days), insurance (7 days), advance tax (5 days before each deadline)

## Android Permissions

Declared in `AndroidManifest.xml`:
- `INTERNET`
- `RECEIVE_BOOT_COMPLETED` — reschedule notifications after reboot
- `VIBRATE`
- `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM`
- `POST_NOTIFICATIONS`

## Design System

| Token | Value |
|-------|-------|
| Background | `#0F1117` |
| Card | `#171B26` |
| Teal (primary) | `#3ECFB2` |
| Body font | Plus Jakarta Sans (via `google_fonts`) |
| Amounts font | JetBrains Mono (via `google_fonts`) |
