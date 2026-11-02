# OFFLINE VAULT: USER GUIDE & ARCHITECTURE MANUAL

Offline Vault is an Android application engineered for secure, private sharing of images and PDF documents. 

**Core Principle**: Uploading and syncing use the internet. **Viewing never does.** Once a file reaches a device, it is encrypted and stored locally in app-private storage, opening instantly without requiring an active connection.

---

## 1. Quick Start Guide (English)

### Step 1: Install & First Launch
1. Install the APK on your Android phone (Android 8.0+ / API 26+).
2. Launch the app and swipe through the 3-slide introduction explaining offline storage, zero-network viewing, and encryption.
3. Tap **Get Started**.

### Step 2: Sign In
- Tap **Continue with Google** or enter your email to receive a 6-digit one-time code (OTP).
- Once signed in, your session persists indefinitely offline. If network drops occur, the app remains fully accessible and never logs you out.

### Step 3: Vault Operations
- **Create a Vault**: Tap **Create group**, pick a name and color. An 8-character invite code (e.g. `XXXX-XXXX`) is automatically generated.
- **Join a Vault**: Tap **Join with code** or scan a QR code shared by another vault owner. You join instantly as a **Viewer** with immediate access to all vault contents.
- **Add Files**: Inside any vault, tap `+` to pick photos or PDFs. Choose your compression preference:
  - *Original*: Best fidelity, uncompressed.
  - *High Quality* (Default): 85% quality, 2048px max dimension.
  - *Data Saver*: 70% quality, 1280px max dimension.
- **Offline Viewing**: Once downloaded or uploaded, images and PDFs render instantly from the encrypted local store. You can zoom, pan, and read documents completely in airplane mode.

---

## 2. વપરાશકર્તા માર્ગદર્શિકા (Gujarati User Guide)

### પગલું 1: ઇન્સ્ટોલ અને પ્રથમ ઉપયોગ
1. તમારા Android ફોન પર એપ્લિકેશન ઇન્સ્ટોલ કરો.
2. ઑફલાઇન વૉલ્ટ 3 સ્લાઇડ દ્વારા સંપૂર્ણ ઑફલાઇન અને એન્ક્રિપ્ટેડ સુવિધાઓ સમજાવશે.
3. **શરૂ કરો** પર ક્લિક કરો.

### પગલું 2: સાઇન ઇન કરો
- **Google વડે ચાલુ રાખો** પર ક્લિક કરો અથવા તમારા ઇમેઇલ પર 6-અંકનો વન-ટાઇમ પાસવર્ડ (OTP) મેળવો.
- એકવાર સાઇન ઇન થયા પછી, ઇન્ટરનેટ ન હોય તો પણ એપ ક્યારેય સાઇન આઉટ થશે નહીં.

### પગલું 3: વૉલ્ટનો ઉપયોગ
- **નવું જૂથ બનાવો**: **જૂથ બનાવો** પર ટૅપ કરો. તમારા જૂથ માટે આપમેળે 8-અક્ષરનો ગુપ્ત કોડ બનશે.
- **કોડ વડે જોડાઓ**: મિત્ર કે પરિવાર તરફથી મળેલો કોડ નાખીને અથવા QR કોડ સ્કેન કરીને તરત જ જોડાઈ જાઓ.
- **સંપૂર્ણ ઑફલાઇન દર્શન**: બધા ફોટા અને પીડીએફ ફાઇલો તમારા ફોનમાં સુરક્ષિત એન્ક્રિપ્ટેડ સ્વરૂપે સચવાય છે, જે એરોપ્લેન મોડમાં પણ તુરંત ખૂલે છે.

---

## 3. Architecture & Technical Verification

- **Local Database**: Drift (SQLite) with FTS5 search index (`lib/data/local/database.dart`).
- **Encryption at Rest**: AES-256-GCM authenticated encryption with 96-bit random nonce (`lib/core/crypto/crypto_service.dart`). Keys reside exclusively in Android Keystore (`lib/core/crypto/key_manager.dart`).
- **Resumable Sync Engine**: Single-mutex background reconciler (`lib/sync/sync_engine.dart`) supporting HTTP Range headers, thumbnails-first downloads, and auto-purging of revoked memberships.
- **Backend Schema & Security**: 6 full SQL migrations in `supabase/migrations/` implementing profiles, groups, folders, files, invite codes, RLS, and SECURITY DEFINER RPC functions (`create_group`, `join_group`, `rotate_invite_code`).
- **pgTAP Test Suite**: Included in `supabase/tests/00_schema_test.sql` covering schema, functions, and RLS integrity.
- **Linter & Test Verification**: `flutter analyze` reports 0 issues; unit tests for crypto and data models pass 100%.
