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

  // More
  String get moreTitle => _t('More', 'अधिक');
  String get moreSubtitle =>
      _t('Settings, classes, and export.', 'सेटिंग्स, कक्षाएँ और निर्यात।');
  String get moreClasses => _t('Classes', 'कक्षाएँ');
  String get moreClassesHint => _t('Manage the classes you teach', 'जिन कक्षाओं को आप पढ़ाते हैं उन्हें प्रबंधित करें');
  String get moreExport => _t('Export PDF', 'PDF निर्यात');
  String get moreExportHint =>
      _t('Share lesson plans with your HOD', 'अपने HOD के साथ पाठ योजना साझा करें');
  String get moreSettings => _t('Settings', 'सेटिंग्स');
  String get moreSettingsHint =>
      _t('Google account and notifications', 'Google खाता और अनुस्मारक');

  // App
  String get appTitle => _t('EduFrame', 'EduFrame');
  String get tagline =>
      _t('Plan tonight. Teach tomorrow.', 'आज रात योजना बनाएँ, कल पढ़ाएँ।');
  String greetingSubtitle(String greeting) => _t('$greeting $tagline', '$greeting $tagline');
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
  String get classLabel => _t('Class & section *', 'कक्षा और अनुभाग *');
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
  String get aiLessonContext => _t('Lesson context', 'पाठ संदर्भ');
  String get aiTopicLabel => _t('Topic', 'विषय');
  String get aiTopicHint => _t('e.g. Fractions', 'उदा. भिन्न');
  String get aiClassLabel => _t('Class', 'कक्षा');
  String get aiClassHint => _t('e.g. 2 · Sec B', 'उदा. 2 · Sec B');
  String get aiSubjectLabel => _t('Subject', 'विषय');
  String get aiSubjectHint => _t('e.g. Mathematics', 'उदा. गणित');
  String get aiTopicRequired => _t('Enter a topic in lesson context first.', 'पहले पाठ संदर्भ में विषय लिखें।');
  String get aiChatWelcome => _t(
        'Ask anything about your lesson — or tap a quick suggestion above.',
        'अपने पाठ के बारे में कुछ भी पूछें — या ऊपर सुझाव टैप करें।',
      );
  String get aiChatHint => _t('Ask a follow-up or request changes...', 'फॉलो-अप पूछें या बदलाव माँगें...');
  String get aiClearChat => _t('Clear chat', 'चैट साफ़ करें');
  String get aiQuickActivities => _t('Activities', 'गतिविधियाँ');
  String get aiQuickHomework => _t('Homework', 'गृहकार्य');
  String get aiQuickDifferentiation => _t('Differentiation', 'विभेदन');
  String get aiQuickExplain => _t('Explain topic', 'विषय समझाएँ');
  String get useInPlan => _t('Use in plan', 'योजना में उपयोग करें');
  String get applyObjectives => _t('Apply objectives', 'उद्देश्य लागू करें');
  String get applyActivities => _t('Apply activities', 'गतिविधियाँ लागू करें');
  String get applyMaterials => _t('Apply materials', 'सामग्री लागू करें');
  String get applyHomework => _t('Apply homework', 'गृहकार्य लागू करें');
  String get applyNotes => _t('Apply teacher notes', 'शिक्षक नोट्स लागू करें');
  String get createPlanWithAi => _t('Create plan with this', 'इससे योजना बनाएँ');

  // Share
  String get sharePlan => _t('Share', 'साझा करें');
  String get aiImprovePlan => _t('Improve', 'सुधारें');
  String get editPlan => _t('Edit plan', 'योजना संपादित करें');
  String get duplicatePlan => _t('Duplicate', 'प्रतिलिपि');
  String get deletePlan => _t('Delete plan', 'योजना हटाएँ');
  String get duplicatePickDate => _t('Duplicate to which date?', 'किस तारीख पर प्रतिलिपि बनाएँ?');
  String duplicateSuccess(String date) =>
      _t('Copied to $date.', '$date पर प्रतिलिपि बनाई गई।');
  String get saveToDevice => _t('Save to device', 'डिवाइस पर सहेजें');

  // Settings
  String get settingsTitle => _t('Settings', 'सेटिंग्स');
  String get settingsSubtitle =>
      _t('Account, appearance, and reminders.', 'खाता, दिखावट और अनुस्मारक।');
  String get darkMode => _t('Dark mode', 'डार्क मोड');
  String get hindiLabels => _t('Hindi labels', 'हिंदी लेबल');
  String get hindiLabelsHint =>
      _t('Show Hindi text for buttons and menus.', 'बटन और मेनू के लिए हिंदी दिखाएँ।');
  String get backupRestore => _t('Backup & restore', 'बैकअप और पुनर्स्थापना');
  String get backupNow => _t('Backup to Google Drive', 'Google Drive पर बैकअप');
  String get restoreBackup => _t('Restore from backup', 'बैकअप से पुनर्स्थापित');
  String get shareBackupFile => _t('Share backup file', 'बैकअप फ़ाइल साझा करें');
  String get restoreFromDrive =>
      _t('Restore from Google Drive', 'Google Drive से पुनर्स्थापित');
  String get restoreFromFile =>
      _t('Restore from file', 'फ़ाइल से पुनर्स्थापित');
  String get backupSuccess => _t('Backup complete.', 'बैकअप पूरा हुआ।');
  String get restoreSuccess => _t('Restore complete.', 'पुनर्स्थापना पूरी हुई।');
  String get notifications => _t('Class reminders', 'कक्षा अनुस्मारक');
  String get saveSettings => _t('Save settings', 'सेटिंग्स सहेजें');
  String get logout => _t('Log out', 'लॉग आउट');
  String get privacyPolicy => _t('Privacy policy', 'गोपनीयता नीति');
  String get termsOfService => _t('Terms of service', 'सेवा की शर्तें');
  String get deleteMyData => _t('Delete my data', 'मेरा डेटा हटाएँ');
  String get deleteMyDataHint => _t(
        'Remove all lesson plans, classes, and timetable for this account on this device.',
        'इस डिवाइस पर इस खाते की सभी पाठ योजनाएँ, कक्षाएँ और समय सारणी हटाएँ।',
      );
  String get deleteMyDataConfirm => _t(
        'This permanently deletes your local EduFrame data for this Google account on this device. You will be signed out. Drive backups are not deleted.',
        'यह इस डिवाइस पर इस Google खाते का स्थानीय EduFrame डेटा स्थायी रूप से हटा देगा। आप साइन आउट हो जाएँगे। Drive बैकअप नहीं हटेंगे।',
      );
  String get deleteConfirmAction => _t('Delete and sign out', 'हटाएँ और साइन आउट');
  String get cancel => _t('Cancel', 'रद्द करें');
  String get legalSection => _t('Legal', 'कानूनी');
  String get dataSafetySection => _t('Your data', 'आपका डेटा');
  String get aboutApp => _t('About EduFrame', 'EduFrame के बारे में');

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
  String get allPlansSubtitle => _t(
        "Browse every lesson you've written — reuse and refine.",
        'आपके द्वारा लिखे हर पाठ को देखें — दोबारा उपयोग करें और सुधारें।',
      );
  String get plansSearch => _t('Search plans', 'योजनाएँ खोजें');
  String get plansSearchHint =>
      _t('Topic, activity, homework...', 'विषय, गतिविधि, गृहकार्य...');
  String get plansSearchPrompt => _t(
        'Type a keyword to find matching lesson plans.',
        'मिलती योजनाएँ खोजने के लिए कीवर्ड लिखें।',
      );
  String get plansSearchEmpty => _t('No matching plans', 'कोई मिलती योजना नहीं');
  String get plansSearchEmptyHint =>
      _t('Try a shorter keyword or different topic.', 'छोटा कीवर्ड या दूसा विषय आज़माएँ।');
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
