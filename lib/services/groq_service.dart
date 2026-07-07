import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

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

  Future<String> _chat(String systemPrompt, String userPrompt) async {
    if (_proxyUrl.trim().isNotEmpty) {
      return _chatViaProxy(systemPrompt, userPrompt);
    }
    return _chatDirect(systemPrompt, userPrompt);
  }

  Future<String> _chatViaProxy(String systemPrompt, String userPrompt) async {
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
        'user': userPrompt,
        'model': _model,
        'max_tokens': 900,
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

  Future<String> _chatDirect(String systemPrompt, String userPrompt) async {
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
        'max_tokens': 900,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
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

  Future<String> improveLessonPlan({
    required String topic,
    required String className,
    required String subject,
    required String objectives,
    required String activities,
    required String homework,
  }) {
    return _chat(
      'You are an experienced school teacher assistant. Improve teacher-written lesson plans. '
      'Keep the teacher\'s intent. Be practical for Indian classrooms. Use clear bullet points. '
      'Do not invent unrealistic activities. No fluff.',
      '''
Topic: $topic
Class: $className
Subject: $subject

Current objectives:
$objectives

Current activities:
$activities

Current homework:
$homework

Improve these three sections. Return with headings:
OBJECTIVES:
ACTIVITIES:
HOMEWORK:
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
      'You suggest practical classroom activities for Indian schools. Low-cost, no fancy tech required.',
      'Suggest a 40-minute lesson flow for $className ($subject), topic: $topic. '
      'Include warm-up, teaching, practice, and wrap-up.',
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
