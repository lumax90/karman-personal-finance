import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subscription_tier.dart';

class AiMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;

  const AiMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, String> toApiMap() => {'role': role, 'content': content};
}

class AiService {
  static Future<String> chat({
    required AiModel model,
    required String apiKey,
    required List<AiMessage> messages,
    String? systemPrompt,
  }) async {
    if (apiKey.isEmpty) {
      throw AiServiceException('API key is required');
    }

    switch (model) {
      case AiModel.grok:
        return _chatOpenAiCompatible(
          baseUrl: model.apiBaseUrl,
          modelId: model.defaultModelId,
          apiKey: apiKey,
          messages: messages,
          systemPrompt: systemPrompt,
        );
      case AiModel.openai:
        return _chatOpenAiCompatible(
          baseUrl: model.apiBaseUrl,
          modelId: model.defaultModelId,
          apiKey: apiKey,
          messages: messages,
          systemPrompt: systemPrompt,
        );
      case AiModel.gemini:
        return _chatGemini(
          apiKey: apiKey,
          modelId: model.defaultModelId,
          messages: messages,
          systemPrompt: systemPrompt,
        );
    }
  }

  /// OpenAI-compatible API (works for OpenAI and Grok/xAI)
  static Future<String> _chatOpenAiCompatible({
    required String baseUrl,
    required String modelId,
    required String apiKey,
    required List<AiMessage> messages,
    String? systemPrompt,
  }) async {
    final apiMessages = <Map<String, String>>[];

    if (systemPrompt != null) {
      apiMessages.add({'role': 'system', 'content': systemPrompt});
    }

    for (final msg in messages) {
      apiMessages.add(msg.toApiMap());
    }

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': modelId,
        'messages': apiMessages,
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw AiServiceException('API Error (${response.statusCode}): $error');
    }

    final data = jsonDecode(response.body);
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw AiServiceException('Empty response from API');
    }

    return choices[0]['message']['content'] as String;
  }

  /// Google Gemini API
  static Future<String> _chatGemini({
    required String apiKey,
    required String modelId,
    required List<AiMessage> messages,
    String? systemPrompt,
  }) async {
    final contents = <Map<String, dynamic>>[];

    for (final msg in messages) {
      contents.add({
        'role': msg.role == 'assistant' ? 'model' : 'user',
        'parts': [{'text': msg.content}],
      });
    }

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };

    if (systemPrompt != null) {
      body['systemInstruction'] = {
        'parts': [{'text': systemPrompt}],
      };
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw AiServiceException('Gemini Error (${response.statusCode}): $error');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw AiServiceException('Empty response from Gemini');
    }

    final parts = candidates[0]['content']['parts'] as List;
    return parts.map((p) => p['text']).join('');
  }

  static String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data['error']?['message'] ?? data['error']?.toString() ?? body;
    } catch (_) {
      return body.length > 200 ? body.substring(0, 200) : body;
    }
  }
}

class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);

  @override
  String toString() => message;
}
