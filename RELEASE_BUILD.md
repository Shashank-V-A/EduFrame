# Release signing for EduFrame (Android)

## 1. Create a release keystore (one time)

```powershell
keytool -genkey -v -keystore d:\Mobile-Dev\android\eduframe-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias eduframe
```

Store the passwords safely. **Never commit the `.jks` file.**

## 2. Create key.properties

Copy `android/key.properties.example` to `android/key.properties` and fill in:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=eduframe
storeFile=eduframe-release.jks
```

## 3. Add release SHA-1 to Google Cloud Console

```powershell
keytool -list -v -keystore d:\Mobile-Dev\android\eduframe-release.jks -alias eduframe
```

Add the SHA-1 to the same OAuth Android client (`com.eduframe.app`).

## 4. Build release APK

With Groq proxy (recommended):

```powershell
cd d:\Mobile-Dev
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter build apk --release --dart-define=GROQ_PROXY_URL=https://server-tau-kohl.vercel.app/api/groq
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## 5. Play Store

- Create a privacy policy (data stored locally + optional Google Drive backup)
- Use the release APK or App Bundle: `flutter build appbundle --release ...`
