# EduFrame Groq proxy (Vercel)

Secure Groq access for the mobile app. The Groq API key stays on the server.

**Production URL:** `https://eduframe.vercel.app/api/groq`

## Git auto-deploy

The API lives at the **repo root** (`/api/groq.js` + `/vercel.json`) so Vercel can deploy from the connected EduFrame GitHub repo without a custom root directory.

Every push to `main` redeploys the proxy. `GROQ_API_KEY` is stored in Vercel env vars (not in git).

**Vercel project:** `eduframe.vercel.app` (dashboard may still show project name `server`)

## Run the Flutter app

The app uses the production proxy by default:

```powershell
flutter run
```

Release build:

```powershell
flutter build apk --release
```

## Local dev fallback

To bypass the proxy and call Groq directly during testing:

```powershell
flutter run --dart-define=GROQ_PROXY_URL= --dart-define=GROQ_API_KEY=your_key
```

The app sends the signed-in user's Google ID token with each proxy request.
