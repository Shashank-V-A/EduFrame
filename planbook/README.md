# PlanBook (Flutter)

Lesson plan notebook for teachers — built for planning tonight, teaching tomorrow.

## Run the app

```powershell
cd d:\Mobile-Dev\planbook
& "C:\Users\SHASHANK V A\Downloads\flutter_windows_3.44.4-stable\flutter\bin\flutter.bat" run
```

Or after adding Flutter to PATH:

```bash
flutter run
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

## Projects in this folder

| Folder | Stack | Use |
|--------|-------|-----|
| `planbook/` | **Flutter** ← use this | Play Store, full native app |
| `lesson-plan-notebook/` | Expo/React Native | Quick prototype via Expo Go |

---

*Your plans, organized. Not a robot teacher.*
