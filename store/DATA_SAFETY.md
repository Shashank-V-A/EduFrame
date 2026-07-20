# Google Play Data safety form — EduFrame

Use these answers when completing Play Console → App content → Data safety.

**App:** EduFrame (`com.eduframe.app`)  
**Privacy policy:** https://eduframe.vercel.app/privacy.html

## Overview

| Question | Answer |
|----------|--------|
| Does your app collect or share user data? | **Yes** |
| All user data encrypted in transit? | **Yes** (HTTPS for Google, Drive, AI proxy) |
| Can users request data deletion? | **Yes** — Settings → Delete my data (local wipe + sign out). Drive backups must be deleted by the user in Drive. |

## Data types

### Personal info

| Type | Collected | Shared | Purpose | Ephemeral? | Required? |
|------|-----------|--------|---------|------------|-----------|
| Name | Yes (Google profile) | No | App functionality (show account) | No | Yes (sign-in required) |
| Email | Yes | No | App functionality | No | Yes |
| User IDs | Yes (Google account id) | No | App functionality (scope local DB) | No | Yes |

### Photos / files (optional backup)

| Type | Collected | Shared | Purpose | Notes |
|------|-----------|--------|---------|-------|
| Files and docs | User-initiated | Shared with Google Drive if user backs up | App functionality | Only when user taps Backup to Drive |

### App activity / AI

| Type | Collected | Shared | Purpose | Notes |
|------|-----------|--------|---------|-------|
| Other in-app messages / prompts | Yes when using AI | Shared with Groq via eduframe.vercel.app proxy | App functionality | User-entered lesson context / chat; not student roster data by design |

### App info and performance (if Sentry DSN is set in the build)

| Type | Collected | Shared | Purpose |
|------|-----------|--------|---------|
| Crash logs | Yes | Shared with Sentry | Analytics / stability |
| Diagnostics | Yes | Shared with Sentry | Analytics / stability |

If you ship builds **without** `SENTRY_DSN`, answer that you do **not** collect crash logs.

### Device or other IDs

Not intentionally collected beyond what Google Sign-In / OS provide for auth.

## Data handling notes for reviewers

- **Primary storage:** on-device SQLite, **scoped per Google user id**.
- **Not collected by EduFrame servers:** full lesson plan database (no EduFrame cloud DB).
- **Notifications:** local only; no push server.
- **Children:** app targets teachers (adults), not designed for children.

## Account deletion

In-app: Settings → Delete my data → confirms wipe of local classes/plans/timetable and signs out.  
Uninstall also removes local data. Google account deletion is via Google Account settings.
