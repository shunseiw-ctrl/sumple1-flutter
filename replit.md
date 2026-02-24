# ALBAWORK (sumple1)

## Overview
A Flutter-based job matching application for the construction industry (建設業界の仕事マッチングアプリ). Originally built as a mobile app (Android/iOS), now configured to also run as a Flutter web application on Replit.

## Project Architecture
- **Framework**: Flutter 3.32.0 (Dart 3.8.0)
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **Server**: Node.js (server.js) - static file server + LINE OAuth handler
- **Cloud Functions**: Node.js 18, Firebase Functions v2
- **Platform**: Web (adapted from mobile-only project)

### Directory Structure
- `lib/` - Main Dart source code
  - `core/` - Services, utils, constants, enums
  - `core/services/line_auth_service.dart` - LINE login client-side handler
  - `core/services/web_redirect.dart` - Web redirect with conditional import (web/stub)
  - `data/` - Models and repositories
  - `pages/` - Page widgets
  - `presentation/` - Presentation layer (guest pages, widgets)
  - `services/` - Additional services (push notifications)
- `web/` - Flutter web platform files
- `functions/` - Firebase Cloud Functions (Node.js)
- `server.js` - Node.js server: static files + LINE OAuth + token exchange
- `android/` - Android platform files
- `ios/` - iOS platform files
- `build/web/` - Built Flutter web output (served on port 5000)

## Running the App
- The workflow runs `serve.sh` which builds Flutter web and runs `server.js` on port 5000
- Firebase is used for authentication, data storage, and cloud functions
- The app starts with a guest login page (anonymous auth)

## LINE Login Integration
- OAuth 2.0 flow via server.js (LINE Login v2.1)
- Flow: User clicks LINE button → server redirects to LINE → LINE callback → server exchanges code for token → server creates Firebase custom token → one-time exchange code returned to client via URL fragment → client exchanges code for Firebase token via POST /auth/line/exchange → signInWithCustomToken
- Requires: LINE_CHANNEL_ID, LINE_CHANNEL_SECRET (secrets), FIREBASE_SERVICE_ACCOUNT (secret, JSON string)
- LINE Channel ID: 2009209066
- Callback URL must be configured in LINE Developer Console
- Security: CSRF state parameter, one-time token exchange (not passed in URL), server-side token validation

## Admin Management
- Admin status is determined by Firestore document `config/admins`
- The document contains `adminUids[]` and `emails[]` arrays
- AuthService.getCurrentUserRole() checks both arrays to determine admin role
- No hardcoded admin UIDs in the codebase (removed for security)

## Security Measures
- Server: Path traversal prevention, security headers (X-Content-Type-Options, X-XSS-Protection, Referrer-Policy, Permissions-Policy), GET/HEAD only for static files
- LINE OAuth: CSRF state parameter, one-time exchange codes (5min expiry), no tokens in URL params
- Auth: Client-side login rate limiting (5 attempts, 3 min lockout) on both admin and user login
- Error messages: Generic auth error messages to prevent user enumeration (user-not-found/wrong-password merged)
- Logging: Debug/info logs suppressed in release builds, error/warning logs retained
- Firebase API key: Public by design (Firebase Web SDK), should be restricted via Firebase Console (HTTP referrer restrictions)

## Three-Tier User System
- **Guest (ゲスト)**: Anonymous Firebase auth, can browse jobs but restricted from applying/messages/earnings/work tabs
  - Guest guard shows styled placeholder with registration CTA button
  - RegistrationPromptModal offers LINE or email registration
- **Worker (職人)**: Registered user (email or LINE login), full access to all features
  - Same 5-tab layout: 検索, はたらく, メッセージ, 売上, マイページ
  - はたらく tab preserves original worker-focused design
- **Admin (ALBALIZE管理者)**: Detected via Firestore config/admins, completely separate dashboard
  - AdminHomePage with 5 tabs: ダッシュボード, 案件管理, 応募者, 売上管理, 設定
  - Dashboard shows real-time counts (jobs, applications, users)
  - AuthGate routes: null→GuestHomePage, anonymous→HomePage, admin→AdminHomePage, worker→HomePage

## Firestore Collections
- `profiles/{uid}` - User profiles: name, kana, birthDate, gender, address, introduction, experienceYears, qualifications[], profilePhotoUrl, profilePhotoLocked
- `favorites/{uid}` - User favorites: jobIds[] array
- `ratings` - Job ratings: applicationId, jobId, raterUid, stars, comment, createdAt
- `notifications` - In-app notifications: targetUid, title, body, type (application/status_update), read, createdAt
- `applications` - Job applications: includes checkInAt, checkOutAt, checkInStatus fields for GPS check-in/out
  - `applications/{appId}/photos` - Work photos subcollection: url, uploadedBy, createdAt
  - `applications/{appId}/documents` - Work documents subcollection: url, folder, uploadedBy, createdAt
- `identity_verification/{uid}` - ID verification: idPhotoUrl, selfieUrl, status (pending/approved/rejected), submittedAt
- `earnings` - Payment records: amount, paymentStatus (paid/unpaid), createdAt

## Key Services
- `FavoritesService` - Manages job favorites in Firestore for registered users, in-memory for guests
- `NotificationService` - Creates/reads in-app notifications, unread count stream, mark as read
- `RatingDialog` - Modal widget for 5-star job rating after completion
- `ImageUploadService` - Multi-image picker, compression, Firebase Storage upload with progress
- `ChatService` - Chat room initialization, message sending with retry, unread count management

## Recent Changes
- 2026-02-24: World-class UI Polish & Micro-interactions
  - Branded splash screen: CSS gradient with animated logo, spinner, fade-out transition (web/splash.css, web/index.html)
  - Splash removal: conditional import pattern (splash_remover.dart/web/stub), 10s fallback timer
  - Service worker disabled for dev (--pwa-strategy=none, unregister in index.html)
  - 3-page onboarding flow: PageView with dot indicators, SharedPreferences persistence, gradient CTA
  - Custom onboarding illustrations: onboarding_search/earn/safety.png (assets/images/)
  - EmptyState illustrations: empty_jobs/messages.png for empty state screens
  - StaggeredFadeSlide widget: staggered list entry animations (50ms delay, 400ms duration, 30px slide)
  - ScaleTap widget: press-scale feedback (0.97x, 100ms), used on interactive cards
  - Job card urgency badges: "残りX枠" (red when ≤2), "即日勤務OK", "/日" salary units
  - Dark mode support: AppDarkColors class, ThemeMode.system, dark surface/background colors
  - Typography refinement: tighter letter-spacing, larger display sizes (42px/900w), new caption/overline
  - Search bar header on job list page
  - pubspec.yaml: assets/images/ directory included
- 2026-02-24: Professional UI Modernization (3-tier)
  - Design system: app_colors.dart (gradients, semantic colors), app_spacing.dart (8-point scale), app_text_styles.dart (Noto Sans JP typography hierarchy), app_shadows.dart (5-level elevation)
  - Shared widgets: skeleton_loader.dart (shimmer animation), empty_state.dart (gradient icon + CTA), status_badge.dart (pill badges, 7 Japanese statuses), app_card.dart (modern cards)
  - Theme: Material 3, Google Fonts Noto Sans JP, 52px buttons, custom InputDecoration, SnackBar, TabBar, Card, Chip, Divider themes
  - Page transitions: CupertinoPageTransitionsBuilder for all platforms
  - Job list: Hero image cards with gradient overlay, category tags, skeleton loading, EmptyState
  - Job detail: 200px hero image, modern info cards with shadows, gradient apply button, AnimatedSwitcher favorite
  - Guest home: Full-screen gradient hero, frosted glass feature cards, gradient CTA buttons, animated fade-in
  - Home: Custom _ModernBottomNav with animated indicator line, Poppins title, dot notification badge
  - Profile: Gradient avatar ring, menu groups with colored icons, section accent bars, modern dialogs
  - Work/Messages/Notifications/Sales: EmptyState widgets, StatusBadge.fromStatus(), AppShadows throughout
  - Dependencies added: google_fonts ^6.2.1, shared_preferences ^2.3.4
- 2026-02-24: 11 quality/UX improvement features
  - Search filters: Bottom sheet with area, salary range slider, qualification chips, date range pickers
  - Favorites page: TabBar in sales tab (売上/お気に入り), favorited jobs with thumbnails and instant removal
  - Application status tab: Leftmost tab in work page, grouped by 応募中/承認済み/完了
  - Identity verification: ID photo + selfie upload → auto profile photo (locked after verification)
  - Chat enhancement: LINE-like UI (green bubbles, date separators, avatars, rounded input)
  - Admin approve/reject: Filter chips, one-click approve/reject with confirmation dialog and notifications
  - Admin sales management: Monthly aggregation with total/paid/unpaid tracking
  - Photo/document upload: 200+ photos grid view, 5-folder document management (御見積書/図面/仕様/工程/その他)
  - Responsive design: MaxWidth constraints, SafeArea, font size optimization
  - PWA support: Manifest with ALBAWORK branding, Apple meta tags, theme color
  - New pages: identity_verification_page.dart
  - New widgets: responsive_container.dart
- 2026-02-24: Five new features implemented
  - Favorites: Heart icon on job cards/detail, FavoritesService (Firestore for registered, in-memory for guests)
  - Rating system: RatingDialog (5-star + comment), shown on work_detail when status='done', stored in ratings collection
  - GPS check-in/out: Check-in/check-out buttons on work_detail for in_progress/assigned status, timestamps in Firestore
  - Profile enhancement: Experience years, self-introduction, qualifications with suggestion chips (足場組立, 玉掛け, etc.)
  - In-app notifications: Bell icon with unread badge on home/admin pages, NotificationsPage, auto-notify on apply/status change
- 2026-02-24: LINE Login integration
  - server.js: Full Node.js server replacing inline serve.sh, handles LINE OAuth flow + static serving
  - LINE OAuth: Authorization code flow, token exchange, Firebase custom token generation
  - One-time exchange code pattern for secure token delivery (no tokens in URL)
  - LINE login button on guest_home_page.dart and profile_page.dart (green LINE color #06C755)
  - LineAuthService: Handles callback processing, token exchange via HTTP POST
  - Web redirect conditional import (web_redirect.dart/web_redirect_impl.dart/web_redirect_stub.dart)
  - Dependencies added: web, http packages in pubspec.yaml; firebase-admin, axios in package.json
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
- 2026-02-24: Brand color theme update (瑠璃色 #1E50A2)
  - Created lib/core/constants/app_colors.dart with centralized color definitions
  - Updated ThemeData in main.dart: ruri accent, white/light base
  - Updated all 16 page files to use AppColors instead of hardcoded colors
  - LINE green button preserved, text readability maintained
- 2026-02-24: Three-tier user system implementation
  - AuthService: anonymous users now return UserRole.guest (was incorrectly returning UserRole.user)
  - RegistrationPromptModal: modal dialog guiding guests to LINE or email registration
  - Guest guards: work_page, messages_page, sales_page show styled placeholders with registration CTA
  - job_detail_page: apply button shows RegistrationPromptModal for guests instead of SnackBar
  - AdminHomePage: new admin dashboard with 5 tabs (dashboard/jobs/applicants/earnings/settings)
  - AuthGate (main.dart): StatefulWidget with role-based routing and caching
- 2026-02-24: Adapted project for Replit environment
  - Flutter web platform support, Firebase config, API compatibility fixes

## User Preferences
- Japanese language UI (日本語)
- Firebase project: alba-work
- Multi-platform target: Web, iOS, Android (App Store/Google Play)
