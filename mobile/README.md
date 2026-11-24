# Kharcha mobile

The Flutter app for Kharcha. It talks to the Laravel API in `../backend`.

Nothing is deployed: the backend runs on your laptop, and the app reaches it
over plain HTTP, either from the Android emulator or from a phone on the same
Wi-Fi.

## Requirements

- Flutter (stable channel)
- Android Studio with an emulator, or an Android phone with USB debugging on
- The backend set up as described in the main `README.md` (database, `.env`,
  migrations)

## 1. Start the backend

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

`--host=0.0.0.0` matters: without it the server only listens on `127.0.0.1`,
and neither the emulator nor your phone can reach it.

## 2. Run on the Android emulator

```bash
cd mobile
flutter pub get
flutter run
```

No extra flags needed. The default API URL is `http://10.0.2.2:8000/api`, and
`10.0.2.2` is how the emulator reaches your laptop's `localhost`.

## 3. Run on a real phone

The phone must be on the **same Wi-Fi network** as the laptop.

Find the laptop's Wi-Fi IP (Linux):

```bash
ip addr
```

Look for your Wi-Fi interface (usually named `wlan0` or `wlp...`) and the
line starting with `inet`, for example `inet 192.168.1.20/24`. The IP is
`192.168.1.20`.

Plug in the phone and run:

```bash
flutter run --dart-define=API_URL=http://192.168.1.20:8000/api
```

Quick check: open `http://192.168.1.20:8000` in the phone's browser. If the
Laravel welcome page loads, the phone can reach the backend. If it times out,
check the IP, the Wi-Fi network and your laptop's firewall (port 8000 must be
open).

## 4. Build a release APK

Use the same `--dart-define`, because the URL is baked in at build time:

```bash
flutter build apk --release --dart-define=API_URL=http://192.168.1.20:8000/api
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`. Copy it to the
phone and install it.

Notes:

- The phone must still be on the same Wi-Fi as the laptop, and the backend
  must be running.
- If the laptop gets a new IP (different network, router restart), rebuild the
  APK with the new IP.
- Plain HTTP is allowed by `android:usesCleartextTraffic="true"` in
  `android/app/src/main/AndroidManifest.xml`. Remove it if the backend ever
  moves to HTTPS.

## Project layout

```
lib/
├── main.dart            Start screen: checks for a saved token
├── theme.dart           Colors, fonts and the app theme
├── format.dart          Money and date formatting
├── models/              User, Expense
├── services/
│   ├── api.dart         HTTP client (auth header, 401/422/network errors)
│   └── auth_storage.dart Token and user in secure storage
├── screens/             Login, Register, Expenses
└── widgets/             Logo, form fields, expense card, summary card,
                         add/edit bottom sheet
```
