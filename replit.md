# ALBAWORK (sumple1)

## Overview
A Flutter-based job matching application for the construction industry (建設業界の仕事マッチングアプリ). Originally built as a mobile app (Android/iOS), now configured to also run as a Flutter web application on Replit.

## Project Architecture
- **Framework**: Flutter 3.32.0 (Dart 3.8.0)
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **Cloud Functions**: Node.js 18, Firebase Functions v2
- **Platform**: Web (adapted from mobile-only project)

### Directory Structure
- `lib/` - Main Dart source code
  - `core/` - Services, utils, constants, enums
  - `data/` - Models and repositories
  - `pages/` - Page widgets
  - `presentation/` - Presentation layer (guest pages, widgets)
  - `services/` - Additional services (push notifications)
- `web/` - Flutter web platform files
- `functions/` - Firebase Cloud Functions (Node.js)
- `android/` - Android platform files
- `ios/` - iOS platform files
- `build/web/` - Built Flutter web output (served on port 5000)

## Running the App
- The workflow runs `serve.sh` which builds Flutter web and serves it on port 5000
- Firebase is used for authentication, data storage, and cloud functions
- The app starts with a guest login page (anonymous auth)

## Admin Management
- Admin status is determined by Firestore document `config/admins`
- The document contains `uids[]` and `emails[]` arrays
- AuthService.getCurrentUserRole() checks both arrays to determine admin role
- No hardcoded admin UIDs in the codebase (removed for security)

## Security Measures
- Server: Path traversal prevention, security headers (X-Content-Type-Options, X-Frame-Options, X-XSS-Protection, Referrer-Policy, Permissions-Policy), GET/HEAD only
- Auth: Client-side login rate limiting (5 attempts, 3 min lockout) on both admin and user login
- Error messages: Generic auth error messages to prevent user enumeration (user-not-found/wrong-password merged)
- Logging: Debug/info logs suppressed in release builds, error/warning logs retained
- Firebase API key: Public by design (Firebase Web SDK), should be restricted via Firebase Console (HTTP referrer restrictions)

## Recent Changes
- 2026-02-24: Security hardening
  - serve.sh: Path traversal prevention, security headers, method restriction, malformed URI handling
  - Login rate limiting: 5 attempts max, 3 min lockout on admin_login_page and profile_page
  - Error message improvements: Generic auth errors to prevent user enumeration
  - Logger: Suppress debug/info logs in release builds (keep error/warning)
  - ErrorHandler: Remove raw exception details from user-facing messages
- 2026-02-24: Code quality and security improvements
  - Removed all hardcoded admin UIDs from codebase
  - Admin detection via Firestore config/admins document
  - Cross-platform image upload (Uint8List), Web platform guards
  - Firestore cache size limits for Web
  - Admin login page: removed "create admin" button, added form validation
  - job_detail_page: adminUid fallback chain for legacy data
- 2026-02-24: Adapted project for Replit environment
  - Flutter web platform support, Firebase config, API compatibility fixes
  - serve.sh for building and serving on port 5000

## User Preferences
- Japanese language UI (日本語)
- Firebase project: alba-work
