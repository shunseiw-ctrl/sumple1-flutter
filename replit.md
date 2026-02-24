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

## Recent Changes
- 2026-02-24: Code quality and security improvements
  - Removed all hardcoded admin UIDs from codebase (messages_page, sales_page, earnings_create_page, job_detail_page, app_constants)
  - Admin detection now uses Firestore `config/admins` document (uids[] and emails[] arrays)
  - Cross-platform image upload: replaced dart:io File with Uint8List (image_upload_service.dart)
  - Web platform guards: kIsWeb checks for push notifications (push_token_service.dart)
  - Firestore cache size: 40MB limit for Web, unlimited for native (firestore_setup.dart)
  - Admin login page: removed "create admin" button (security), added form validation and password toggle
  - Unified error handling with Logger and ErrorHandler classes
  - job_detail_page: adminUid fallback chain (ownerId -> adminUid -> createdBy) for legacy data compatibility
- 2026-02-24: Adapted project for Replit environment
  - Added Flutter web platform support
  - Added web Firebase configuration in `firebase_options.dart`
  - Fixed import paths in `guest_home_page.dart`
  - Fixed `BottomNavigationBarThemeData` API compatibility for Flutter 3.32
  - Downgraded SDK constraint from ^3.10.7 to ^3.8.0 for compatibility
  - Created `serve.sh` to build and serve Flutter web on port 5000
  - Configured static deployment with `build/web` as public directory

## User Preferences
- Japanese language UI (日本語)
- Firebase project: alba-work
