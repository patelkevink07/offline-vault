// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appName => 'vaultOFF';

  @override
  String get onboardingTitle1 => 'એક વાર સિંક કરો';

  @override
  String get onboardingBody1 =>
      'તમારા ફોટા અને દસ્તાવેજો અપલોડ કરો. તે તમારા ગ્રુપના દરેક ઉપકરણ પર સિંક થાય છે.';

  @override
  String get onboardingTitle2 => 'ગમે ત્યાં જુઓ, ઑફલાઇન';

  @override
  String get onboardingBody2 =>
      'એક વાર સિંક થયા પછી, ફાઇલો તમારા ફોનમાં સંગ્રહિત થાય છે. જોવા માટે ક્યારેય ઇન્ટરનેટની જરૂર નથી.';

  @override
  String get onboardingTitle3 => 'તમારા ગ્રુપ માટે ખાનગી';

  @override
  String get onboardingBody3 =>
      'માત્ર તમારો ગ્રુપ કોડ ધરાવતા લોકો જ તમારી ફાઇલો જોઈ શકે છે. બધું એન્ક્રિપ્ટેડ છે.';

  @override
  String get onboardingNext => 'આગળ';

  @override
  String get onboardingGetStarted => 'શરૂ કરો';

  @override
  String get signInTitle => 'vaultOFF માં સ્વાગત છે';

  @override
  String get signInSubtitle => 'તમારી વૉલ્ટ ઍક્સેસ કરવા સાઇન ઇન કરો';

  @override
  String get continueWithGoogle => 'Google સાથે ચાલુ રાખો';

  @override
  String get orSignInWithEmail => 'અથવા ઇમેઇલથી સાઇન ઇન કરો';

  @override
  String get emailHint => 'તમારું ઇમેઇલ સરનામું દાખલ કરો';

  @override
  String get sendCode => 'કોડ મોકલો';

  @override
  String enterCode(String email) {
    return '$email પર મોકલેલો 6-અંકનો કોડ દાખલ કરો';
  }

  @override
  String get verifyCode => 'ચકાસો';

  @override
  String get invalidEmail => 'કૃપા કરીને માન્ય ઇમેઇલ સરનામું દાખલ કરો';

  @override
  String get codeSent => 'કોડ મોકલ્યો! તમારું ઇમેઇલ તપાસો.';

  @override
  String get invalidCode =>
      'તમે દાખલ કરેલો કોડ ખોટો છે. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get signInError => 'કંઈક ખોટું થયું. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get groupsHomeTitle => 'તમારી વૉલ્ટ';

  @override
  String get createGroup => 'ગ્રુપ બનાવો';

  @override
  String get joinWithCode => 'કોડ વડે જોડાઓ';

  @override
  String get emptyGroupsTitle => 'હજી કોઈ વૉલ્ટ નથી';

  @override
  String get emptyGroupsBody =>
      'તમારી પહેલી વૉલ્ટ બનાવો અથવા તમે જેના પર વિશ્વાસ કરો છો તેના કોડ વડે જોડાઓ.';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ફાઇલો',
      one: '1 ફાઇલ',
      zero: 'કોઈ ફાઇલ નથી',
    );
    return '$_temp0';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count સભ્યો',
      one: '1 સભ્ય',
    );
    return '$_temp0';
  }

  @override
  String sizeOnDevice(String size) {
    return 'આ ફોન પર $size';
  }

  @override
  String get syncStatusSynced => 'અપ ટુ ડેટ';

  @override
  String get syncStatusSyncing => 'સિંક થઈ રહ્યું છે…';

  @override
  String get syncStatusOffline => 'ઑફલાઇન';

  @override
  String get syncStatusWaiting => 'કનેક્શનની રાહ જોઈ રહ્યા છીએ';

  @override
  String lastSynced(String time) {
    return 'છેલ્લું સિંક $time';
  }

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get syncCentre => 'સિંક સેન્ટર';

  @override
  String get pullToRefresh => 'રિફ્રેશ કરવા ખેંચો';

  @override
  String get signOut => 'સાઇન આઉટ';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get ok => 'ઠીક';

  @override
  String get retry => 'ફરી પ્રયાસ કરો';

  @override
  String get error => 'ભૂલ';

  @override
  String get loading => 'લોડ થઈ રહ્યું છે…';

  @override
  String get noConnection => 'કનેક્શન નથી';

  @override
  String get offlineReady => 'ઑફલાઇન ઉપલબ્ધ';

  @override
  String get downloading => 'ડાઉનલોડ થઈ રહ્યું છે…';

  @override
  String get uploadPending => 'અપલોડ બાકી છે';

  @override
  String get syncFailed => 'સિંક નિષ્ફળ થયું';

  @override
  String get networkErrorMessage =>
      'તમારું ઇન્ટરનેટ કનેક્શન તપાસો અને ફરી પ્રયાસ કરો.';

  @override
  String get unknownError => 'કંઈક અણધાર્યું થયું. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get settingsAppLockTitle => 'ઍપ લૉક અને પિન';

  @override
  String get settingsAppLockSubtitleSet => 'પિન સેટ કરેલ છે';

  @override
  String get settingsAppLockSubtitleNotSet => 'પિન રૂપરેખાંકિત નથી';

  @override
  String get settingsSetPin => 'પિન સેટ કરો';

  @override
  String get settingsChangePin => 'પિન બદલો';

  @override
  String get settingsRemovePin => 'પિન દૂર કરો';

  @override
  String get pinDialogTitleSet => 'પિન સેટ કરો';

  @override
  String get pinDialogTitleChange => 'પિન બદલો';

  @override
  String get pinDialogTitleRemove => 'પિન દૂર કરો';

  @override
  String get pinRecommendation =>
      'અમે 6-અંકના પિનની ભલામણ કરીએ છીએ (4 થી 8 અંકો માન્ય છે)';

  @override
  String get enterPin => 'પિન દાખલ કરો';

  @override
  String get enterCurrentPin => 'વર્તમાન પિન દાખલ કરો';

  @override
  String get enterNewPin => 'નવો પિન દાખલ કરો';

  @override
  String get confirmNewPin => 'નવા પિનની પુષ્ટિ કરો';

  @override
  String get pinMismatch => 'પિન મેળ ખાતા નથી';

  @override
  String get pinLengthError => 'પિન 4 થી 8 અંક વચ્ચે હોવો જોઈએ';

  @override
  String get pinIncorrect => 'ખોટો પિન. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String pinLockoutMessage(int seconds) {
    return 'ઘણા બધા ખોટા પ્રયાસો. $seconds સેકન્ડમાં ફરી પ્રયાસ કરો';
  }

  @override
  String get biometricPrompt => 'vaultOFF અનલૉક કરો';

  @override
  String get biometricsEnabled => 'બાયોમેટ્રિક અનલૉક';

  @override
  String get biometricsSubtitle =>
      'અનલૉક કરવા માટે ફિંગરપ્રિન્ટ અથવા ફેસનો ઉપયોગ કરો';

  @override
  String get unlock => 'અનલૉક કરો';

  @override
  String get savePin => 'પિન સાચવો';

  @override
  String get syncAndNetwork => 'સિંક અને નેટવર્ક';

  @override
  String get syncWifiOnly => 'માત્ર Wi-Fi પર સિંક કરો';

  @override
  String get syncWifiOnlySubtitle =>
      'સ્વચાલિત પૃષ્ઠભૂમિ સિંક માટે મોબાઇલ ડેટાનો ઉપયોગ અટકાવો';

  @override
  String get privacyAndSecurity => 'ગોપનીયતા અને સુરક્ષા';

  @override
  String get blockScreenshots => 'સ્ક્રીનશોટ બ્લૉક કરો';

  @override
  String get blockScreenshotsSubtitle =>
      'સ્ક્રીન કેપ્ચર અટકાવો અને ઍપ સ્વિચરમાં સામગ્રી છુપાવો';

  @override
  String get storage => 'સ્ટોરેજ';

  @override
  String get freeUpSpace => 'જગ્યા ખાલી કરો';

  @override
  String get freeUpSpaceSubtitle =>
      'થંબનેલ્સ ઑફલાઇન રાખીને મૂળ ડાઉનલોડ્સ દૂર કરે છે';

  @override
  String get spaceCleared => 'જગ્યા ખાલી થઈ ગઈ. થંબનેલ્સ સચવાયેલા છે.';

  @override
  String get language => 'ભાષા';

  @override
  String get account => 'ખાતું';

  @override
  String get batteryOptimization => 'બૅટરી ઑપ્ટિમાઇઝેશન';

  @override
  String get batteryOptimizationSubtitle =>
      'ઍપ બંધ હોય ત્યારે પણ વૉલ્ટ અપડેટ રાખવા માટે પૃષ્ઠભૂમિ સિંકની મંજૂરી આપો';

  @override
  String get batteryOptimizationGuideTitle => 'બૅટરી ઑપ્ટિમાઇઝેશન અક્ષમ કરો';

  @override
  String get batteryOptimizationGuideContent =>
      'જ્યારે ઍપ બંધ હોય ત્યારે Android vaultOFF ને સ્લીપ મોડમાં મૂકી શકે છે, જેનાથી સ્વચાલિત સિંક અટકી જાય છે. પૃષ્ઠભૂમિમાં તમારા વૉલ્ટ અને ફાઇલો અપડેટ રાખવા માટે, vaultOFF બૅટરી વપરાશને અનરિસ્ટ્રિક્ટેડ પર સેટ કરો.';

  @override
  String get openBatterySettings => 'બૅટરી સેટિંગ્સ ખોલો';

  @override
  String get joinVault => 'વૉલ્ટમાં જોડાઓ';

  @override
  String get enter4DigitCode => '૪ અંકનો કોડ દાખલ કરો';

  @override
  String get scanQrCode => 'QR કોડ સ્કેન કરો';

  @override
  String get scanQrCodeSubtitle =>
      'અન્ય સ્ક્રીન અથવા ડિવાઇસ પરથી સીધો કોડ સ્કેન કરો';

  @override
  String get stopScanner => 'સ્કેનર બંધ કરો';

  @override
  String get invalidOrExpiredCode => 'અમાન્ય અથવા સમાપ્ત થયેલ આમંત્રણ કોડ.';

  @override
  String get tooManyAttempts =>
      'ઘણા બધા નિષ્ફળ પ્રયાસો. કૃપા કરીને એક કલાક પછી ફરી પ્રયાસ કરો.';

  @override
  String get trafficPaused =>
      'વૉલ્ટમાં જોડાવાનું હાલમાં સ્થગિત છે. કૃપા કરીને થોડા સમય પછી ફરી પ્રયાસ કરો.';

  @override
  String get removedFromGroup => 'તમને આ વૉલ્ટમાંથી દૂર કરવામાં આવ્યા છે.';

  @override
  String get requestPendingApproval =>
      'તમારી જોડાવાની વિનંતી માલિકની મંજૂરી માટે બાકી છે.';

  @override
  String get shareAndMembers => 'શેર અને સભ્યો';

  @override
  String get vaultCode => 'વૉલ્ટ કોડ';

  @override
  String expiresInHours(int hours) {
    return '$hours કલાકમાં સમાપ્ત થાય છે';
  }

  @override
  String get changeExpiry => 'સમાપ્તિ સમય બદલો';

  @override
  String get expiry1Hour => '૧ કલાક';

  @override
  String get expiry24Hours => '૨૪ કલાક';

  @override
  String get expiry7Days => '૭ દિવસ';

  @override
  String get approveMembersMyself => 'નવા સભ્યોને મારી જાતે મંજૂર કરો';

  @override
  String get rotateCode => 'નવો કોડ બનાવો';

  @override
  String get copyCode => 'કૉપિ કરો';

  @override
  String get shareCode => 'શેર કરો';

  @override
  String get codeCopied => 'કોડ ક્લિપબોર્ડ પર કૉપિ થયો';

  @override
  String get members => 'સભ્યો';

  @override
  String get joinedJustNow => 'હમણાં જ જોડાયા';

  @override
  String get roleOwner => 'માલિક';

  @override
  String get roleEditor => 'સંપાદક';

  @override
  String get roleViewer => 'દર્શક';

  @override
  String get removeMember => 'દૂર કરો';

  @override
  String get leaveGroup => 'વૉલ્ટ છોડો';

  @override
  String get leaveGroupConfirm =>
      'શું તમે ખરેખર આ વૉલ્ટ છોડવા માંગો છો? બધી ડાઉનલોડ કરેલી ફાઇલો અને થંબનેલ્સ તરત જ તમારા ફોનમાંથી દૂર કરવામાં આવશે.';

  @override
  String removeMemberConfirm(String name) {
    return 'આ વૉલ્ટમાંથી $name ને દૂર કરીએ?';
  }

  @override
  String get approve => 'મંજૂર કરો';

  @override
  String get decline => 'અસ્વીકાર કરો';

  @override
  String get pendingMembers => 'મંજૂરી બાકી';
}
