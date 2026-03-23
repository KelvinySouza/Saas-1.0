import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  final List<Map<String, String>> _messages = [];

  String get _apiBaseUrl {
    if (kIsWeb) {
      // Para web, use o backend hospedado (ex: Vercel, Heroku)
      return 'https://seu-backend-hospedado.com'; // Substitua pela URL real
    } else {
      // Para mobile/desktop, use localhost
      return 'http://localhost:3000';
    }
  }

  Future<void> _sendPrompt() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': prompt});
      _loading = true;
      _controller.clear();
    });

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      setState(() {
        _messages.add({'role': 'system', 'text': 'Usuário não autenticado.'});
        _loading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/api/ai');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro desconhecido');
      }

      final data = jsonDecode(response.body);
      final answer = data['answer'] ?? 'Sem resposta';
      setState(() {
        _messages.add({'role': 'assistant', 'text': answer});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Falha ao chamar IA: ${e.toString()}'});
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente IA'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m['text'] ?? ''),
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
                    onSubmitted: (_) => _sendPrompt(),
                  ),
                ),
                _loading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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