# vaultOFF: USER GUIDE & ARCHITECTURE MANUAL

**vaultOFF** is an Android application engineered for secure, zero-knowledge offline sharing of photos and PDF documents.

**Core Principle**: Uploading and syncing use the internet. **Viewing never does.** Once a file reaches a device, it is encrypted locally with AES-256-GCM and stored in app-private storage, opening instantly without requiring an active connection.

---

## 1. Quick Start Guide (English)

### Step 1: Install & First Launch
1. Install the APK on your Android phone (Android 8.0+ / API 26+).
2. Launch vaultOFF and navigate the introduction slides explaining offline storage, zero-network viewing, and authenticated encryption.
3. Tap **Get Started**.

### Step 2: Sign In & Offline Mode
- Tap **Continue with Google**, enter your email to receive a 6-digit OTP code, or tap **Offline Mode** to use vaultOFF entirely locally.
- Once signed in, your session persists indefinitely offline. The app never logs you out when offline.

### Step 3: Vault Operations & 4-Digit Codes
- **Create a Vault**: Tap **Create group**, pick a name and color. An initial 4-digit code (e.g. `4829`) with 24-hour expiry is generated.
- **Join a Vault**: Tap **Join with code**. Enter the 4-digit numeric code into the 4-box keypad or tap **Scan QR**. You join instantly as a **Viewer** (or Editor if granted, or Pending if the owner requires manual approval).
- **Share & Members**:
  - View the 4-digit code in tabular figures with QR code.
  - Set expiration: **1 hour**, **24 hours**, or **7 days**.
  - Toggle **Approve new members myself**.
  - Change member roles (**Owner**, **Editor**, **Viewer**) or remove members.
  - Leave vault: Non-owners can leave any vault, which immediately wipes all downloaded files and thumbnails from their device.
- **Add Files**: Inside any vault, tap `+` to pick photos or PDFs. Choose your compression preference:
  - *Original*: Best fidelity, uncompressed.
  - *High Quality* (Default): 85% quality, 2048px max dimension.
  - *Data Saver*: 70% quality, 1280px max dimension.
- **Offline Viewing**: Once downloaded or uploaded, images and PDFs render instantly from the encrypted local store. You can zoom, pan, and read documents completely in airplane mode.

---

## 2. Security & Engineering Architecture

### Phase 1: PIN & App Lock (Security)
- **PBKDF2-HMAC-SHA256**: Passwords/PINs are salted with a 16-byte cryptographically secure random salt, hashed using 100,000 iterations of PBKDF2-HMAC-SHA256, and compared in constant time.
- **Lockout Escalation**: After 5 failed attempts, exponential lockout delays (30s, 1m, 5m, 15m, 1h) are enforced and persisted in secure storage across device reboots and app force-closes.
- **Biometric Unlock**: Biometric prompt (fingerprint/face) unlocks the vault, with the PIN always available as fallback.

### Phase 2: Sync Engine & Server-Based Cursors
- **Server Clock Tracking**: The sync cursor strictly tracks the Supabase server's `updated_at` and tiebreaker row `id`, immune to local phone clock skew.
- **5-Minute Safety Overlap**: Each sync query steps back 5 minutes from the previous cursor to capture any concurrent transactions committed out of order.
- **Atomic Drift Transactions**: Metadata for folders and files is committed in a single atomic SQLite transaction, ensuring the cursor only advances on commit.

### Phase 3: Soft-Delete Queue & Conflict Precedence
- **Immediate Local Hiding**: Deleted files/folders are immediately hidden locally (`pendingDelete = true`).
- **Persistent Delete Queue**: Deletions are enqueued to SQLite `DeleteQueue` and synced online via `deleted = true`.
- **Delete-Wins Precedence**: Deletions always take precedence over incoming concurrent remote edits.
- **Viewer "Remove from this phone"**: Deletes the local decrypted file from disk, keeps the thumbnail, and sets status to `remote`.

### Phase 4: Database Security & Secret Hardening
- **Row Level Security (RLS)**: Enforced on all tables (`groups`, `group_members`, `invite_codes`, `folders`, `files`, `join_attempts`).
- **Storage Policies**: Scoped strictly by group membership `public.is_member(group_id)`.
- **Configuration via `--dart-define`**: Backend secrets and credentials are never hardcoded. All keys are supplied via `--dart-define`.

### Phase 5: Background Sync & Concurrency Lease Mutex
- **Workmanager Background Sync**: Periodic 6-hour background sync (Wi-Fi + charging) and one-off reconnect sync with 15-minute backoff.
- **Database Lease Mutex**: Isolate lease coordinator (`SyncLeaseManager`) prevents concurrent SQLite access between foreground app and background worker. The foreground app always preempts background sync within 2 seconds.
- **Battery Optimization In-App Guide**: Quick guide and direct Android settings intent to ensure reliable background sync.

### Phase 6: Member Management & Immediate Wipe
- **Role Control**: Owners can promote members between Editor and Viewer or remove them.
- **Instant Local Wipe**: Leaving or being removed from a vault immediately purges all encrypted originals and thumbnails from the device.

---

## 3. Production Release & Build Instructions

### Building Release APKs
Run the release build with ABI splitting and compile-time defines:

```bash
flutter build apk --release --split-per-abi \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-anon-key" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="your-client-id.apps.googleusercontent.com"
```

### Keystore Configuration for Release Signing
To sign with your custom production release keystore:
1. Copy `android/key.properties.example` to `android/key.properties`:
   ```bash
   cp android/key.properties.example android/key.properties
   ```
2. Populate `key.properties` with your keystore path, alias, and passwords (do **NOT** commit `key.properties` to version control).
3. Alternatively, supply them as environment variables in CI/CD:
   - `KEYSTORE_STORE_FILE`
   - `KEYSTORE_KEY_ALIAS`
   - `KEYSTORE_STORE_PASSWORD`
   - `KEYSTORE_KEY_PASSWORD`

---

## 4. Phase 8: Operational & Infrastructure Checklist

1. **Supabase Idle Project Pause Prevention**:
   - Free-tier Supabase projects pause after 7 days of inactivity.
   - Set up an external ping (e.g. GitHub Actions scheduled workflow, CronJob, or UptimeRobot) calling the Supabase REST health endpoint `GET https://<project-ref>.supabase.co/rest/v1/` with the anon key header every 48 hours.

2. **Automated Database Backups**:
   - In Supabase Dashboard -> **Database** -> **Backups**, verify daily backups are active.
   - For additional redundancy, configure `pg_dump` via GitHub Actions or cloud bucket sync.

3. **Google OAuth SHA-1 & SHA-256 Fingerprints**:
   - In Google Cloud Console -> **Credentials** -> **OAuth 2.0 Client IDs**, register both the debug and release certificate fingerprints:
     ```bash
     keytool -list -v -keystore android/upload-keystore.jks
     ```
   - Add both the SHA-1 and SHA-256 fingerprints to your Android client credentials.
