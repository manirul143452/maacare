// ============================================================
//  AppLocalizations – MaaCare
//  Supports: English (en), Hindi (hi), Assamese (as), Bengali (bn)
// ============================================================

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('as'),
    Locale('bn'),
  ];

  // ── Language Names (displayed in their own language) ──
  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'as': 'অসমীয়া',
    'bn': 'বাংলা',
  };

  String _t(Map<String, String> translations) {
    return translations[locale.languageCode] ?? translations['en'] ?? '';
  }

  // ══════════════════════════════════════════════════
  // APP GENERAL
  // ══════════════════════════════════════════════════

  String get appName => _t({
        'en': 'MaaCare',
        'hi': 'माँकेयर',
        'as': 'মাকেয়াৰ',
        'bn': 'মাকেয়ার',
      });

  String get tagline => _t({
        'en': 'Every Mama Deserves the Best Care',
        'hi': 'हर माँ को मिले सबसे अच्छी देखभाल',
        'as': 'প্ৰতিটো মাকৰ বাবে সৰ্বোত্তম যত্ন',
        'bn': 'প্রতিটি মায়ের জন্য সেরা যত্ন',
      });

  // ══════════════════════════════════════════════════
  // NAVIGATION / BOTTOM BAR
  // ══════════════════════════════════════════════════

  String get navHome => _t({'en': 'Home', 'hi': 'होम', 'as': 'হোম', 'bn': 'হোম'});
  String get navTracker => _t({'en': 'Tracker', 'hi': 'ट्रैकर', 'as': 'ট্ৰেকাৰ', 'bn': 'ট্র্যাকার'});
  String get navCommunity => _t({'en': 'Community', 'hi': 'समुदाय', 'as': 'সমাজ', 'bn': 'সম্প্রদায়'});
  String get navConsult => _t({'en': 'Consult', 'hi': 'परामर्श', 'as': 'পৰামৰ্শ', 'bn': 'পরামর্শ'});
  String get navProfile => _t({'en': 'Profile', 'hi': 'प्रोफाइल', 'as': 'প্ৰ\'ফাইল', 'bn': 'প্রোফাইল'});

  // ══════════════════════════════════════════════════
  // SETTINGS
  // ══════════════════════════════════════════════════

  String get settings => _t({'en': 'Settings', 'hi': 'सेटिंग्स', 'as': 'ছেটিংছ', 'bn': 'সেটিংস'});
  String get personalization => _t({'en': 'Personalization', 'hi': 'व्यक्तिगतकरण', 'as': 'ব্যক্তিগতকৰণ', 'bn': 'ব্যক্তিগতকরণ'});
  String get language => _t({'en': 'Language', 'hi': 'भाषा', 'as': 'ভাষা', 'bn': 'ভাষা'});
  String get selectLanguage => _t({'en': 'Select Language', 'hi': 'भाषा चुनें', 'as': 'ভাষা বাছনি কৰক', 'bn': 'ভাষা নির্বাচন করুন'});
  String get darkMode => _t({'en': 'Dark Mode', 'hi': 'डार्क मोड', 'as': 'ডাৰ্ক মোড', 'bn': 'ডার্ক মোড'});
  String get darkModeSubtitle => _t({
        'en': 'Soft dark themes for tired eyes 🌙',
        'hi': 'थकी आँखों के लिए सॉफ्ट डार्क थीम 🌙',
        'as': 'ক্লান্ত চকুৰ বাবে ছফ্ট ডাৰ্ক থিম 🌙',
        'bn': 'ক্লান্ত চোখের জন্য সফট ডার্ক থিম 🌙',
      });
  String get pinkTheme => _t({'en': 'Pink Theme', 'hi': 'गुलाबी थीम', 'as': 'গোলাপী থিম', 'bn': 'গোলাপি থিম'});
  String get pinkThemeSubtitle => _t({
        'en': 'Vibrant pink tones for mama energy 🌸',
        'hi': 'माँ की ऊर्जा के लिए गुलाबी रंग 🌸',
        'as': 'মাকৰ শক্তিৰ বাবে গোলাপী ৰং 🌸',
        'bn': 'মায়ের শক্তির জন্য গোলাপি রঙ 🌸',
      });
  String get notifications => _t({'en': 'Notifications', 'hi': 'सूचनाएं', 'as': 'জাননী', 'bn': 'বিজ্ঞপ্তি'});
  String get dailyReminders => _t({'en': 'Daily Reminders', 'hi': 'दैनिक अनुस्मारक', 'as': 'দৈনিক সোঁৱৰণী', 'bn': 'দৈনিক অনুস্মারক'});
  String get dailyRemindersSubtitle => _t({
        'en': 'Mood checks and baby updates 👶',
        'hi': 'मूड चेक और बेबी अपडेट 👶',
        'as': 'মুড চেক আৰু শিশু আপডেট 👶',
        'bn': 'মুড চেক এবং শিশু আপডেট 👶',
      });
  String get privacyLegal => _t({'en': 'Privacy & Legal', 'hi': 'गोपनीयता और कानूनी', 'as': 'গোপনীয়তা আৰু আইনী', 'bn': 'গোপনীয়তা ও আইনি'});
  String get privacyPolicy => _t({'en': 'Privacy Policy', 'hi': 'गोपनीयता नीति', 'as': 'গোপনীয়তা নীতি', 'bn': 'গোপনীয়তা নীতি'});
  String get termsConditions => _t({'en': 'Terms & Conditions', 'hi': 'नियम और शर्तें', 'as': 'চৰ্তাৱলী', 'bn': 'নিয়ম ও শর্তাবলী'});
  String get exportData => _t({'en': 'Export My Data', 'hi': 'मेरा डेटा निर्यात करें', 'as': 'মোৰ ডেটা ৰপ্তানি', 'bn': 'আমার ডেটা রপ্তানি'});
  String get exportDataSubtitle => _t({
        'en': 'Download all your logs in JSON format',
        'hi': 'JSON फॉर्मेट में सभी लॉग डाउनलोड करें',
        'as': 'JSON ফৰ্মেটত সকলো লগ ডাউনলোড কৰক',
        'bn': 'JSON ফরম্যাটে সকল লগ ডাউনলোড করুন',
      });
  String get requestDeletion => _t({'en': 'Request Data Deletion', 'hi': 'डेटा हटाने का अनुरोध', 'as': 'ডেটা মচাৰ অনুৰোধ', 'bn': 'ডেটা মুছে ফেলার অনুরোধ'});
  String get signOut => _t({'en': 'Sign Out 🚪', 'hi': 'साइन आउट 🚪', 'as': 'চাইন আউট 🚪', 'bn': 'সাইন আউট 🚪'});

  // Sign out dialog
  String get signOutTitle => _t({'en': 'Sign Out?', 'hi': 'साइन आउट करें?', 'as': 'চাইন আউট?', 'bn': 'সাইন আউট?'});
  String get signOutMsg => _t({
        'en': "Are you sure you want to sign out, Mama? We'll be here waiting for you!",
        'hi': "क्या आप साइन आउट करना चाहती हैं, माँ? हम आपका इंतजार करेंगे!",
        'as': "আপুনি চাইন আউট কৰিব বিচাৰেনে, মা? আমি আপোনাৰ বাবে অপেক্ষা কৰিম!",
        'bn': "আপনি কি সাইন আউট করতে চান, মা? আমরা আপনার জন্য অপেক্ষা করব!",
      });
  String get stay => _t({'en': 'Stay', 'hi': 'रुकें', 'as': 'থাকক', 'bn': 'থাকুন'});
  String get cancel => _t({'en': 'Cancel', 'hi': 'रद्द करें', 'as': 'বাতিল', 'bn': 'বাতিল'});
  String get confirm => _t({'en': 'Confirm', 'hi': 'पुष्टि करें', 'as': 'নিশ্চিত', 'bn': 'নিশ্চিত'});
  String get delete => _t({'en': 'Delete', 'hi': 'हटाएं', 'as': 'মচক', 'bn': 'মুছুন'});

  // Delete data dialog
  String get deleteDataTitle => _t({'en': 'Delete Data? ⚠️', 'hi': 'डेटा हटाएं? ⚠️', 'as': 'ডেটা মচিব? ⚠️', 'bn': 'ডেটা মুছবেন? ⚠️'});
  String get deleteDataMsg => _t({
        'en': 'This will permanently erase all your logs and profile. Are you sure?',
        'hi': 'यह आपके सभी लॉग और प्रोफाइल को स्थायी रूप से मिटा देगा। क्या आप सुनिश्चित हैं?',
        'as': 'এইটোৱে আপোনাৰ সকলো লগ আৰু প্ৰ\'ফাইল স্থায়ীভাৱে মচি পেলাব। আপুনি নিশ্চিতনে?',
        'bn': 'এটি আপনার সমস্ত লগ এবং প্রোফাইল স্থায়ীভাবে মুছে দেবে। আপনি কি নিশ্চিত?',
      });

  // Snackbars
  String get preparingData => _t({'en': 'Preparing your data bundle... 📦', 'hi': 'आपका डेटा तैयार हो रहा है... 📦', 'as': 'আপোনাৰ ডেটা প্ৰস্তুত কৰা হৈছে... 📦', 'bn': 'আপনার ডেটা প্রস্তুত হচ্ছে... 📦'});
  String get deletionRequested => _t({'en': 'Data deletion request sent! ✋', 'hi': 'डेटा हटाने का अनुरोध भेजा गया! ✋', 'as': 'ডেটা মচাৰ অনুৰোধ পঠোৱা হ\'ল! ✋', 'bn': 'ডেটা মুছে ফেলার অনুরোধ পাঠানো হয়েছে! ✋'});

  // ══════════════════════════════════════════════════
  // PRIVACY POLICY
  // ══════════════════════════════════════════════════

  String get privacyHero => _t({
        'en': 'Your Privacy, Our Promise 🤱',
        'hi': 'आपकी गोपनीयता, हमारा वादा 🤱',
        'as': 'আপোনাৰ গোপনীয়তা, আমাৰ প্ৰতিশ্ৰুতি 🤱',
        'bn': 'আপনার গোপনীয়তা, আমাদের প্রতিশ্রুতি 🤱',
      });

  String get privacyIntro => _t({
        'en': 'At MaaCare, your trust means everything. This policy explains how we collect, use, and protect your personal data. Last updated: April 2025.',
        'hi': 'MaaCare में, आपका विश्वास हमारे लिए सबकुछ है। यह नीति बताती है कि हम आपका व्यक्तिगत डेटा कैसे एकत्र, उपयोग और सुरक्षित करते हैं। अंतिम अपडेट: अप्रैल 2025।',
        'as': 'MaaCare-ত, আপোনাৰ বিশ্বাসেই সকলো। এই নীতিয়ে ব্যাখ্যা কৰে যে আমি আপোনাৰ ব্যক্তিগত তথ্য কেনেকৈ সংগ্ৰহ, ব্যৱহাৰ আৰু সুৰক্ষিত কৰো। শেষ আপডেট: এপ্ৰিল ২০২৫।',
        'bn': 'MaaCare-এ, আপনার বিশ্বাসই সবকিছু। এই নীতি ব্যাখ্যা করে কিভাবে আমরা আপনার ব্যক্তিগত তথ্য সংগ্রহ, ব্যবহার এবং সুরক্ষিত করি। সর্বশেষ আপডেট: এপ্রিল ২০২৫।',
      });

  // Section titles
  String get privacySection1Title => _t({'en': '1. Data We Collect', 'hi': '1. हम क्या डेटा एकत्र करते हैं', 'as': '১. আমি কি তথ্য সংগ্ৰহ কৰো', 'bn': '১. আমরা কী তথ্য সংগ্রহ করি'});
  String get privacySection1Body => _t({
        'en': 'We collect information you provide directly:\n\n'
            '• Name, age, email address and phone number\n'
            '• Pregnancy stage, due date, and health history\n'
            '• Mood logs, symptom entries, and daily journal notes\n'
            '• Nutrition plans and vaccination records for your baby\n'
            '• Community posts (can be posted anonymously)\n'
            '• Device type, OS version for crash reporting\n'
            '• Consultation booking details with doctors\n'
            '• Payment information processed via Razorpay (we do not store card details)',
        'hi': 'हम वो जानकारी एकत्र करते हैं जो आप सीधे प्रदान करते हैं:\n\n'
            '• नाम, उम्र, ईमेल पता और फोन नंबर\n'
            '• गर्भावस्था चरण, नियत तारीख और स्वास्थ्य इतिहास\n'
            '• मूड लॉग, लक्षण प्रविष्टियां और दैनिक जर्नल नोट्स\n'
            '• पोषण योजनाएं और आपके शिशु के लिए टीकाकरण रिकॉर्ड\n'
            '• समुदाय पोस्ट (गुमनाम रूप से पोस्ट किए जा सकते हैं)\n'
            '• क्रैश रिपोर्टिंग के लिए डिवाइस प्रकार, OS संस्करण\n'
            '• डॉक्टरों के साथ परामर्श बुकिंग विवरण\n'
            '• Razorpay के माध्यम से संसाधित भुगतान जानकारी (हम कार्ड विवरण संग्रहीत नहीं करते)',
        'as': 'আমি আপুনি প্ৰদান কৰা তথ্য সংগ্ৰহ কৰো:\n\n'
            '• নাম, বয়স, ইমেইল আৰু ফোন নম্বৰ\n'
            '• গৰ্ভাৱস্থাৰ পৰ্যায়, নিৰ্ধাৰিত তাৰিখ আৰু স্বাস্থ্য ইতিহাস\n'
            '• মুড লগ, লক্ষণ প্ৰৱিষ্টি আৰু দৈনিক জাৰ্নাল নোট\n'
            '• পুষ্টি পৰিকল্পনা আৰু শিশুৰ টীকাকৰণ ৰেকৰ্ড\n'
            '• সমাজ পোষ্ট (বেনামী হিছাপে পোষ্ট কৰিব পাৰি)\n'
            '• ক্ৰেছ ৰিপোৰ্টিঙৰ বাবে ডিভাইছ প্ৰকাৰ, OS সংস্কৰণ\n'
            '• চিকিৎসকৰ সৈতে পৰামৰ্শ বুকিং বিৱৰণ\n'
            '• Razorpay-ৰ জৰিয়তে প্ৰক্ৰিয়া কৰা পেমেণ্ট তথ্য (আমি কাৰ্ড বিৱৰণ সংৰক্ষণ নকৰো)',
        'bn': 'আমরা আপনার প্রদানকৃত তথ্য সংগ্রহ করি:\n\n'
            '• নাম, বয়স, ইমেইল ঠিকানা এবং ফোন নম্বর\n'
            '• গর্ভাবস্থার পর্যায়, প্রত্যাশিত তারিখ এবং স্বাস্থ্য ইতিহাস\n'
            '• মুড লগ, উপসর্গ এন্ট্রি এবং দৈনিক জার্নাল নোট\n'
            '• পুষ্টি পরিকল্পনা এবং আপনার শিশুর টিকাদান রেকর্ড\n'
            '• কমিউনিটি পোস্ট (বেনামে পোস্ট করা যায়)\n'
            '• ক্র্যাশ রিপোর্টিংয়ের জন্য ডিভাইস টাইপ, OS সংস্করণ\n'
            '• ডাক্তারদের সাথে পরামর্শ বুকিং বিবরণ\n'
            '• Razorpay-এর মাধ্যমে প্রক্রিয়াকৃত পেমেন্ট তথ্য (আমরা কার্ড বিবরণ সংরক্ষণ করি না)',
      });

  String get privacySection2Title => _t({'en': '2. How We Use Your Data', 'hi': '2. हम आपके डेटा का उपयोग कैसे करते हैं', 'as': '২. আমি আপোনাৰ তথ্য কেনেকৈ ব্যৱহাৰ কৰো', 'bn': '২. আমরা আপনার তথ্য কীভাবে ব্যবহার করি'});
  String get privacySection2Body => _t({
        'en': '• Personalize AI chat responses and health tips for your pregnancy stage\n'
            '• Match you with relevant community members (Suggested Mamas)\n'
            '• Enable doctor consultations via 100ms encrypted video calls\n'
            '• Send daily reminders for mood tracking, medications, and baby milestones\n'
            '• Generate personalized nutrition plans powered by AI\n'
            '• Process premium subscription payments via Razorpay\n'
            '• Improve our app features through anonymized usage analytics\n'
            '• Respond to your support requests',
        'hi': '• अपनी गर्भावस्था चरण के लिए AI चैट प्रतिक्रियाएं और स्वास्थ्य युक्तियां व्यक्तिगत बनाएं\n'
            '• आपको प्रासंगिक समुदाय सदस्यों से मिलाएं\n'
            '• 100ms एन्क्रिप्टेड वीडियो कॉल के माध्यम से डॉक्टर परामर्श सक्षम करें\n'
            '• मूड ट्रैकिंग, दवाओं और बेबी माइलस्टोन के लिए दैनिक अनुस्मारक भेजें\n'
            '• AI द्वारा संचालित व्यक्तिगत पोषण योजनाएं बनाएं\n'
            '• Razorpay के माध्यम से प्रीमियम सदस्यता भुगतान संसाधित करें\n'
            '• गुमनाम उपयोग विश्लेषण के माध्यम से ऐप सुविधाओं में सुधार करें\n'
            '• आपके समर्थन अनुरोधों का जवाब दें',
        'as': '• আপোনাৰ গৰ্ভাৱস্থাৰ পৰ্যায়ৰ বাবে AI চ\'ট প্ৰতিক্ৰিয়া ব্যক্তিগতকৰণ কৰক\n'
            '• আপোনাক প্ৰাসংগিক সমাজ সদস্যৰ সৈতে মিলাওক\n'
            '• 100ms এনক্ৰিপ্টেড ভিডিঅ\'  কলৰ জৰিয়তে চিকিৎসক পৰামৰ্শ সক্ষম কৰক\n'
            '• মুড ট্ৰেকিং আৰু শিশুৰ মাইলষ্টোনৰ বাবে দৈনিক সোঁৱৰণী পঠাওক\n'
            '• AI-চালিত ব্যক্তিগত পুষ্টি পৰিকল্পনা তৈৰি কৰক\n'
            '• Razorpay-ৰ জৰিয়তে প্ৰিমিয়াম চাবস্ক্ৰিপচন পেমেণ্ট প্ৰক্ৰিয়া কৰক\n'
            '• বেনামী ব্যৱহাৰ বিশ্লেষণৰ জৰিয়তে আমাৰ এপ উন্নত কৰক\n'
            '• আপোনাৰ সমৰ্থন অনুৰোধৰ জবাব দিয়ক',
        'bn': '• আপনার গর্ভাবস্থার পর্যায়ের জন্য AI চ্যাট প্রতিক্রিয়া ব্যক্তিগতকৃত করুন\n'
            '• আপনাকে প্রাসঙ্গিক কমিউনিটি সদস্যদের সাথে মেলান\n'
            '• 100ms এনক্রিপ্টেড ভিডিও কলের মাধ্যমে ডাক্তার পরামর্শ সক্ষম করুন\n'
            '• মুড ট্র্যাকিং এবং শিশুর মাইলস্টোনের জন্য দৈনিক অনুস্মারক পাঠান\n'
            '• AI-চালিত ব্যক্তিগতকৃত পুষ্টি পরিকল্পনা তৈরি করুন\n'
            '• Razorpay-এর মাধ্যমে প্রিমিয়াম সাবস্ক্রিপশন পেমেন্ট প্রক্রিয়া করুন\n'
            '• বেনামী ব্যবহার বিশ্লেষণের মাধ্যমে আমাদের অ্যাপ উন্নত করুন\n'
            '• আপনার সহায়তা অনুরোধে সাড়া দিন',
      });

  String get privacySection3Title => _t({'en': '3. Data Security', 'hi': '3. डेटा सुरक्षा', 'as': '৩. তথ্য সুৰক্ষা', 'bn': '৩. তথ্য সুরক্ষা'});
  String get privacySection3Body => _t({
        'en': '• All data is stored on InsForge\'s encrypted PostgreSQL database\n'
            '• Video consultations use 100ms end-to-end encrypted infrastructure\n'
            '• Authentication tokens are stored using secure device storage\n'
            '• Payment data is handled exclusively by Razorpay (PCI-DSS compliant)\n'
            '• We use HTTPS/TLS for all data in transit\n'
            '• Community posts are stored with user IDs; anonymous posts hide your identity',
        'hi': '• सभी डेटा InsForge के एन्क्रिप्टेड PostgreSQL डेटाबेस पर संग्रहीत है\n'
            '• वीडियो परामर्श 100ms एंड-टू-एंड एन्क्रिप्टेड इंफ्रास्ट्रक्चर का उपयोग करते हैं\n'
            '• प्रमाणीकरण टोकन सुरक्षित डिवाइस स्टोरेज का उपयोग करके संग्रहीत किए जाते हैं\n'
            '• भुगतान डेटा विशेष रूप से Razorpay (PCI-DSS अनुपालक) द्वारा संभाला जाता है\n'
            '• हम पारगमन में सभी डेटा के लिए HTTPS/TLS का उपयोग करते हैं\n'
            '• समुदाय पोस्ट उपयोगकर्ता IDs के साथ संग्रहीत हैं; गुमनाम पोस्ट आपकी पहचान छुपाती हैं',
        'as': '• সকলো তথ্য InsForge-ৰ এনক্ৰিপ্টেড PostgreSQL ডেটাবেছত সংৰক্ষিত\n'
            '• ভিডিঅ\'  পৰামৰ্শ 100ms এণ্ড-টু-এণ্ড এনক্ৰিপ্টেড পৰিকাঠামো ব্যৱহাৰ কৰে\n'
            '• প্ৰমাণীকৰণ টোকেন সুৰক্ষিত ডিভাইছ ষ্ট\'ৰেজত সংৰক্ষিত\n'
            '• পেমেণ্ট তথ্য কেৱল Razorpay (PCI-DSS অনুগত) দ্বাৰা পৰিচালিত\n'
            '• যাত্ৰাকালীন সকলো তথ্যৰ বাবে HTTPS/TLS ব্যৱহাৰ কৰা হয়\n'
            '• সমাজ পোষ্ট ব্যৱহাৰকাৰী ID-ৰ সৈতে সংৰক্ষিত; বেনামী পোষ্টে পৰিচয় লুকাই ৰাখে',
        'bn': '• সমস্ত তথ্য InsForge-এর এনক্রিপ্টেড PostgreSQL ডেটাবেসে সংরক্ষিত\n'
            '• ভিডিও পরামর্শ 100ms এন্ড-টু-এন্ড এনক্রিপ্টেড অবকাঠামো ব্যবহার করে\n'
            '• প্রমাণীকরণ টোকেন নিরাপদ ডিভাইস স্টোরেজে সংরক্ষিত\n'
            '• পেমেন্ট ডেটা শুধুমাত্র Razorpay (PCI-DSS সম্মত) দ্বারা পরিচালিত\n'
            '• সমস্ত ট্রানজিট ডেটার জন্য HTTPS/TLS ব্যবহার করা হয়\n'
            '• কমিউনিটি পোস্ট ব্যবহারকারী ID সহ সংরক্ষিত; বেনামী পোস্ট পরিচয় গোপন রাখে',
      });

  String get privacySection4Title => _t({'en': '4. Third-Party Services', 'hi': '4. तृतीय पक्ष सेवाएं', 'as': '৪. তৃতীয় পক্ষৰ সেৱা', 'bn': '৪. তৃতীয় পক্ষের পরিষেবা'});
  String get privacySection4Body => _t({
        'en': '• 100ms (video calls): handles encrypted room sessions for doctor consultations\n'
            '• Razorpay (payments): processes subscription and consultation fees\n'
            '• InsForge (backend): stores all app data in secure cloud infrastructure\n'
            '• Google Fonts: loads typography assets (no personal data shared)\n'
            '\nEach service has its own privacy policy which we encourage you to review.',
        'hi': '• 100ms (वीडियो कॉल): डॉक्टर परामर्श के लिए एन्क्रिप्टेड रूम सत्र संभालता है\n'
            '• Razorpay (भुगतान): सदस्यता और परामर्श शुल्क संसाधित करता है\n'
            '• InsForge (बैकेंड): सुरक्षित क्लाउड में सभी ऐप डेटा संग्रहीत करता है\n'
            '• Google Fonts: टाइपोग्राफी लोड करता है (कोई व्यक्तिगत डेटा साझा नहीं)\n'
            '\nप्रत्येक सेवा की अपनी गोपनीयता नीति है जिसे हम आपको समीक्षा करने के लिए प्रोत्साहित करते हैं।',
        'as': '• 100ms (ভিডিঅ\'  কল): চিকিৎসক পৰামৰ্শৰ বাবে এনক্ৰিপ্টেড ৰুম ছেচন পৰিচালনা কৰে\n'
            '• Razorpay (পেমেণ্ট): চাবস্ক্ৰিপচন আৰু পৰামৰ্শ মাচুল প্ৰক্ৰিয়া কৰে\n'
            '• InsForge (বেকেণ্ড): সুৰক্ষিত ক্লাউডত সকলো এপ তথ্য সংৰক্ষণ কৰে\n'
            '• Google Fonts: টাইপোগ্ৰাফি লোড কৰে (কোনো ব্যক্তিগত তথ্য শ্বেয়াৰ নকৰা হয়)\n'
            '\nপ্ৰতিটো সেৱাৰ নিজস্ব গোপনীয়তা নীতি আছে।',
        'bn': '• 100ms (ভিডিও কল): ডাক্তার পরামর্শের জন্য এনক্রিপ্টেড রুম সেশন পরিচালনা করে\n'
            '• Razorpay (পেমেন্ট): সাবস্ক্রিপশন এবং পরামর্শ ফি প্রক্রিয়া করে\n'
            '• InsForge (ব্যাকএন্ড): নিরাপদ ক্লাউডে সমস্ত অ্যাপ ডেটা সংরক্ষণ করে\n'
            '• Google Fonts: টাইপোগ্রাফি লোড করে (কোনো ব্যক্তিগত তথ্য শেয়ার করা হয় না)\n'
            '\nপ্রতিটি পরিষেবার নিজস্ব গোপনীয়তা নীতি রয়েছে।',
      });

  String get privacySection5Title => _t({'en': '5. Your Rights (DPDP Act & GDPR)', 'hi': '5. आपके अधिकार (DPDP अधिनियम और GDPR)', 'as': '৫. আপোনাৰ অধিকাৰ (DPDP আইন আৰু GDPR)', 'bn': '৫. আপনার অধিকার (DPDP আইন ও GDPR)'});
  String get privacySection5Body => _t({
        'en': '• Right to Access: View all data we hold about you via Settings → Export My Data\n'
            '• Right to Correction: Update your profile anytime from the Profile screen\n'
            '• Right to Erasure: Request complete account deletion via Settings → Request Data Deletion\n'
            '• Right to Portability: Download your data in JSON format\n'
            '• Right to Object: Opt out of marketing communications anytime\n'
            '• Right to Anonymity: Post in the community as an anonymous user',
        'hi': '• पहुंच का अधिकार: सेटिंग्स → मेरा डेटा निर्यात करें के माध्यम से अपना डेटा देखें\n'
            '• सुधार का अधिकार: प्रोफाइल स्क्रीन से कभी भी अपडेट करें\n'
            '• मिटाने का अधिकार: सेटिंग्स → डेटा हटाने का अनुरोध करें\n'
            '• पोर्टेबिलिटी का अधिकार: JSON प्रारूप में डेटा डाउनलोड करें\n'
            '• आपत्ति का अधिकार: कभी भी मार्केटिंग से बाहर निकलें\n'
            '• गुमनामी का अधिकार: समुदाय में गुमनाम रूप से पोस्ट करें',
        'as': '• প্ৰৱেশৰ অধিকাৰ: ছেটিংছ → মোৰ ডেটা ৰপ্তানি কৰক\n'
            '• সংশোধনৰ অধিকাৰ: প্ৰ\'ফাইল স্ক্ৰীনৰ পৰা যিকোনো সময়ত আপডেট কৰক\n'
            '• মচিবৰ অধিকাৰ: ছেটিংছ → ডেটা মচাৰ অনুৰোধ কৰক\n'
            '• পৰ্টেবিলিটিৰ অধিকাৰ: JSON ফৰ্মেটত ডেটা ডাউনলোড কৰক\n'
            '• আপত্তিৰ অধিকাৰ: যিকোনো সময়ত মাৰ্কেটিং ৰপ্ত নধৰক\n'
            '• বেনামীৰ অধিকাৰ: সমাজত বেনামীভাৱে পোষ্ট কৰক',
        'bn': '• অ্যাক্সেসের অধিকার: সেটিংস → আমার ডেটা রপ্তানি করুন\n'
            '• সংশোধনের অধিকার: প্রোফাইল স্ক্রিন থেকে যেকোনো সময় আপডেট করুন\n'
            '• মুছে ফেলার অধিকার: সেটিংস → ডেটা মুছে ফেলার অনুরোধ করুন\n'
            '• বহনযোগ্যতার অধিকার: JSON ফরম্যাটে ডেটা ডাউনলোড করুন\n'
            '• আপত্তির অধিকার: যেকোনো সময় মার্কেটিং থেকে বেরিয়ে যান\n'
            '• বেনামিতার অধিকার: কমিউনিটিতে বেনামে পোস্ট করুন',
      });

  String get privacySection6Title => _t({'en': '6. Children\'s Privacy', 'hi': '6. बच्चों की गोपनीयता', 'as': '৬. শিশুৰ গোপনীয়তা', 'bn': '৬. শিশুদের গোপনীয়তা'});
  String get privacySection6Body => _t({
        'en': 'MaaCare is designed for adults aged 18 and above. We do not knowingly collect personal information from minors. Baby health data (vaccinations, nutrition) is collected as part of the parent\'s account and is used solely for that parent\'s caregiving needs.',
        'hi': 'MaaCare 18 वर्ष और उससे अधिक आयु के वयस्कों के लिए डिज़ाइन किया गया है। हम जानबूझकर नाबालिगों की व्यक्तिगत जानकारी एकत्र नहीं करते। शिशु स्वास्थ्य डेटा माता-पिता के खाते के हिस्से के रूप में एकत्र किया जाता है।',
        'as': 'MaaCare ১৮ বছৰ আৰু তাতকৈ অধিক বয়সৰ প্ৰাপ্তবয়স্কৰ বাবে ডিজাইন কৰা হৈছে। আমি ইচ্ছাকৃতভাৱে নাবালকৰ ব্যক্তিগত তথ্য সংগ্ৰহ নকৰো। শিশুৰ স্বাস্থ্য তথ্য মাতা-পিতাৰ একাউণ্টৰ অংশ হিছাপে সংগ্ৰহ কৰা হয়।',
        'bn': 'MaaCare ১৮ বছর এবং তার বেশি বয়সের প্রাপ্তবয়স্কদের জন্য ডিজাইন করা হয়েছে। আমরা ইচ্ছাকৃতভাবে অপ্রাপ্তবয়স্কদের ব্যক্তিগত তথ্য সংগ্রহ করি না। শিশুর স্বাস্থ্য ডেটা পিতামাতার অ্যাকাউন্টের অংশ হিসেবে সংগ্রহ করা হয়।',
      });

  String get privacySection7Title => _t({'en': '7. Contact Us', 'hi': '7. हमसे संपर्क करें', 'as': '৭. আমাৰ সৈতে যোগাযোগ কৰক', 'bn': '৭. আমাদের সাথে যোগাযোগ করুন'});
  String get privacySection7Body => _t({
        'en': 'For any privacy-related concerns, data requests, or questions:\n\n'
            '📧 Email: privacy@maacare.app\n'
            '📍 Address: MaaCare Health Technologies, India\n'
            '⏰ Response time: Within 72 hours\n\n'
            'We are committed to resolving all privacy concerns promptly.',
        'hi': 'किसी भी गोपनीयता संबंधी चिंता, डेटा अनुरोध या प्रश्नों के लिए:\n\n'
            '📧 ईमेल: privacy@maacare.app\n'
            '📍 पता: MaaCare Health Technologies, भारत\n'
            '⏰ प्रतिक्रिया समय: 72 घंटों के भीतर\n\n'
            'हम सभी गोपनीयता चिंताओं को शीघ्र हल करने के लिए प्रतिबद्ध हैं।',
        'as': 'যিকোনো গোপনীয়তা সম্পৰ্কীয় সমস্যা, তথ্য অনুৰোধ বা প্ৰশ্নৰ বাবে:\n\n'
            '📧 ইমেইল: privacy@maacare.app\n'
            '📍 ঠিকনা: MaaCare Health Technologies, ভাৰত\n'
            '⏰ প্ৰতিক্ৰিয়াৰ সময়: ৭২ ঘণ্টাৰ ভিতৰত\n\n'
            'আমি সকলো গোপনীয়তাৰ সমস্যা দ্ৰুতভাৱে সমাধান কৰিবলৈ প্ৰতিশ্ৰুতিবদ্ধ।',
        'bn': 'যেকোনো গোপনীয়তা সংক্রান্ত উদ্বেগ, ডেটা অনুরোধ বা প্রশ্নের জন্য:\n\n'
            '📧 ইমেইল: privacy@maacare.app\n'
            '📍 ঠিকানা: MaaCare Health Technologies, ভারত\n'
            '⏰ প্রতিক্রিয়ার সময়: ৭২ ঘণ্টার মধ্যে\n\n'
            'আমরা সমস্ত গোপনীয়তার উদ্বেগ দ্রুত সমাধান করতে প্রতিশ্রুতিবদ্ধ।',
      });

  String get agreeAndContinue => _t({'en': 'Agree & Continue 💕', 'hi': 'सहमत और जारी रखें 💕', 'as': 'সম্মত আৰু অব্যাহত ৰাখক 💕', 'bn': 'সম্মত এবং চালিয়ে যান 💕'});

  // ══════════════════════════════════════════════════
  // THEME LABELS
  // ══════════════════════════════════════════════════
  String get themeLight => _t({'en': 'Light', 'hi': 'लाइट', 'as': 'লাইট', 'bn': 'লাইট'});
  String get themeDark => _t({'en': 'Dark', 'hi': 'डार्क', 'as': 'ডাৰ্ক', 'bn': 'ডার্ক'});
  String get themePink => _t({'en': 'Pink', 'hi': 'गुलाबी', 'as': 'গোলাপী', 'bn': 'গোলাপি'});
  String get themeSelect => _t({'en': 'Choose Theme', 'hi': 'थीम चुनें', 'as': 'থিম বাছনি কৰক', 'bn': 'থিম নির্বাচন করুন'});

  // ══════════════════════════════════════════════════
  // HOME SCREEN
  // ══════════════════════════════════════════════════
  String get goodMorning => _t({'en': 'Good morning', 'hi': 'सुप्रभात', 'as': 'সুপ্ৰভাত', 'bn': 'সুপ্রভাত'});
  String get goodAfternoon => _t({'en': 'Good afternoon', 'hi': 'शुभ दोपहर', 'as': 'শুভ আবেলি', 'bn': 'শুভ বিকাল'});
  String get goodEvening => _t({'en': 'Good evening', 'hi': 'शुभ संध्या', 'as': 'শুভ সন্ধিয়া', 'bn': 'শুভ সন্ধ্যা'});
  String get mama => _t({'en': 'Mama', 'hi': 'माँ', 'as': 'মা', 'bn': 'মা'});
  String get doingAmazingly => _t({'en': 'You\'re doing amazingly! ✨', 'hi': 'आप बहुत अच्छा कर रही हैं! ✨', 'as': 'আপুনি বৰ ধুনীয়াকৈ কৰিছে! ✨', 'bn': 'আপনি খুব ভালো করছেন! ✨'});

  String get connectionLost => _t({'en': 'Connection Lost', 'hi': 'संपर्क टूट गया', 'as': 'সংযোগ বিচ্ছিন্ন', 'bn': 'সংযোগ বিচ্ছিন্ন'});
  String get dashboardError => _t({'en': 'We couldn\'t load your amazing dashboard. Let\'s try again.', 'hi': 'हम आपका डैशबोर्ड लोड नहीं कर सके। आइए फिर से प्रयास करें।', 'as': 'আমি আপোনাৰ ডেচবৰ্ড ল\'ড কৰিব নোৱাৰিলো। আকৌ চেষ্টা কৰোঁ আহক।', 'bn': 'আমরা আপনার ড্যাশবোর্ড লোড করতে পারিনি। চলুন আবার চেষ্টা করি।'});
  String get retry => _t({'en': 'Retry', 'hi': 'पुनः प्रयास करें', 'as': 'পুনৰ চেষ্টা', 'bn': 'পুনরায় চেষ্টা'});

  String get week => _t({'en': 'WEEK', 'hi': 'सप्ताह', 'as': 'সপ্তাহ', 'bn': 'সপ্তাহ'});
  String get sizeOfA => _t({'en': 'Size of a', 'hi': 'आकार', 'as': 'আকাৰ', 'bn': 'আকার'});
  String get weeksToMeet => _t({'en': 'weeks to meet! 🌟', 'hi': 'मिलने में सप्ताह! 🌟', 'as': 'লগ পাবলৈ সপ্তাহ! 🌟', 'bn': 'দেখা হতে সপ্তাহ! 🌟'});
  String get guide => _t({'en': 'Guide', 'hi': 'मार्गदर्शक', 'as': 'মাৰ্গদৰ্শক', 'bn': 'গাইড'});

  String get howFeelingToday => _t({'en': 'How are you feeling today?', 'hi': 'आज आप कैसा महसूस कर रही हैं?', 'as': 'আজি আপুনি কেনে অনুভৱ কৰিছে?', 'bn': 'আজ আপনি কেমন অনুভব করছেন?'});
  String get moodLogged => _t({'en': 'Mood logged! You\'re amazing! +5 ⭐', 'hi': 'मूड दर्ज हो गया! आप अद्भुत हैं! +5 ⭐', 'as': 'মুড ল\'গ কৰা হৈছে! আপুনি অসাধাৰণ! +5 ⭐', 'bn': 'মুড লগ করা হয়েছে! আপনি অসাধারণ! +5 ⭐'});

  String get healthSupport => _t({'en': 'Health Support', 'hi': 'स्वास्थ्य सहायता', 'as': 'স্বাস্থ্য সাহায্য', 'bn': 'স্বাস্থ্য সহায়তা'});
  String get trackSymptomsHelp => _t({'en': 'Track symptoms, get expert help', 'hi': 'लक्षण ट्रैक करें, विशेषज्ञ से मदद लें', 'as': 'লক্ষণ ট্ৰেক কৰক, বিশেষজ্ঞৰ সহায় লওক', 'bn': 'উপসর্গ ট্র্যাক করুন, বিশেষজ্ঞের সাহায্য নিন'});
  String get yourHealthScore => _t({'en': 'Your Health Score', 'hi': 'आपका स्वास्थ्य स्कोर', 'as': 'আপোনাৰ স্বাস্থ্য স্কোৰ', 'bn': 'আপনার স্বাস্থ্য স্কোর'});

  // ══════════════════════════════════════════════════
  // BMI & CALORIE CALCULATOR
  // ══════════════════════════════════════════════════
  String get bmiTitle => _t({'en': 'Smart Health Calculator', 'hi': 'स्मार्ट हेल्थ कैलकुलेटर', 'as': 'স্মাৰ্ট স্বাস্থ্য কেলকুলেটৰ', 'bn': 'স্মার্ট হেলথ ক্যালকুলেটর'});
  String get bmiSubtitle => _t({'en': 'BMI + Daily Calorie Need based on your details', 'hi': 'आपके विवरण के आधार पर बीएमआई + दैनिक कैलोरी', 'as': 'BMI + আপোনাৰ বিৱৰণৰ ওপৰত ভিত্তি কৰি দৈনিক কেলৰি', 'bn': 'BMI + আপনার বিবরণীর উপর ভিত্তি করে দৈনিক ক্যালরি'});
  String get yourDetails => _t({'en': 'Your Details', 'hi': 'आपका विवरण', 'as': 'আপোনাৰ বিৱৰণ', 'bn': 'আপনার বিবরণ'});
  String get weight => _t({'en': 'Weight', 'hi': 'वज़न', 'as': 'ওজন', 'bn': 'ওজন'});
  String get height => _t({'en': 'Height', 'hi': 'ऊंचाई', 'as': 'উচ্চতা', 'bn': 'উচ্চতা'});
  String get age => _t({'en': 'Age', 'hi': 'आयु', 'as': 'বয়স', 'bn': 'বয়স'});
  String get activityLevel => _t({'en': 'Activity Level', 'hi': 'गतिविधि स्तर', 'as': 'ক্ৰিয়াকলাপৰ স্তৰ', 'bn': 'কার্যকলাপ স্তর'});
  String get pregnancyStage => _t({'en': 'Pregnancy Stage', 'hi': 'गर्भावस्था का चरण', 'as': 'গর্ভাবস্থাৰ পর্যায়', 'bn': 'গর্ভাবস্থার পর্যায়'});
  String get calculateNow => _t({'en': 'Calculate Now', 'hi': 'अभी गणना करें', 'as': 'এতিয়া গণনা কৰক', 'bn': 'এখনই গণনা করুন'});
  String get saveProgress => _t({'en': 'Save Progress', 'hi': 'प्रगति सहेजें', 'as': 'প্ৰগতি সংৰক্ষণ কৰক', 'bn': 'অগ্রগতি সংরক্ষণ করুন'});
  String get bmiMetrics => _t({'en': 'Metrics History', 'hi': 'मीट्रिक्स इतिहास', 'as': 'মেট্ৰিক্সৰ ইতিহাস', 'bn': 'মেট্রিক্স ইতিহাস'});
}

// ── Delegate ──────────────────────────────────────
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'as', 'bn'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
