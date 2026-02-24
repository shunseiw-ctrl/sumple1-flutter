# ALBAWORK (sumple1)

## Overview
ALBAWORK is a Flutter-based job matching application specifically designed for the construction industry (建設業界の仕事マッチングアプリ). It facilitates job discovery and application for workers and streamlines management for administrators. Originally developed for mobile platforms (Android/iOS), the project has been adapted to also function as a Flutter web application on Replit. The project aims to provide a robust, secure, and user-friendly platform with features like a three-tier user system, LINE login integration, advanced job management, and real-time notifications.

## User Preferences
- Japanese language UI (日本語)
- Firebase project: alba-work
- Multi-platform target: Web, iOS, Android (App Store/Google Play)

## System Architecture
The application is built with Flutter 3.32.0 (Dart 3.8.0) and utilizes Firebase for its backend services, including Firestore for data storage, Authentication, Storage, and Messaging. A Node.js server (`server.js`) handles static file serving and LINE OAuth processes, complemented by Firebase Cloud Functions (Node.js 18, v2) for server-less logic.

**Core Features:**
- **Three-Tier User System**:
    - **Guest (ゲスト)**: Anonymous Firebase authentication, limited browsing.
    - **Worker (職人)**: Registered users (email/LINE), full access to job search, applications, messages, earnings, and profile management.
    - **Admin (ALBALIZE管理者)**: Dedicated dashboard for managing jobs, applicants, earnings, and settings, identified via Firestore `config/admins` document.
- **LINE Login Integration**: Implements OAuth 2.0 flow via a Node.js server, exchanging LINE authorization codes for Firebase custom tokens, ensuring secure authentication.
- **Job Management**: Features include job listing, detail viewing, favoriting, application submission, and GPS check-in/out for work completion tracking.
- **Communication**: Integrated chat functionality for workers and administrators.
- **Earnings & Payments**: Tracking of worker earnings and payment records.
- **Identity Verification**: Workflow for users to upload ID photos and selfies for verification, which can lock their profile photo.
- **Notifications**: In-app notification system with unread counts for important updates (e.g., application status changes).
- **Admin Dashboard**: Provides real-time insights into jobs, applications, and users.
- **UI/UX & Design System**:
    - Adheres to Material 3 design principles with custom themes, typography (Noto Sans JP), and color palettes (e.g., 瑠璃色 #1E50A2 as accent).
    - Utilizes an 8-point spacing scale, 5-level elevation shadows, and semantic colors.
    - Features modern UI elements like skeleton loaders, animated empty states, status badges, and custom card designs.
    - Includes responsive design for various screen sizes, PWA support, and platform-specific transitions.
    - Incorporates micro-interactions such as staggered list entry animations (`StaggeredFadeSlide`) and press-scale feedback (`ScaleTap`).
    - Dark mode support is implemented.
- **Error Handling**: Comprehensive error handling with `ErrorHandler` for classifying and displaying user-friendly messages. Includes `ErrorRetryWidget` for UI feedback and `OfflineBanner` for network status.
- **Security**: Measures include path traversal prevention, security headers, login rate limiting, generic error messages to prevent user enumeration, and server-side token validation for LINE OAuth. Admin UIDs are not hardcoded.

**Directory Structure:**
- `lib/`: Main Dart source code, organized into `core/`, `data/`, `pages/`, `presentation/`, and `services/`.
- `web/`: Flutter web platform files.
- `functions/`: Firebase Cloud Functions.
- `server.js`: Node.js server for static files and LINE OAuth.

## External Dependencies
- **Firebase**: Firestore, Authentication, Storage, Messaging, Cloud Functions (Node.js 18, v2).
- **LINE Login API**: Used for OAuth 2.0 integration.
- **Node.js**: Runtime environment for `server.js` and Firebase Cloud Functions.
- **Google Fonts**: Specifically Noto Sans JP, for consistent typography.
- **`shared_preferences` package**: For local data persistence (e.g., onboarding status).
- **`web` package**: For web-specific functionalities in Flutter.
- **`http` package**: For making HTTP requests.
- **`firebase-admin` (Node.js)**: For Firebase operations within the backend.
- **`axios` (Node.js)**: For HTTP client requests in `server.js`.