# EduFrame AI proxy (Vercel)

Production URL: `https://eduframe.vercel.app/api/groq`

## Environment variables (Vercel)

| Variable | Required | Notes |
|----------|----------|-------|
| `GROQ_API_KEY` | Yes | Groq API secret |
| `GOOGLE_WEB_CLIENT_ID` | Recommended | Web OAuth client; defaults to the app’s configured Web client ID |

## Auth

Every `POST` must include `Authorization: Bearer <Google ID token>`. The proxy verifies the token with `google-auth-library` (audience = Web client ID) and applies a simple per-user rate limit (~30 requests / minute).

## Legal pages

Static HTML in `/public`:

- https://eduframe.vercel.app/privacy.html
- https://eduframe.vercel.app/terms.html

## Local dependency install

From the repo root (needed for Vercel / local Node checks):

```bash
npm install
```
