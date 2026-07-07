import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../models/models.dart';
import '../models/plan_draft.dart';
import '../services/database_service.dart';
import '../services/groq_service.dart';
import '../utils/ai_result_parser.dart';
import '../utils/class_display.dart';
import '../widgets/ai_message_body.dart';
import 'plan_new_screen.dart';

enum _AiTool { activities, homework, differentiation, explain }

class AiAssistScreen extends StatefulWidget {
  const AiAssistScreen({super.key});

  @override
  State<AiAssistScreen> createState() => _AiAssistScreenState();
}

class _AiAssistScreenState extends State<AiAssistScreen> {
  final _topicController = TextEditingController();
  final _classController = TextEditingController();
  final _subjectController = TextEditingController();
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  List<TeachingClass> _classes = [];
  final List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _contextExpanded = true;
  _AiTool? _lastTool;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _classController.dispose();
    _subjectController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final classes = await DatabaseService.instance.getAllClasses();
    if (mounted) setState(() => _classes = classes);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  List<Map<String, String>> _historyForApi() {
    return _messages
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();
  }

  Future<void> _sendMessage(String text, {_AiTool? tool}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;

    if (tool != null) _lastTool = tool;

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: trimmed));
      _loading = true;
    });
    _chatController.clear();
    _scrollToBottom();

    try {
      final response = await GroqService.instance.aiAssistChat(
        messages: _historyForApi(),
        topic: _topicController.text.trim(),
        className: _classController.text.trim(),
        subject: _subjectController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(isUser: false, text: response));
      });
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _lastTool = null;
    });
  }

  String _classLabel() {
    final value = _classController.text.trim();
    return value.isEmpty ? 'Class' : value;
  }

  String _subjectLabel() {
    final value = _subjectController.text.trim();
    return value.isEmpty ? 'Subject' : value;
  }

  void _quickAction(_AiTool tool, String prompt) {
    if (_topicController.text.trim().isEmpty) {
      _snack(context.strings.aiTopicRequired);
      return;
    }
    _sendMessage(prompt, tool: tool);
  }

  int? _matchClassId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();

    for (final cls in _classes) {
      final label = teachingClassLabel(cls).toLowerCase();
      if (label == lower) return cls.id;
      if (cls.name.toLowerCase() == lower) return cls.id;

      final section = cls.section.trim();
      if (section.isNotEmpty) {
        final variants = [
          '${cls.name}-$section',
          '${cls.name} $section',
          '${cls.name}-sec $section',
          '${cls.name} · sec $section',
          formatClassLabel(cls.name, section),
        ];
        for (final variant in variants) {
          if (variant.toLowerCase() == lower) return cls.id;
        }
      }
    }
    return null;
  }

  String? _lastAssistantText() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].isUser) return _messages[i].text;
    }
    return null;
  }

  PlanDraft _buildDraftFromChat() {
    final result = _lastAssistantText() ?? '';
    final parsed = AiResultParser.parse(result);
    final topic = _topicController.text.trim();
    final className = _classController.text.trim();
    final subject = _subjectController.text.trim();

    var objectives = parsed.objectives;
    var materials = parsed.materials;
    var activities = parsed.activities;
    var homework = parsed.homework;
    var notes = parsed.notes;

    if (!parsed.hasStructuredContent && _lastTool == _AiTool.activities) {
      activities = result;
    }

    final extraNotes = <String>[
      if (subject.isNotEmpty) 'Subject: $subject',
      if (className.isNotEmpty && _matchClassId(className) == null) 'Class: $className',
    ];
    if (extraNotes.isNotEmpty) {
      final prefix = extraNotes.join('\n');
      notes = notes.isEmpty ? prefix : '$prefix\n\n$notes';
    }

    return PlanDraft(
      classId: _matchClassId(className),
      topic: topic,
      objectives: objectives,
      materials: materials,
      activities: activities,
      homework: homework,
      notes: notes,
    );
  }

  Future<void> _createPlanWithAi() async {
    if (_lastAssistantText() == null) return;
    final draft = _buildDraftFromChat();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanNewScreen(draft: draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final palette = AppPalette.of(context);
    final topic = _topicController.text.trim();
    final className = _classLabel();
    final subject = _subjectLabel();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.aiTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (_messages.isNotEmpty)
                IconButton(
                  tooltip: s.aiClearChat,
                  onPressed: _loading ? null : _clearChat,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ),
        _contextCard(s, palette),
        if (_messages.isEmpty) _quickActions(s, palette, topic, className, subject),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: (_messages.isEmpty ? 1 : _messages.length) + (_loading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_messages.isEmpty) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      s.aiChatWelcome,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.textMuted, height: 1.5),
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (index < _messages.length) {
                return _messageBubble(_messages[index], palette);
              }

              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
        if (_lastTool == _AiTool.activities && _lastAssistantText() != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createPlanWithAi,
                icon: const Icon(Icons.note_add_outlined),
                label: Text(s.createPlanWithAi),
              ),
            ),
          ),
        _chatInputBar(s, palette),
        ],
      ),
    );
  }

  Widget _contextCard(AppStrings s, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Column(
          children: [
            ListTile(
              dense: true,
              title: Text(s.aiLessonContext, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: Icon(_contextExpanded ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _contextExpanded = !_contextExpanded),
            ),
            if (_contextExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _topicController,
                      decoration: InputDecoration(
                        labelText: s.aiTopicLabel,
                        hintText: s.aiTopicHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _classController,
                      decoration: InputDecoration(
                        labelText: s.aiClassLabel,
                        hintText: s.aiClassHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: s.aiSubjectLabel,
                        hintText: s.aiSubjectHint,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(
    AppStrings s,
    AppPalette palette,
    String topic,
    String className,
    String subject,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _quickChip(
            s.aiQuickActivities,
            Icons.lightbulb_outline,
            () => _quickAction(
              _AiTool.activities,
              'Suggest a 40-minute lesson flow for $className ($subject) on topic: $topic. '
              'Include warm-up, teaching, practice, wrap-up, materials, homework, and teacher notes.',
            ),
          ),
          _quickChip(
            s.aiQuickHomework,
            Icons.assignment_outlined,
            () => _quickAction(
              _AiTool.homework,
              'Suggest homework for $className ($subject) on topic: $topic.',
            ),
          ),
          _quickChip(
            s.aiQuickDifferentiation,
            Icons.people_outline,
            () => _quickAction(
              _AiTool.differentiation,
              'Give differentiation tips for $className on topic: $topic.',
            ),
          ),
          _quickChip(
            s.aiQuickExplain,
            Icons.school_outlined,
            () => _quickAction(
              _AiTool.explain,
              'Explain how to teach "$topic" to $className ($subject) in simple language.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: _loading ? null : onTap,
      ),
    );
  }

  Widget _messageBubble(ChatMessage message, AppPalette palette) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        decoration: BoxDecoration(
          color: isUser ? palette.primary : palette.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: palette.border),
        ),
        child: isUser
            ? Text(
                message.text,
                style: const TextStyle(color: Colors.white, height: 1.45, fontSize: 15),
              )
            : AiMessageBody(text: message.text),
      ),
    );
  }

  Widget _chatInputBar(AppStrings s, AppPalette palette) {
    return Material(
      color: palette.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _loading ? null : _sendMessage,
                  decoration: InputDecoration(
                    hintText: s.aiChatHint,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _loading ? null : () => _sendMessage(_chatController.text),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
