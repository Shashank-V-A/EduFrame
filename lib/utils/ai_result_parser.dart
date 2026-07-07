class AiParsedSections {
  const AiParsedSections({
    this.objectives = '',
    this.activities = '',
    this.homework = '',
    this.notes = '',
    this.fullText = '',
  });

  final String objectives;
  final String activities;
  final String homework;
  final String notes;
  final String fullText;

  bool get hasStructuredContent =>
      objectives.isNotEmpty || activities.isNotEmpty || homework.isNotEmpty;
}

class AiResultParser {
  static AiParsedSections parse(String text) {
    final objectives = _extractSection(text, ['OBJECTIVES:', 'OBJECTIVES', 'Learning objectives']);
    final activities = _extractSection(text, [
      'ACTIVITIES:',
      'ACTIVITIES',
      'Activities & teaching procedure',
      'ACTIVITIES & PROCEDURE:',
    ]);
    final homework = _extractSection(text, ['HOMEWORK:', 'HOMEWORK', 'Homework / assignment']);
    final notes = _extractSection(text, ['NOTES:', 'NOTES', 'Teacher notes', 'DIFFERENTIATION:']);

    return AiParsedSections(
      objectives: objectives,
      activities: activities,
      homework: homework,
      notes: notes,
      fullText: text.trim(),
    );
  }

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
    'ACTIVITIES:',
    'HOMEWORK:',
    'NOTES:',
    'DIFFERENTIATION:',
    'OBJECTIVES',
    'ACTIVITIES',
    'HOMEWORK',
  ];
}
