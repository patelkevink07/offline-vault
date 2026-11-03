import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'vaultOFF'**
  String get appName;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Sync once'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Upload your photos and documents. They sync to every device in your group.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'View anywhere, offline'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Once synced, files are stored on your phone. No internet needed to view them — ever.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Private to your group'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Only people with your group code can see your files. Everything is encrypted.'**
  String get onboardingBody3;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to vaultOFF'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your vaults'**
  String get signInSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orSignInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'or sign in with email'**
  String get orSignInWithEmail;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}'**
  String enterCode(String email);

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCode;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent! Check your email.'**
  String get codeSent;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'The code you entered is incorrect. Please try again.'**
  String get invalidCode;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get signInError;

  /// No description provided for @groupsHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Vaults'**
  String get groupsHomeTitle;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// No description provided for @joinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with code'**
  String get joinWithCode;

  /// No description provided for @emptyGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'No vaults yet'**
  String get emptyGroupsTitle;

  /// No description provided for @emptyGroupsBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first vault or join one with a code from someone you trust.'**
  String get emptyGroupsBody;

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files} =1{1 file} other{{count} files}}'**
  String filesCount(int count);

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersCount(int count);

  /// No description provided for @sizeOnDevice.
  ///
  /// In en, this message translates to:
  /// **'{size} on this phone'**
  String sizeOnDevice(String size);

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get syncStatusWaiting;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String lastSynced(String time);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @syncCentre.
  ///
  /// In en, this message translates to:
  /// **'Sync Centre'**
  String get syncCentre;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get noConnection;

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get offlineReady;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloading;

  /// No description provided for @uploadPending.
  ///
  /// In en, this message translates to:
  /// **'Upload pending'**
  String get uploadPending;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @networkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get networkErrorMessage;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something unexpected happened. Please try again.'**
  String get unknownError;

  /// No description provided for @settingsAppLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App Lock & PIN'**
  String get settingsAppLockTitle;

  /// No description provided for @settingsAppLockSubtitleSet.
  ///
  /// In en, this message translates to:
  /// **'PIN configured'**
  String get settingsAppLockSubtitleSet;

  /// No description provided for @settingsAppLockSubtitleNotSet.
  ///
  /// In en, this message translates to:
  /// **'No PIN configured'**
  String get settingsAppLockSubtitleNotSet;

  /// No description provided for @settingsSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get settingsSetPin;

  /// No description provided for @settingsChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settingsChangePin;

  /// No description provided for @settingsRemovePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get settingsRemovePin;

  /// No description provided for @pinDialogTitleSet.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get pinDialogTitleSet;

  /// No description provided for @pinDialogTitleChange.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get pinDialogTitleChange;

  /// No description provided for @pinDialogTitleRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get pinDialogTitleRemove;

  /// No description provided for @pinRecommendation.
  ///
  /// In en, this message translates to:
  /// **'We recommend a 6-digit PIN (4 to 8 digits allowed)'**
  String get pinRecommendation;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @enterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN'**
  String get enterCurrentPin;

  /// No description provided for @enterNewPin.
  ///
  /// In en, this message translates to:
  /// **'Enter new PIN'**
  String get enterNewPin;

  /// No description provided for @confirmNewPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get confirmNewPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinMismatch;

  /// No description provided for @pinLengthError.
  ///
  /// In en, this message translates to:
  /// **'PIN must be between 4 and 8 digits'**
  String get pinLengthError;

  /// No description provided for @pinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again.'**
  String get pinIncorrect;

  /// No description provided for @pinLockoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Try again in {seconds}s'**
  String pinLockoutMessage(int seconds);

  /// No description provided for @biometricPrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock vaultOFF'**
  String get biometricPrompt;

  /// No description provided for @biometricsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get biometricsEnabled;

  /// No description provided for @biometricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face to unlock'**
  String get biometricsSubtitle;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @savePin.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get savePin;

  /// No description provided for @syncAndNetwork.
  ///
  /// In en, this message translates to:
  /// **'Sync & Network'**
  String get syncAndNetwork;

  /// No description provided for @syncWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Sync on Wi-Fi only'**
  String get syncWifiOnly;

  /// No description provided for @syncWifiOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent using mobile data for automatic background sync'**
  String get syncWifiOnlySubtitle;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacyAndSecurity;

  /// No description provided for @blockScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots'**
  String get blockScreenshots;

  /// No description provided for @blockScreenshotsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent screen captures and hide content in app switcher'**
  String get blockScreenshotsSubtitle;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @freeUpSpace.
  ///
  /// In en, this message translates to:
  /// **'Free up space'**
  String get freeUpSpace;

  /// No description provided for @freeUpSpaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes original downloads while keeping thumbnails offline'**
  String get freeUpSpaceSubtitle;

  /// No description provided for @spaceCleared.
  ///
  /// In en, this message translates to:
  /// **'Space cleared. Thumbnails retained.'**
  String get spaceCleared;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @batteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimization;

  /// No description provided for @batteryOptimizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow background sync to keep your vault updated even when closed'**
  String get batteryOptimizationSubtitle;

  /// No description provided for @batteryOptimizationGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable Battery Optimization'**
  String get batteryOptimizationGuideTitle;

  /// No description provided for @batteryOptimizationGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Android may put vaultOFF to sleep when the app is closed, pausing automatic sync. To keep your vaults and files up to date in the background, set vaultOFF battery usage to Unrestricted.'**
  String get batteryOptimizationGuideContent;

  /// No description provided for @openBatterySettings.
  ///
  /// In en, this message translates to:
  /// **'Open Battery Settings'**
  String get openBatterySettings;

  /// No description provided for @joinVault.
  ///
  /// In en, this message translates to:
  /// **'Join Vault'**
  String get joinVault;

  /// No description provided for @enter4DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code'**
  String get enter4DigitCode;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCode;

  /// No description provided for @scanQrCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the code directly from another screen or device'**
  String get scanQrCodeSubtitle;

  /// No description provided for @stopScanner.
  ///
  /// In en, this message translates to:
  /// **'Stop Scanner'**
  String get stopScanner;

  /// No description provided for @invalidOrExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired invite code.'**
  String get invalidOrExpiredCode;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again in an hour.'**
  String get tooManyAttempts;

  /// No description provided for @trafficPaused.
  ///
  /// In en, this message translates to:
  /// **'Joining groups is temporarily paused. Please try again later.'**
  String get trafficPaused;

  /// No description provided for @removedFromGroup.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from this group.'**
  String get removedFromGroup;

  /// No description provided for @requestPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Your join request is pending approval from the owner.'**
  String get requestPendingApproval;

  /// No description provided for @shareAndMembers.
  ///
  /// In en, this message translates to:
  /// **'Share and members'**
  String get shareAndMembers;

  /// No description provided for @vaultCode.
  ///
  /// In en, this message translates to:
  /// **'Vault Code'**
  String get vaultCode;

  /// No description provided for @expiresInHours.
  ///
  /// In en, this message translates to:
  /// **'Expires in {hours} h'**
  String expiresInHours(int hours);

  /// No description provided for @changeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Change Expiry'**
  String get changeExpiry;

  /// No description provided for @expiry1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get expiry1Hour;

  /// No description provided for @expiry24Hours.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get expiry24Hours;

  /// No description provided for @expiry7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get expiry7Days;

  /// No description provided for @approveMembersMyself.
  ///
  /// In en, this message translates to:
  /// **'Approve new members myself'**
  String get approveMembersMyself;

  /// No description provided for @rotateCode.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotateCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyCode;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get codeCopied;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @joinedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Joined just now'**
  String get joinedJustNow;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get roleEditor;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave vault'**
  String get leaveGroup;

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this vault? All downloaded files and thumbnails will be removed from your phone immediately.'**
  String get leaveGroupConfirm;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this vault?'**
  String removeMemberConfirm(String name);

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @pendingMembers.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingMembers;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
