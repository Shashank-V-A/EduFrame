import 'package:flutter/material.dart';

/// Lightweight English / Hindi strings (no code-gen).
class AppStrings {
  AppStrings(this.languageCode);

  final String languageCode;

  bool get isHindi => languageCode == 'hi';

  static const supported = ['en', 'hi'];

  // Navigation
  String get navToday => _t('Today', 'आज');
  String get navPlans => _t('Plans', 'योजनाएँ');
  String get navTimetable => _t('Timetable', 'समय सारणी');
  String get navAi => _t('AI', 'AI');
  String get navMore => _t('More', 'अधिक');

  // Today
  String get appTitle => _t('EduFrame', 'EduFrame');
  String greetingSubtitle(String greeting) =>
      _t('$greeting Plan tonight, teach tomorrow with confidence.',
          '$greeting आज रात योजना बनाएँ, कल आत्मविश्वास से पढ़ाएँ।');
  String get planForTomorrow => _t('Plan for tomorrow', 'कल के लिए योजना');
  String get planForToday => _t('Plan for today', 'आज के लिए योजना');
  String get noPlansTomorrow => _t('No plans for tomorrow yet', 'कल के लिए अभी कोई योजना नहीं');
  String get noPlansTomorrowHint =>
      _t('Most teachers plan the night before — tap below to start.',
          'अधिकांश शिक्षक रात को योजना बनाते हैं — नीचे टैप करें।');
  String get planNow => _t('Plan now', 'अभी योजना बनाएँ');
  String get nothingToday => _t('Nothing scheduled for today', 'आज के लिए कुछ निर्धारित नहीं');
  String get addPlanToday => _t('Add a plan if you still have classes today.',
      'यदि आज भी कक्षाएँ हैं तो योजना जोड़ें।');

  // Plan form
  String get classLabel => _t('Class *', 'कक्षा *');
  String get addClassFirst =>
      _t('Add a class first from More > Classes.', 'पहले अधिक > कक्षाएँ से कक्षा जोड़ें।');
  String get dateLabel => _t('Date *', 'तारीख *');
  String get topicLabel => _t('Topic / lesson title *', 'विषय / पाठ शीर्षक *');
  String get objectivesLabel => _t('Learning objectives', 'सीखने के उद्देश्य');
  String get materialsLabel => _t('Materials / resources', 'सामग्री / संसाधन');
  String get activitiesLabel => _t('Activities & teaching procedure', 'गतिविधियाँ और शिक्षण प्रक्रिया');
  String get homeworkLabel => _t('Homework / assignment', 'गृहकार्य / असाइनमेंट');
  String get notesLabel => _t('Teacher notes', 'शिक्षक नोट्स');
  String get tomorrow => _t('Tomorrow', 'कल');
  String get nextMonday => _t('Next Monday', 'अगला सोमवार');
  String get pickDate => _t('Pick date', 'तारीख चुनें');

  // Timetable
  String get timetableTitle => _t('Timetable', 'समय सारणी');
  String get timetableSubtitle =>
      _t('Weekly schedule with 5-minute class reminders.', 'साप्ताहिक समय सारणी व 5 मिनट पूर्व अनुस्मारक।');
  String get noPeriods => _t('No periods for this day', 'इस दिन कोई पीरियड नहीं');
  String get addPeriodsHint =>
      _t('Add your school periods to get reminders before each class.',
          'प्रत्येक कक्षा से पहले अनुस्मारक पाने के लिए पीरियड जोड़ें।');
  String get addPeriod => _t('Add period', 'पीरियड जोड़ें');
  String get planThisClass => _t('Plan this class', 'इस कक्षा की योजना बनाएँ');
  String get addPeriodAction => _t('Add a period', 'पीरियड जोड़ें');

  // AI
  String get aiTitle => _t('AI Assist', 'AI सहायता');
  String get aiSubtitle => _t(
        'Groq-powered help that supports your planning — you stay in control.',
        'Groq-संचालित सहायता जो आपकी योजना में मदद करती है — नियंत्रण आपके पास।');
  String get useInPlan => _t('Use in plan', 'योजना में उपयोग करें');
  String get applyObjectives => _t('Apply objectives', 'उद्देश्य लागू करें');
  String get applyActivities => _t('Apply activities', 'गतिविधियाँ लागू करें');
  String get applyHomework => _t('Apply homework', 'गृहकार्य लागू करें');
  String get applyNotes => _t('Apply to notes', 'नोट्स में लागू करें');
  String get createPlanWithAi => _t('Create plan with this', 'इससे योजना बनाएँ');

  // Share
  String get sharePlan => _t('Share plan', 'योजना साझा करें');
  String get shareWhatsApp => _t('Share via WhatsApp', 'WhatsApp से साझा करें');

  // Settings
  String get settingsTitle => _t('Settings', 'सेटिंग्स');
  String get settingsSubtitle =>
      _t('Account, appearance, backup, and reminders.', 'खाता, दिखावट, बैकअप और अनुस्मारक।');
  String get darkMode => _t('Dark mode', 'डार्क मोड');
  String get hindiLabels => _t('Hindi labels', 'हिंदी लेबल');
  String get hindiLabelsHint =>
      _t('Show Hindi text for buttons and menus.', 'बटन और मेनू के लिए हिंदी दिखाएँ।');
  String get backupRestore => _t('Backup & restore', 'बैकअप और पुनर्स्थापना');
  String get backupNow => _t('Backup to Google Drive', 'Google Drive पर बैकअप');
  String get restoreBackup => _t('Restore from backup', 'बैकअप से पुनर्स्थापित');
  String get shareBackupFile => _t('Share backup file', 'बैकअप फ़ाइल साझा करें');
  String get notifications => _t('Class reminders', 'कक्षा अनुस्मारक');
  String get saveSettings => _t('Save settings', 'सेटिंग्स सहेजें');
  String get logout => _t('Log out', 'लॉग आउट');

  // Onboarding
  String get onboardingSkip => _t('Skip', 'छोड़ें');
  String get onboardingNext => _t('Next', 'आगे');
  String get onboardingStart => _t('Get started', 'शुरू करें');
  String get onboarding1Title => _t('Add your classes', 'अपनी कक्षाएँ जोड़ें');
  String get onboarding1Body => _t(
        'Set up the classes you teach — subject and section included.',
        'जिन कक्षाओं को आप पढ़ाते हैं उन्हें सेट करें — विषय और अनुभाग सहित।');
  String get onboarding2Title => _t('Build your timetable', 'समय सारणी बनाएँ');
  String get onboarding2Body => _t(
        'Add weekly periods and get reminders 5 minutes before each class.',
        'साप्ताहिक पीरियड जोड़ें और प्रत्येक कक्षा से 5 मिनट पहले अनुस्मारक पाएँ।');
  String get onboarding3Title => _t('Plan for tomorrow', 'कल के लिए योजना बनाएँ');
  String get onboarding3Body => _t(
        'Write lesson plans tonight. Export PDF or share on WhatsApp anytime.',
        'आज रात पाठ योजना लिखें। कभी भी PDF निर्यात या WhatsApp पर साझा करें।');

  // Plans
  String get allPlans => _t('All plans', 'सभी योजनाएँ');
  String get emptyNotebook => _t('Your notebook is empty', 'आपकी नोटबुक खाली है');
  String get startFromToday =>
      _t('Start with tomorrow\'s classes from the Today tab.', 'आज टैब से कल की कक्षाओं से शुरू करें।');

  String _t(String en, String hi) => isHindi ? hi : en;
}

extension AppStringsContext on BuildContext {
  AppStrings get strings {
    final locale = Localizations.localeOf(this);
    return AppStrings(locale.languageCode);
  }
}
