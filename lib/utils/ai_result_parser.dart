class AiParsedSections {
  const AiParsedSections({
    this.objectives = '',
    this.materials = '',
    this.activities = '',
    this.homework = '',
    this.notes = '',
    this.fullText = '',
  });

  final String objectives;
  final String materials;
  final String activities;
  final String homework;
  final String notes;
  final String fullText;

  bool get hasStructuredContent =>
      objectives.isNotEmpty ||
      materials.isNotEmpty ||
      activities.isNotEmpty ||
      homework.isNotEmpty ||
      notes.isNotEmpty;
}

class AiResultParser {
  static AiParsedSections parse(String text) {
    final normalized = _normalize(text);

    final objectives = _extractSection(normalized, [
      'OBJECTIVES:',
      'OBJECTIVES',
      'Learning objectives:',
      'Learning objectives',
      'उद्देश्य:',
      'उद्देश्य',
    ]);
    final materials = _extractSection(normalized, [
      'MATERIALS:',
      'MATERIALS',
      'Materials needed:',
      'Materials Needed:',
      'Materials / resources:',
      'Materials / resources',
      'MATERIALS / RESOURCES:',
      'सामग्री:',
      'सामग्री',
    ]);
    final activities = _extractSection(normalized, [
      'ACTIVITIES:',
      'ACTIVITIES',
      'Activities & teaching procedure:',
      'Activities & procedure:',
      'ACTIVITIES & PROCEDURE:',
      'गतिविधियाँ:',
      'गतिविधियां:',
      'गतिविधि:',
    ]);
    final homework = _extractSection(normalized, [
      'HOMEWORK:',
      'HOMEWORK',
      'Homework / assignment:',
      'Homework / assignment',
      'Assessment:',
      'गृहकार्य:',
      'गृहकार्य',
    ]);
    final notes = _extractSection(normalized, [
      'TEACHER NOTES:',
      'TEACHER NOTES',
      'NOTES:',
      'NOTES',
      'Teacher notes:',
      'Teacher notes',
      'DIFFERENTIATION:',
      'Note:',
      'शिक्षक नोट्स:',
      'नोट्स:',
    ]);

    var resolvedActivities = activities;
    if (resolvedActivities.isEmpty) {
      resolvedActivities = extractLessonFlow(normalized);
    }

    return AiParsedSections(
      objectives: objectives,
      materials: materials,
      activities: resolvedActivities,
      homework: homework,
      notes: notes,
      fullText: text.trim(),
    );
  }

  static String extractLessonFlow(String text) {
    final flowHeaders = [
      'Warm-up',
      'Warm up',
      'Introduction',
      'Teaching',
      'Practice',
      'Wrap-up',
      'Wrap up',
      'Main activity',
      'Lesson flow',
      'Closing',
    ];

    final buffer = StringBuffer();
    for (final header in flowHeaders) {
      final content = _extractSection(text, ['$header:', '$header (', header]);
      if (content.isNotEmpty) {
        buffer.writeln('$header:');
        buffer.writeln(content);
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  static String _normalize(String text) => text.replaceAll('**', '').replaceAll('__', '');

  static String _extractSection(String text, List<String> headers) {
    final lower = text.toLowerCase();
    for (final header in headers) {
      final idx = lower.indexOf(header.toLowerCase());
      if (idx == -1) continue;

      final start = idx + header.length;
      var end = text.length;

      for (final other in _allHeaders) {
        if (headers.any((h) => h.toLowerCase() == other.toLowerCase())) continue;
        final next = lower.indexOf(other.toLowerCase(), start);
        if (next != -1 && next < end) end = next;
      }

      return text.substring(start, end).trim();
    }
    return '';
  }

  static const _allHeaders = [
    'OBJECTIVES:',
    'OBJECTIVES',
    'Learning objectives:',
    'MATERIALS:',
    'MATERIALS',
    'Materials needed:',
    'Materials Needed:',
    'ACTIVITIES:',
    'ACTIVITIES',
    'HOMEWORK:',
    'HOMEWORK',
    'Assessment:',
    'TEACHER NOTES:',
    'NOTES:',
    'DIFFERENTIATION:',
    'Note:',
    'Warm-up',
    'Warm up',
    'Introduction',
    'Teaching',
    'Practice',
    'Wrap-up',
    'Wrap up',
    'Main activity',
    'Lesson flow',
    'Closing',
    'Lesson Topic:',
    'Grade:',
    'Time:',
  ];
}
