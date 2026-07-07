# EduFrame Groq proxy (Vercel)

Secure Groq access for the mobile app. The Groq API key stays on the server.

## Deploy

1. Install Vercel CLI: `npm i -g vercel`
2. From this `server/` folder:

```bash
cd server
vercel
```

3. Set the secret in Vercel:

```bash
vercel env add GROQ_API_KEY
```

4. Production proxy URL: `https://server-tau-kohl.vercel.app/api/groq`

## Run the Flutter app with proxy

The app uses the production proxy by default. No extra flags needed:

```powershell
flutter run
```

Override proxy URL (optional):

```powershell
flutter run --dart-define=GROQ_PROXY_URL=https://server-tau-kohl.vercel.app/api/groq
```

Release build:

```powershell
flutter build apk --release --dart-define=GROQ_PROXY_URL=https://server-tau-kohl.vercel.app/api/groq
```

The app sends the signed-in user's Google ID token. For production, verify the token on the server (optional hardening step).

## Local dev fallback

Without `GROQ_PROXY_URL`, the app falls back to `--dart-define=GROQ_API_KEY=...` for testing only.
