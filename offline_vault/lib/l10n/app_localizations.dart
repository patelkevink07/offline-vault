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
