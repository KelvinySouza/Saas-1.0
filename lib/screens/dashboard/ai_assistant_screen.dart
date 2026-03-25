import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// URL base da API Node (`server.js`). Android emulador: use `http://10.0.2.2:3000`.
/// Ex.: `flutter run --dart-define=AI_BACKEND_URL=http://127.0.0.1:3000`
const String _kAiBackendFromEnv = String.fromEnvironment('AI_BACKEND_URL');

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  static const int _maxPromptLength = 12000;

  /// Links de ajuda (HTTPS oficiais).
  static final Uri _urlSupabaseFlutterDocs = Uri.parse(
    'https://supabase.com/docs/guides/getting-started/quickstarts/flutter',
  );
  static final Uri _urlDartDefineDocs = Uri.parse(
    'https://docs.flutter.dev/deployment/flavors#using---dart-define',
  );
  static final Uri _urlOpenAiApi = Uri.parse(
    'https://platform.openai.com/docs/api-reference',
  );

  final _controller = TextEditingController();
  bool _loading = false;
  final List<Map<String, String>> _messages = [];

  String get _apiBaseUrl {
    final configured = _kAiBackendFromEnv.trim();
    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/+$'), '');
    }
    // Mesmo host do `server.js` (PORT 3000). Web + CORS em dev aceita origem do Flutter.
    return 'http://127.0.0.1:3000';
  }

  bool _isAllowedApiBase(String base) {
    final uri = Uri.tryParse(base);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  Future<void> _openUrl(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir: $uri')),
        );
      }
    }
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is String && err.isNotEmpty) return err;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _sendPrompt() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    if (prompt.length > _maxPromptLength) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Texto muito longo. Reduza a pergunta.'),
          ),
        );
      }
      return;
    }

    final base = _apiBaseUrl;
    if (!_isAllowedApiBase(base)) {
      setState(() {
        _messages.add({'role': 'user', 'text': prompt});
        _messages.add({
          'role': 'assistant',
          'text':
              'URL da API inválida. Use http(s) e defina AI_BACKEND_URL só com --dart-define.',
        });
        _controller.clear();
      });
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'text': prompt});
      _loading = true;
      _controller.clear();
    });

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      setState(() {
        _messages.add({
          'role': 'system',
          'text': 'Sessão expirada ou usuário não autenticado.',
        });
        _loading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$base/api/ai');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        final msg = _extractErrorMessage(response.body) ??
            'Não foi possível obter resposta.';
        setState(() {
          _messages.add({'role': 'assistant', 'text': msg});
        });
        return;
      }

      Map<String, dynamic>? data;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': 'Resposta inválida do servidor.',
          });
        });
        return;
      }

      final answer = data?['answer'] as String? ?? 'Sem resposta.';
      setState(() {
        _messages.add({'role': 'assistant', 'text': answer});
      });
    } on http.ClientException catch (e, st) {
      if (kDebugMode) {
        debugPrint('AI request network error: $e\n$st');
      }
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text':
              'Sem conexão com a API. Confira se o servidor está em execução (porta 3000) e se AI_BACKEND_URL está correto no emulador (ex.: http://10.0.2.2:3000).',
        });
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AI request failed: $e\n$st');
      }
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text':
              'Não foi possível concluir o pedido. Tente novamente em instantes.',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente IA'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API: $_apiBaseUrl',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_kAiBackendFromEnv.isEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Padrão: 127.0.0.1:3000 (servidor local). Personalize com --dart-define=AI_BACKEND_URL=...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () => _openUrl(_urlSupabaseFlutterDocs),
                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                        label: const Text('Supabase + Flutter'),
                      ),
                      TextButton.icon(
                        onPressed: () => _openUrl(_urlDartDefineDocs),
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('--dart-define'),
                      ),
                      TextButton.icon(
                        onPressed: () => _openUrl(_urlOpenAiApi),
                        icon: const Icon(Icons.cloud_outlined, size: 18),
                        label: const Text('OpenAI (backend)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(m['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Pergunte algo para o assistente...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendPrompt(),
                  ),
                ),
                _loading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendPrompt,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
