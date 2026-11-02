// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appName => 'ઑફલાઇન વૉલ્ટ';

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
  String get signInTitle => 'ઑફલાઇન વૉલ્ટમાં સ્વાગત છે';

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
}
