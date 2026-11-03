// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'vaultOFF';

  @override
  String get onboardingTitle1 => 'एक बार सिंक करें';

  @override
  String get onboardingBody1 =>
      'अपनी फ़ोटो और दस्तावेज़ अपलोड करें। वे आपके ग्रुप के हर डिवाइस पर सिंक हो जाते हैं।';

  @override
  String get onboardingTitle2 => 'कहीं भी देखें, ऑफ़लाइन';

  @override
  String get onboardingBody2 =>
      'एक बार सिंक होने के बाद, फ़ाइलें आपके फ़ोन में सहेजी जाती हैं। उन्हें देखने के लिए कभी भी इंटरनेट की ज़रूरत नहीं।';

  @override
  String get onboardingTitle3 => 'आपके ग्रुप के लिए निजी';

  @override
  String get onboardingBody3 =>
      'केवल आपके ग्रुप कोड वाले लोग ही आपकी फ़ाइलें देख सकते हैं। सब कुछ एन्क्रिप्टेड है।';

  @override
  String get onboardingNext => 'आगे';

  @override
  String get onboardingGetStarted => 'शुरू करें';

  @override
  String get signInTitle => 'vaultOFF में आपका स्वागत है';

  @override
  String get signInSubtitle => 'अपनी वॉल्ट तक पहुँचने के लिए साइन इन करें';

  @override
  String get continueWithGoogle => 'Google से जारी रखें';

  @override
  String get orSignInWithEmail => 'या ईमेल से साइन इन करें';

  @override
  String get emailHint => 'अपना ईमेल पता दर्ज करें';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String enterCode(String email) {
    return '$email पर भेजा गया 6-अंकों का कोड दर्ज करें';
  }

  @override
  String get verifyCode => 'सत्यापित करें';

  @override
  String get invalidEmail => 'कृपया एक मान्य ईमेल पता दर्ज करें';

  @override
  String get codeSent => 'कोड भेज दिया गया! अपना ईमेल देखें।';

  @override
  String get invalidCode =>
      'आपने जो कोड दर्ज किया है वह गलत है। कृपया पुनः प्रयास करें।';

  @override
  String get signInError => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get groupsHomeTitle => 'आपकी वॉल्ट';

  @override
  String get createGroup => 'ग्रुप बनाएँ';

  @override
  String get joinWithCode => 'कोड से जुड़ें';

  @override
  String get emptyGroupsTitle => 'अभी कोई वॉल्ट नहीं';

  @override
  String get emptyGroupsBody =>
      'अपनी पहली वॉल्ट बनाएँ या किसी भरोसेमंद व्यक्ति के कोड से जुड़ें।';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें',
      one: '1 फ़ाइल',
      zero: 'कोई फ़ाइल नहीं',
    );
    return '$_temp0';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सदस्य',
      one: '1 सदस्य',
    );
    return '$_temp0';
  }

  @override
  String sizeOnDevice(String size) {
    return 'इस फ़ोन पर $size';
  }

  @override
  String get syncStatusSynced => 'अप टू डेट';

  @override
  String get syncStatusSyncing => 'सिंक हो रहा है…';

  @override
  String get syncStatusOffline => 'ऑफ़लाइन';

  @override
  String get syncStatusWaiting => 'कनेक्शन की प्रतीक्षा में';

  @override
  String lastSynced(String time) {
    return 'अंतिम सिंक $time';
  }

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get syncCentre => 'सिंक सेंटर';

  @override
  String get pullToRefresh => 'रिफ़्रेश करने के लिए खींचें';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get ok => 'ठीक है';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get error => 'त्रुटि';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get noConnection => 'कनेक्शन नहीं है';

  @override
  String get offlineReady => 'ऑफ़लाइन उपलब्ध';

  @override
  String get downloading => 'डाउनलोड हो रहा है…';

  @override
  String get uploadPending => 'अपलोड बाकी है';

  @override
  String get syncFailed => 'सिंक विफल';

  @override
  String get networkErrorMessage =>
      'अपना इंटरनेट कनेक्शन जाँचें और पुनः प्रयास करें।';

  @override
  String get unknownError => 'कुछ अनपेक्षित हुआ। कृपया पुनः प्रयास करें।';

  @override
  String get settingsAppLockTitle => 'ऐप लॉक और पिन';

  @override
  String get settingsAppLockSubtitleSet => 'पिन सेट है';

  @override
  String get settingsAppLockSubtitleNotSet => 'कोई पिन सेट नहीं है';

  @override
  String get settingsSetPin => 'पिन सेट करें';

  @override
  String get settingsChangePin => 'पिन बदलें';

  @override
  String get settingsRemovePin => 'पिन हटाएं';

  @override
  String get pinDialogTitleSet => 'पिन सेट करें';

  @override
  String get pinDialogTitleChange => 'पिन बदलें';

  @override
  String get pinDialogTitleRemove => 'पिन हटाएं';

  @override
  String get pinRecommendation =>
      'हम 6-अंकों के पिन की सलाह देते हैं (4 से 8 अंक मान्य हैं)';

  @override
  String get enterPin => 'पिन दर्ज करें';

  @override
  String get enterCurrentPin => 'वर्तमान पिन दर्ज करें';

  @override
  String get enterNewPin => 'नया पिन दर्ज करें';

  @override
  String get confirmNewPin => 'नए पिन की पुष्टि करें';

  @override
  String get pinMismatch => 'पिन मेल नहीं खाते';

  @override
  String get pinLengthError => 'पिन 4 से 8 अंकों के बीच होना चाहिए';

  @override
  String get pinIncorrect => 'गलत पिन। कृपया पुनः प्रयास करें।';

  @override
  String pinLockoutMessage(int seconds) {
    return 'बहुत सारे असफल प्रयास। $seconds सेकंड में पुनः प्रयास करें';
  }

  @override
  String get biometricPrompt => 'vaultOFF अनलॉक करें';

  @override
  String get biometricsEnabled => 'बायोमेट्रिक अनलॉक';

  @override
  String get biometricsSubtitle =>
      'अनलॉक करने के लिए फ़िंगरप्रिंट या चेहरे का उपयोग करें';

  @override
  String get unlock => 'अनलॉक करें';

  @override
  String get savePin => 'पिन सहेजें';

  @override
  String get syncAndNetwork => 'सिंक और नेटवर्क';

  @override
  String get syncWifiOnly => 'केवल वाई-फ़ाई पर सिंक करें';

  @override
  String get syncWifiOnlySubtitle =>
      'स्वचालित बैकग्राउंड सिंक के लिए मोबाइल डेटा के उपयोग को रोकें';

  @override
  String get privacyAndSecurity => 'गोपनीयता और सुरक्षा';

  @override
  String get blockScreenshots => 'स्क्रीनशॉट ब्लॉक करें';

  @override
  String get blockScreenshotsSubtitle =>
      'स्क्रीन कैप्चर रोकें और ऐप स्विचर में सामग्री छिपाएं';

  @override
  String get storage => 'स्टोरेज';

  @override
  String get freeUpSpace => 'स्थान खाली करें';

  @override
  String get freeUpSpaceSubtitle =>
      'थंबनेल को ऑफ़लाइन रखते हुए मूल डाउनलोड हटाता है';

  @override
  String get spaceCleared => 'स्थान खाली हो गया। थंबनेल सुरक्षित हैं।';

  @override
  String get language => 'भाषा';

  @override
  String get account => 'खाता';

  @override
  String get batteryOptimization => 'बैटरी ऑप्टिमाइज़ेशन';

  @override
  String get batteryOptimizationSubtitle =>
      'ऐप बंद होने पर भी वॉल्ट को अपडेट रखने के लिए बैकग्राउंड सिंक की अनुमति दें';

  @override
  String get batteryOptimizationGuideTitle => 'बैटरी ऑप्टिमाइज़ेशन अक्षम करें';

  @override
  String get batteryOptimizationGuideContent =>
      'ऐप बंद होने पर Android vaultOFF को स्लीप में डाल सकता है, जिससे स्वचालित सिंक रुक जाता है। बैकग्राउंड में अपने वॉल्ट और फ़ाइलों को अपडेट रखने के लिए, vaultOFF बैटरी उपयोग को अप्रतिबंधित पर सेट करें।';

  @override
  String get openBatterySettings => 'बैटरी सेटिंग्स खोलें';
}
