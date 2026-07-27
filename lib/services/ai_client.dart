// AI provider client — the single swap point for the vision/learning AI calls.
//
// Currently Google Gemini. Gemini is NOT OpenAI-compatible, so this file keeps
// the same aiChatCompletion(messages:) interface the feature code already uses
// (OpenAI-style role/content messages) and translates it into Gemini's
// contents/parts request internally. To swap providers, change this file only.
//
// Verify against current Gemini docs:
//   - base URL: https://generativelanguage.googleapis.com/v1beta
//   - model:    gemini-2.5-flash (vision + text, free tier)
//   - endpoint: {base}/models/{model}:generateContent, auth via x-goog-api-key

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String kAiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
const String kAiModel = 'gemini-2.5-flash';

// Read at build time from env.json via --dart-define-from-file.
const String _kAiApiKey = String.fromEnvironment('GEMINI_API_KEY');

/// Prepares an adaptive system prompt and injects it into [messages], ready
/// for [aiChatCompletion]. Does not call Gemini and does not touch
/// [aiChatCompletion] itself — callers build [systemPrompt] dynamically from
/// the active StudentProfile (see lib/services/adaptive_prompts.dart) and
/// pass it here. Any existing 'system' message in [messages] is replaced
/// (callers should not pass one; the adaptive prompt is the single source of
/// system-level instruction).
List<Map<String, dynamic>> withAdaptiveSystemPrompt(
  String systemPrompt,
  List<Map<String, dynamic>> messages,
) {
  return [
    {'role': 'system', 'content': systemPrompt},
    ...messages.where((m) => m['role'] != 'system'),
  ];
}

/// Result of an AI call: either [content] (success) or an Arabic [error].
class AiResult {
  const AiResult._(this.content, this.error);
  factory AiResult.success(String content) => AiResult._(content, null);
  factory AiResult.failure(String error) => AiResult._(null, error);

  final String? content;
  final String? error;

  bool get ok => content != null;
}

/// Chat completion against Gemini. Accepts OpenAI-style [messages] (role +
/// content, where content is a String or a list of {type:text|image_url}
/// parts) so callers don't change. Handles every failure state with Arabic
/// error messages — never throws.
Future<AiResult> aiChatCompletion({
  required List<Map<String, dynamic>> messages,
  int maxTokens = 800,
}) async {
  // Diagnostics: key presence/length (never the key itself) + endpoint/model.
  debugPrint('🤖 Gemini key exists: ${_kAiApiKey.isNotEmpty} '
      '(len=${_kAiApiKey.length}) model=$kAiModel base=$kAiBaseUrl');

  if (_kAiApiKey.isEmpty) {
    return AiResult.failure(
        'خطأ: مفتاح GEMINI_API_KEY غير موجود. أضِفه في env.json ثم أعد تشغيل التطبيق.');
  }

  final requestBody = _toGeminiRequest(messages, maxTokens);

  http.Response response;
  try {
    response = await http.post(
      Uri.parse('$kAiBaseUrl/models/$kAiModel:generateContent'),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _kAiApiKey,
      },
      body: jsonEncode(requestBody),
    );
  } catch (e) {
    debugPrint('❌ Gemini network error: $e');
    return AiResult.failure(
        'تعذّر الاتصال بالإنترنت. تحقّق من الشبكة وحاول مجدداً. ($e)');
  }

  // Always log the status + raw body so the exact failure is visible.
  final rawBody = utf8.decode(response.bodyBytes, allowMalformed: true);
  debugPrint('🤖 Gemini HTTP ${response.statusCode} body: $rawBody');

  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(rawBody);
      final content = _extractGeminiText(data);
      if (content == null || content.trim().isEmpty) {
        return AiResult.failure(
            'لم يصل رد من المساعد الذكي (قد يكون المحتوى محجوباً). حاول مرة أخرى.');
      }
      return AiResult.success(content);
    } catch (e) {
      debugPrint('❌ Gemini 200 parse error: $e');
      return AiResult.failure('تعذّر قراءة رد المساعد الذكي (200).');
    }
  }

  // Non-200: surface Gemini's message + status number on screen.
  String detail;
  try {
    final err = jsonDecode(rawBody);
    detail = (err['error']?['message'])?.toString() ?? rawBody;
  } catch (_) {
    detail = rawBody.isEmpty ? 'لا يوجد تفصيل' : rawBody;
  }
  if (detail.length > 200) detail = '${detail.substring(0, 200)}…';
  return AiResult.failure(
      'تعذّر الاتصال بالمساعد الذكي (${response.statusCode}): $detail');
}

/// Translates OpenAI-style messages into a Gemini generateContent request.
/// - `system` messages -> systemInstruction
/// - `assistant` role  -> Gemini "model" role, others -> "user"
/// - text parts -> {text}, image_url data-URIs -> {inline_data}
Map<String, dynamic> _toGeminiRequest(
    List<Map<String, dynamic>> messages, int maxTokens) {
  final systemParts = <Map<String, dynamic>>[];
  final contents = <Map<String, dynamic>>[];

  for (final msg in messages) {
    final role = msg['role'] as String?;
    final content = msg['content'];

    if (role == 'system') {
      if (content is String && content.isNotEmpty) {
        systemParts.add({'text': content});
      }
      continue;
    }

    final parts = <Map<String, dynamic>>[];
    if (content is String) {
      if (content.isNotEmpty) parts.add({'text': content});
    } else if (content is List) {
      for (final part in content) {
        if (part is! Map) continue;
        final type = part['type'];
        if (type == 'text') {
          parts.add({'text': part['text']});
        } else if (type == 'image_url') {
          final url = (part['image_url'] as Map?)?['url'] as String?;
          final inline = _dataUriToInline(url);
          if (inline != null) parts.add({'inline_data': inline});
        }
      }
    }

    if (parts.isNotEmpty) {
      contents.add({
        'role': role == 'assistant' ? 'model' : 'user',
        'parts': parts,
      });
    }
  }

  final body = <String, dynamic>{
    'contents': contents,
    'generationConfig': {
      'maxOutputTokens': maxTokens,
      // Disable "thinking" so gemini-2.5-flash returns direct output instead of
      // spending the token budget on reasoning (which can yield an empty reply).
      'thinkingConfig': {'thinkingBudget': 0},
    },
  };
  if (systemParts.isNotEmpty) {
    body['systemInstruction'] = {'parts': systemParts};
  }
  return body;
}

/// Parses a `data:<mime>;base64,<data>` URI into Gemini inline_data.
Map<String, dynamic>? _dataUriToInline(String? url) {
  if (url == null) return null;
  final match = RegExp(r'^data:(.+?);base64,(.*)$', dotAll: true).firstMatch(url);
  if (match == null) return null;
  return {'mime_type': match.group(1), 'data': match.group(2)};
}

/// Joins the text of all parts in the first Gemini candidate.
String? _extractGeminiText(dynamic data) {
  final candidates = data['candidates'];
  if (candidates is! List || candidates.isEmpty) return null;
  final parts = candidates.first?['content']?['parts'];
  if (parts is! List) return null;
  final buffer = StringBuffer();
  for (final part in parts) {
    final text = (part is Map) ? part['text'] : null;
    if (text is String) buffer.write(text);
  }
  return buffer.toString();
}
