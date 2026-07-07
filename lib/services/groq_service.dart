import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'locale_service.dart';

class GroqService {
  GroqService._();
  static final GroqService instance = GroqService._();

  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';
  static const _bundledApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const _productionProxy = 'https://eduframe.vercel.app/api/groq';
  static const _proxyUrl = String.fromEnvironment(
    'GROQ_PROXY_URL',
    defaultValue: _productionProxy,
  );

  String _languageInstruction() {
    final code = LocaleService.instance.locale.value.languageCode;
    if (code == 'hi') {
      return 'IMPORTANT: Write your entire response in Hindi using Devanagari script. '
          'Use clear, simple Hindi suitable for Indian school teachers. ';
    }
    return '';
  }

  String _formatInstruction() {
    return 'Format rules: Use plain text only. Do not use markdown, asterisks, hashtags, or ** for emphasis. '
        'Use ALL-CAPS section headings on their own line ending with a colon (e.g. OBJECTIVES:). '
        'Use hyphen bullets (- item) for lists. Keep answers structured and easy to read on a phone. ';
  }

  Future<String> _chat(String systemPrompt, String userPrompt) {
    return _chatWithHistory(
      systemPrompt: systemPrompt,
      messages: [
        {'role': 'user', 'content': userPrompt},
      ],
    );
  }

  Future<String> _chatWithHistory({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 900,
  }) async {
    final system = '${_languageInstruction()}${_formatInstruction()}$systemPrompt';
    if (_proxyUrl.trim().isNotEmpty) {
      return _chatViaProxy(system, messages, maxTokens: maxTokens);
    }
    return _chatDirect(system, messages, maxTokens: maxTokens);
  }

  Future<String> _chatViaProxy(
    String systemPrompt,
    List<Map<String, String>> messages, {
    int maxTokens = 900,
  }) async {
    final idToken = await AuthService.instance.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Sign in with Google to use AI Assist.');
    }

    final response = await http.post(
      Uri.parse(_proxyUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'system': systemPrompt,
        'messages': messages,
        'model': _model,
        'max_tokens': maxTokens,
        'temperature': 0.4,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI proxy error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('content')) {
      return (data['content'] as String).trim();
    }
    final choices = data['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final message = choices.first['message'] as Map<String, dynamic>;
      return (message['content'] as String).trim();
    }
    throw Exception('No response from AI proxy');
  }

  Future<String> _chatDirect(
    String systemPrompt,
    List<Map<String, String>> messages, {
    int maxTokens = 900,
  }) async {
    if (_bundledApiKey.trim().isEmpty) {
      throw Exception(
        'AI is not configured. Set GROQ_PROXY_URL for production or rebuild with --dart-define=GROQ_API_KEY=your_key',
      );
    }

    final response = await http.post(
      Uri.parse(_groqUrl),
      headers: {
        'Authorization': 'Bearer $_bundledApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': 0.4,
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages,
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    if (choices.isEmpty) throw Exception('No response from AI');
    final message = choices.first['message'] as Map<String, dynamic>;
    return (message['content'] as String).trim();
  }

  Future<String> aiAssistChat({
    required List<Map<String, String>> messages,
    required String topic,
    required String className,
    required String subject,
  }) {
    final context = StringBuffer();
    if (topic.isNotEmpty) context.writeln('Topic: $topic');
    if (className.isNotEmpty) context.writeln('Class: $className');
    if (subject.isNotEmpty) context.writeln('Subject: $subject');

    return _chatWithHistory(
      systemPrompt:
          'You are EduFrame AI, a practical lesson-planning assistant for Indian school teachers. '
          'Help with lesson flow, homework, differentiation, and explaining topics clearly. '
          'Support follow-up questions and revisions to your previous answers. '
          'Keep suggestions realistic for classrooms with limited resources.\n'
          '${context.isNotEmpty ? 'Current lesson context:\n$context' : ''}',
      messages: messages,
      maxTokens: 1200,
    );
  }

  Future<String> structureLessonPlanFromChat({
    required List<Map<String, String>> messages,
    required String topic,
    required String className,
    required String subject,
  }) {
    final context = StringBuffer();
    if (topic.isNotEmpty) context.writeln('Topic: $topic');
    if (className.isNotEmpty) context.writeln('Class: $className');
    if (subject.isNotEmpty) context.writeln('Subject: $subject');

    return _chatWithHistory(
      systemPrompt:
          'You extract the final lesson plan from a teacher-AI conversation. '
          'Include all revisions from follow-up messages. Be practical for Indian classrooms.\n'
          '${context.isNotEmpty ? 'Lesson context:\n$context' : ''}',
      messages: [
        ...messages,
        {
          'role': 'user',
          'content':
              'Based on our full conversation above, output the complete final lesson plan now. '
              'Use exactly these section headings on their own lines:\n'
              'OBJECTIVES:\nMATERIALS:\nACTIVITIES:\nHOMEWORK:\nTEACHER NOTES:',
        },
      ],
      maxTokens: 1200,
    );
  }

  Future<String> improveLessonPlan({
    required String topic,
    required String className,
    required String subject,
    required String objectives,
    required String materials,
    required String activities,
    required String homework,
    required String notes,
  }) {
    return _chat(
      'You are an experienced school teacher assistant. Improve teacher-written lesson plans. '
      'Keep the teacher\'s intent. Be practical for Indian classrooms. Use clear bullet points. '
      'Do not invent unrealistic activities. No fluff. Always fill every section.',
      '''
Topic: $topic
Class: $className
Subject: $subject

Current objectives:
$objectives

Current materials:
$materials

Current activities:
$activities

Current homework:
$homework

Current teacher notes:
$notes

Improve all five sections. Return exactly with these headings:
OBJECTIVES:
MATERIALS:
ACTIVITIES:
HOMEWORK:
TEACHER NOTES:
''',
    );
  }

  Future<String> suggestHomework({
    required String topic,
    required String className,
    required String subject,
  }) {
    return _chat(
      'You suggest realistic homework for school teachers in India. Short, specific, textbook-friendly.',
      'Suggest homework for $className ($subject) on topic: $topic. '
      'Give 2-3 options with exercise style wording teachers can copy.',
    );
  }

  Future<String> suggestActivities({
    required String topic,
    required String className,
    required String subject,
  }) {
    return _chat(
      'You suggest practical classroom activities for Indian schools. Low-cost, no fancy tech required. '
      'Structure your response with these headings when possible: OBJECTIVES:, ACTIVITIES:, MATERIALS:, HOMEWORK:, TEACHER NOTES:',
      'Suggest a 40-minute lesson flow for $className ($subject), topic: $topic. '
      'Include warm-up, teaching, practice, and wrap-up. List materials needed.',
    );
  }

  Future<String> differentiationTips({
    required String topic,
    required String className,
  }) {
    return _chat(
      'You help teachers support both struggling and advanced students. Be concise and actionable.',
      'Give differentiation tips for $className on topic: $topic. '
      'Split into: Struggling learners / Advanced learners / Quick checks.',
    );
  }

  Future<String> explainTopicSimply({
    required String topic,
    required String className,
    required String subject,
  }) {
    return _chat(
      'Explain topics simply so teachers can teach clearly the next day.',
      'Explain how to teach "$topic" to $className ($subject) in simple language. '
      'Include one analogy and common student mistakes.',
    );
  }
}
