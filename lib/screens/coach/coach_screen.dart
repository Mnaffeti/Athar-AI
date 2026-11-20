import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_theme.dart';

class _Message {
  const _Message(this.text, {required this.fromUser});

  final String text;
  final bool fromUser;
}

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key, required this.name});

  final String name;

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  late final List<_Message> _messages = [
    _Message(
      "Hey ${widget.name} 👋 I'm your Athar coach. You're 12 days into your "
      'streak and screen time is down 35% this week. What do you want to work on?',
      fromUser: false,
    ),
  ];

  bool _typing = false;

  static const _suggestions = [
    'I keep opening TikTok',
    'Motivate me for the gym',
    'Plan a phone-free evening',
  ];

  // La clé est transmise à la compilation via --dart-define-from-file=env.json.
  static const _groqApiKey = String.fromEnvironment('GROQ_API_KEY');

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _fetchGroqReply(String userPrompt) async {
    if (_groqApiKey.isEmpty) {
      return 'Erreur : GROQ_API_KEY est introuvable. '
          'Vérifie le fichier env.json et les options de lancement.';
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'qwen/qwen3.8-27b',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are Athar Coach, a friendly, concise productivity and '
                  'wellness AI coach helping the user reduce screen time, avoid '
                  'mindless scrolling, and stay motivated for the gym.',
            },
            {
              'role': 'user',
              'content': userPrompt,
            },
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Groq API error ${response.statusCode}: ${response.body}',
        );
        return 'Le coach ne peut pas répondre pour le moment. '
            'Réessaie dans quelques instants.';
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>;
      final content = message['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        return 'Je n’ai pas reçu de réponse. Essaie à nouveau.';
      }

      return content.trim();
    } catch (e) {
      debugPrint('Groq request failed: $e');
      return 'Erreur de connexion. Vérifie ta connexion et réessaie.';
    }
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _typing) return;

    _controller.clear();

    setState(() {
      _messages.add(_Message(trimmed, fromUser: true));
      _typing = true;
    });

    _scrollToBottom();

    final reply = await _fetchGroqReply(trimmed);

    if (!mounted) return;

    setState(() {
      _messages.add(_Message(reply, fromUser: false));
      _typing = false;
    });

    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.brandNavy,
                  child: Image(
                    image: AssetImage('assets/images/logo_mark.png'),
                    height: 20,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Athar Coach',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Online',
                      style: TextStyle(fontSize: 12, color: AppColors.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const _Bubble.typing();
                }
                return _Bubble(message: _messages[i]);
              },
            ),
          ),
          if (_messages.length == 1)
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ActionChip(
                  label: Text(_suggestions[i]),
                  onPressed: () => _send(_suggestions[i]),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: const InputDecoration(
                      hintText: 'Ask your coach…',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => _send(_controller.text),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    fixedSize: const Size(52, 52),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message}) : typing = false;

  const _Bubble.typing()
      : message = null,
        typing = true;

  final _Message? message;
  final bool typing;

  @override
  Widget build(BuildContext context) {
    final fromUser = message?.fromUser ?? false;

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: fromUser ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(fromUser ? 18 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 18),
          ),
          border: fromUser ? null : Border.all(color: AppColors.border),
        ),
        child: typing
            ? const Text('•••', style: TextStyle(color: AppColors.textMuted))
            : Text(
                message!.text,
                style: TextStyle(
                  height: 1.4,
                  color: fromUser ? AppColors.onAccent : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}
