# EduFrame (Flutter)

Lesson plan notebook for teachers — built for planning tonight, teaching tomorrow.

## Run the app

```powershell
cd d:\Mobile-Dev
& "C:\Users\SHASHANK V A\Downloads\flutter_windows_3.44.4-stable\flutter\bin\flutter.bat" run --dart-define=GROQ_API_KEY=your_groq_key
```

Or after adding Flutter to PATH:

```bash
flutter run --dart-define=GROQ_API_KEY=your_groq_key
```

Connect your Android phone with USB debugging on, or use an emulator from Android Studio.

## One-time setup

### 1. Add Flutter to PATH

Move Flutter out of Downloads (recommended):

```
C:\src\flutter
```

Then add `C:\src\flutter\bin` to your **User PATH** in Windows Environment Variables. Restart the terminal.

### 2. Fix Android SDK path (recommended)

`flutter doctor` warns that your SDK path has spaces (`SHASHANK V A`). Move it to:

```
C:\Android\sdk
```

Then set `ANDROID_HOME` to that path in Environment Variables.

### 3. Accept Android licenses

```bash
flutter doctor --android-licenses
```

## Features

- Plan for tomorrow / today
- Structured lesson form (objectives, activities, homework, notes)
- Search old plans
- Duplicate and edit
- PDF export for HOD
- Offline SQLite storage

## Build APK for your mom (no Play Store yet)

```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

Send this file to her phone and install directly.

## Troubleshooting

### "Lost connection to device" in Android Studio

Usually the **debugger disconnects**, not a full app crash — especially on **Pixel API 36** emulators.

1. Pick **Pixel 10 API 36.1** in the device dropdown (not Windows desktop).
2. Stop any running session (red square), then Run again.
3. This project disables **Impeller/Vulkan** for emulator stability.
4. If it happens again: the app may still be open on the emulator — check the emulator screen.
5. Cold boot the emulator: **Device Manager → ⋮ → Cold Boot Now**.

### Google OAuth values

Android package name:

```text
com.eduframe.app
```

Debug SHA-1:

```text
F8:BE:BB:2B:28:EC:FB:DB:DF:43:8B:B1:A4:E7:8F:77:D0:E8:4B:03
```

Configured Android client ID:

```text
669192163812-1955h44t69ueu40bqqt25v4o3jvp8k6a.apps.googleusercontent.com
```

Configured Web client ID:

```text
669192163812-1c4eglr4tpdpj0ovh2ff3i0fppucmjui.apps.googleusercontent.com
```

### Run from terminal (alternative to Android Studio)

```powershell
cd d:\Mobile-Dev
& "C:\Users\SHASHANK V A\Downloads\flutter_windows_3.44.4-stable\flutter\bin\flutter.bat" run -d localhost:56837 --dart-define=GROQ_API_KEY=your_groq_key
```

Replace the device id with yours from `flutter devices`.

## Project

Flutter app **EduFrame** at `d:\Mobile-Dev` — open this folder in Android Studio.

---

*EduFrame — your plans, organized.*
