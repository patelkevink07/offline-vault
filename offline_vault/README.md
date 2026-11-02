# Offline Vault

A Flutter application for securely syncing and viewing photos and documents offline within private groups. Files are encrypted and shared only with group members — once synced, no internet connection is needed to access them.

## Prerequisites

- **Flutter SDK** ≥ 3.22
- **Dart SDK** ≥ 3.4
- **Android SDK** (API 21+)
- **Supabase CLI** ≥ 1.100
- A **Supabase** project (free tier works)

## Setup

### 1. Clone the repository

```bash
git clone <repo-url>
cd offline_vault
```

### 2. Create your environment file

```bash
cp .env.example .env
```

Edit `.env` and fill in your Supabase project URL and anon key. You can find these in the Supabase dashboard under **Settings → API**.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Link Supabase

```bash
supabase link --project-ref <your-project-ref>
```

### 5. Push database migrations

```bash
supabase db push
```

### 6. Generate code

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Build & Run

```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# Release App Bundle
flutter build appbundle --release
```

## Localization

The app supports English, Gujarati (ગુજરાતી), and Hindi (हिन्दी). ARB files are located in `lib/l10n/`. To regenerate localization files:

```bash
flutter gen-l10n
```

## Project Status

> **Phase 0** — Foundation & core screens (onboarding, sign-in, groups home). More phases coming soon covering file management, sync engine, media viewer, and sharing features.
