# Release signing & Play Store upload (EduFrame)

## 1. Create a release keystore (one time)

```powershell
cd d:\EduFrame\android
keytool -genkey -v -keystore eduframe-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias eduframe
```

Store the passwords safely (password manager). **Never commit** `eduframe-release.jks` or `key.properties`.

## 2. Create `android/key.properties`

Copy `android/key.properties.example` to `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=eduframe
storeFile=eduframe-release.jks
```

`storeFile` is relative to the `android/app` module directory when resolved by Gradle — put the `.jks` next to `key.properties` under `android/` and set:

```properties
storeFile=../eduframe-release.jks
```

Or place the keystore at `android/app/eduframe-release.jks` with `storeFile=eduframe-release.jks`.

## 3. Add release SHA-1 to Google Cloud Console

```powershell
keytool -list -v -keystore d:\EduFrame\android\eduframe-release.jks -alias eduframe
```

Add the SHA-1 (and SHA-256) to the Android OAuth client for `com.eduframe.app`.

## 4. Build the Play App Bundle (AAB)

```powershell
cd d:\EduFrame
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter build appbundle --release --dart-define=GROQ_PROXY_URL=https://eduframe.vercel.app/api/groq
```

Optional crash reporting:

```powershell
flutter build appbundle --release `
  --dart-define=GROQ_PROXY_URL=https://eduframe.vercel.app/api/groq `
  --dart-define=SENTRY_DSN=https://YOUR_PUBLIC_DSN
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Release builds **fail** if `android/key.properties` is missing (no debug-keystore fallback).

## 5. Play Console checklist

- [ ] Privacy policy URL: `https://eduframe.vercel.app/privacy.html`
- [ ] Terms URL: `https://eduframe.vercel.app/terms.html`
- [ ] Upload AAB; enroll in Play App Signing
- [ ] Store listing text + graphics under `store/`
- [ ] Complete Data safety using `store/DATA_SAFETY.md`
- [ ] Content rating questionnaire
- [ ] Set Vercel env `GROQ_API_KEY` and optionally `GOOGLE_WEB_CLIENT_ID`

## 6. Sideload APK (testing only)

```powershell
flutter build apk --release --dart-define=GROQ_PROXY_URL=https://eduframe.vercel.app/api/groq
```

APK: `build/app/outputs/flutter-apk/app-release.apk`
