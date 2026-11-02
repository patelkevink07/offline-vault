// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Offline Vault';

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
  String get signInTitle => 'Welcome to Offline Vault';

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
}
