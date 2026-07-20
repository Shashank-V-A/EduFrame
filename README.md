# EduFrame (Flutter)

Lesson plan notebook for teachers — plan tonight, teach tomorrow.

**Package:** `com.eduframe.app` · **Privacy:** https://eduframe.vercel.app/privacy.html · **Terms:** https://eduframe.vercel.app/terms.html

## Features

- Plan for tomorrow / today with structured lesson forms
- Classes, weekly timetable, and local reminders
- Search, duplicate, edit plans
- PDF export and share
- AI Assist (via signed Groq proxy)
- Offline SQLite storage **scoped per Google account**
- Backup / restore (Google Drive or file)
- Delete-my-data from Settings
- Hindi labels and dark mode

## Run the app

```powershell
cd d:\EduFrame
flutter pub get
flutter run --dart-define=GROQ_PROXY_URL=https://eduframe.vercel.app/api/groq
```

Optional crash reporting (create a Sentry project and paste the DSN):

```powershell
flutter run --dart-define=GROQ_PROXY_URL=https://eduframe.vercel.app/api/groq --dart-define=SENTRY_DSN=https://YOUR_DSN
```

Connect an Android phone with USB debugging, or use an emulator.

## One-time setup

1. Install Flutter stable and add it to `PATH`.
2. Run `flutter doctor` and accept Android licenses: `flutter doctor --android-licenses`.
3. Configure Google Sign-In OAuth clients for `com.eduframe.app` (see Google Cloud Console).
4. Deploy / keep Vercel env vars: `GROQ_API_KEY`, and optionally `GOOGLE_WEB_CLIENT_ID` (defaults to the Web client used by the app).

## Play Store release

See **[RELEASE_BUILD.md](RELEASE_BUILD.md)** for keystore + AAB steps.

Store listing copy and Data safety answers live under **[store/](store/)**.

Legal pages are in `public/` and are served from the Vercel project (`/privacy.html`, `/terms.html`).

```powershell
flutter build appbundle --release --dart-define=GROQ_PROXY_URL=https://eduframe.vercel.app/api/groq
```

Requires `android/key.properties` and a release keystore (no debug fallback).

## Project layout

| Path | Role |
|------|------|
| `lib/` | Flutter app |
| `android/` | Android project |
| `api/groq.js` | Authenticated Groq proxy |
| `public/` | Privacy & Terms HTML |
| `store/` | Play listing text + graphics |

## Troubleshooting

### Emulator debugger disconnects

Common on some API 36 images. Debug builds disable Impeller for stability; release keeps the default renderer. Cold-boot the emulator if needed.

### Google OAuth

Android package: `com.eduframe.app`  
Add **release** SHA-1 from your upload keystore to the Android OAuth client before Play testing.

---

*EduFrame — your plans, organized.*
