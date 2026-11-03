// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'vaultOFF';

  @override
  String get onboardingTitle1 => 'Sync once';

  @override
  String get onboardingBody1 =>
      'Upload your photos and documents. They sync to every device in your group.';

  @override
  String get onboardingTitle2 => 'View anywhere, offline';

  @override
  String get onboardingBody2 =>
      'Once synced, files are stored on your phone. No internet needed to view them — ever.';

  @override
  String get onboardingTitle3 => 'Private to your group';

  @override
  String get onboardingBody3 =>
      'Only people with your group code can see your files. Everything is encrypted.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get signInTitle => 'Welcome to vaultOFF';

  @override
  String get signInSubtitle => 'Sign in to access your vaults';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orSignInWithEmail => 'or sign in with email';

  @override
  String get emailHint => 'Enter your email address';

  @override
  String get sendCode => 'Send code';

  @override
  String enterCode(String email) {
    return 'Enter the 6-digit code sent to $email';
  }

  @override
  String get verifyCode => 'Verify';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get codeSent => 'Code sent! Check your email.';

  @override
  String get invalidCode =>
      'The code you entered is incorrect. Please try again.';

  @override
  String get signInError => 'Something went wrong. Please try again.';

  @override
  String get groupsHomeTitle => 'Your Vaults';

  @override
  String get createGroup => 'Create group';

  @override
  String get joinWithCode => 'Join with code';

  @override
  String get emptyGroupsTitle => 'No vaults yet';

  @override
  String get emptyGroupsBody =>
      'Create your first vault or join one with a code from someone you trust.';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
      zero: 'No files',
    );
    return '$_temp0';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String sizeOnDevice(String size) {
    return '$size on this phone';
  }

  @override
  String get syncStatusSynced => 'Up to date';

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncStatusWaiting => 'Waiting for connection';

  @override
  String lastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get settings => 'Settings';

  @override
  String get syncCentre => 'Sync Centre';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get signOut => 'Sign out';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading…';

  @override
  String get noConnection => 'No connection';

  @override
  String get offlineReady => 'Available offline';

  @override
  String get downloading => 'Downloading…';

  @override
  String get uploadPending => 'Upload pending';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get networkErrorMessage =>
      'Check your internet connection and try again.';

  @override
  String get unknownError => 'Something unexpected happened. Please try again.';

  @override
  String get settingsAppLockTitle => 'App Lock & PIN';

  @override
  String get settingsAppLockSubtitleSet => 'PIN configured';

  @override
  String get settingsAppLockSubtitleNotSet => 'No PIN configured';

  @override
  String get settingsSetPin => 'Set PIN';

  @override
  String get settingsChangePin => 'Change PIN';

  @override
  String get settingsRemovePin => 'Remove PIN';

  @override
  String get pinDialogTitleSet => 'Set PIN';

  @override
  String get pinDialogTitleChange => 'Change PIN';

  @override
  String get pinDialogTitleRemove => 'Remove PIN';

  @override
  String get pinRecommendation =>
      'We recommend a 6-digit PIN (4 to 8 digits allowed)';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get enterCurrentPin => 'Enter current PIN';

  @override
  String get enterNewPin => 'Enter new PIN';

  @override
  String get confirmNewPin => 'Confirm new PIN';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get pinLengthError => 'PIN must be between 4 and 8 digits';

  @override
  String get pinIncorrect => 'Incorrect PIN. Please try again.';

  @override
  String pinLockoutMessage(int seconds) {
    return 'Too many failed attempts. Try again in ${seconds}s';
  }

  @override
  String get biometricPrompt => 'Unlock vaultOFF';

  @override
  String get biometricsEnabled => 'Biometric unlock';

  @override
  String get biometricsSubtitle => 'Use fingerprint or face to unlock';

  @override
  String get unlock => 'Unlock';

  @override
  String get savePin => 'Save PIN';

  @override
  String get syncAndNetwork => 'Sync & Network';

  @override
  String get syncWifiOnly => 'Sync on Wi-Fi only';

  @override
  String get syncWifiOnlySubtitle =>
      'Prevent using mobile data for automatic background sync';

  @override
  String get privacyAndSecurity => 'Privacy & Security';

  @override
  String get blockScreenshots => 'Block screenshots';

  @override
  String get blockScreenshotsSubtitle =>
      'Prevent screen captures and hide content in app switcher';

  @override
  String get storage => 'Storage';

  @override
  String get freeUpSpace => 'Free up space';

  @override
  String get freeUpSpaceSubtitle =>
      'Removes original downloads while keeping thumbnails offline';

  @override
  String get spaceCleared => 'Space cleared. Thumbnails retained.';

  @override
  String get language => 'Language';

  @override
  String get account => 'Account';

  @override
  String get batteryOptimization => 'Battery Optimization';

  @override
  String get batteryOptimizationSubtitle =>
      'Allow background sync to keep your vault updated even when closed';

  @override
  String get batteryOptimizationGuideTitle => 'Disable Battery Optimization';

  @override
  String get batteryOptimizationGuideContent =>
      'Android may put vaultOFF to sleep when the app is closed, pausing automatic sync. To keep your vaults and files up to date in the background, set vaultOFF battery usage to Unrestricted.';

  @override
  String get openBatterySettings => 'Open Battery Settings';

  @override
  String get joinVault => 'Join Vault';

  @override
  String get enter4DigitCode => 'Enter the 4-digit code';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String get scanQrCodeSubtitle =>
      'Scan the code directly from another screen or device';

  @override
  String get stopScanner => 'Stop Scanner';

  @override
  String get invalidOrExpiredCode => 'Invalid or expired invite code.';

  @override
  String get tooManyAttempts =>
      'Too many failed attempts. Please try again in an hour.';

  @override
  String get trafficPaused =>
      'Joining groups is temporarily paused. Please try again later.';

  @override
  String get removedFromGroup => 'You have been removed from this group.';

  @override
  String get requestPendingApproval =>
      'Your join request is pending approval from the owner.';

  @override
  String get shareAndMembers => 'Share and members';

  @override
  String get vaultCode => 'Vault Code';

  @override
  String expiresInHours(int hours) {
    return 'Expires in $hours h';
  }

  @override
  String get changeExpiry => 'Change Expiry';

  @override
  String get expiry1Hour => '1 hour';

  @override
  String get expiry24Hours => '24 hours';

  @override
  String get expiry7Days => '7 days';

  @override
  String get approveMembersMyself => 'Approve new members myself';

  @override
  String get rotateCode => 'Rotate';

  @override
  String get copyCode => 'Copy';

  @override
  String get shareCode => 'Share';

  @override
  String get codeCopied => 'Code copied to clipboard';

  @override
  String get members => 'Members';

  @override
  String get joinedJustNow => 'Joined just now';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleEditor => 'Editor';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get removeMember => 'Remove';

  @override
  String get leaveGroup => 'Leave vault';

  @override
  String get leaveGroupConfirm =>
      'Are you sure you want to leave this vault? All downloaded files and thumbnails will be removed from your phone immediately.';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name from this vault?';
  }

  @override
  String get approve => 'Approve';

  @override
  String get decline => 'Decline';

  @override
  String get pendingMembers => 'Pending Approval';
}
