// AI provider client — the single swap point for the vision/learning AI calls.
//
// Currently Kimi (Moonshot), which is OpenAI-compatible (POST /chat/completions,
// Bearer auth, same message shape). To swap providers, change the three
// constants below and the env key name — nothing in the feature code changes.
//
// Verify against the current Kimi docs:
//   - base URL: https://api.moonshot.ai/v1  (global; .cn is the China endpoint)
//   - model:    kimi-k3 (must be a vision-capable model for image analysis)
// If Kimi rejects the model or vision, change kAiModel here only.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String kAiBaseUrl = 'https://api.moonshot.ai/v1';
const String kAiModel = 'kimi-k3';

// Read at build time from env.json via --dart-define-from-file.
const String _kAiApiKey = String.fromEnvironment('KIMI_API_KEY');

/// Result of an AI call: either [content] (success) or an Arabic [error].
class AiResult {
  const AiResult._(this.content, this.error);
  factory AiResult.success(String content) => AiResult._(content, null);
  factory AiResult.failure(String error) => AiResult._(null, error);

  final String? content;
  final String? error;

  bool get ok => content != null;
}

/// OpenAI-compatible chat completion against the configured provider. Handles
/// the failure states (missing key, HTTP error, empty response, network error)
/// and returns Arabic error messages — never throws.
Future<AiResult> aiChatCompletion({
  required List<Map<String, dynamic>> messages,
  int maxTokens = 800,
}) async {
  // Diagnostics: key presence/length (never the key itself) + endpoint/model.
  debugPrint('🤖 Kimi key exists: ${_kAiApiKey.isNotEmpty} '
      '(len=${_kAiApiKey.length}) model=$kAiModel base=$kAiBaseUrl');

  if (_kAiApiKey.isEmpty) {
    return AiResult.failure(
        'خطأ: مفتاح KIMI_API_KEY غير موجود. أضِفه في env.json ثم أعد تشغيل التطبيق.');
  }

  http.Response response;
  try {
    response = await http.post(
      Uri.parse('$kAiBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_kAiApiKey',
      },
      body: jsonEncode({
        'model': kAiModel,
        'messages': messages,
        'max_tokens': maxTokens,
      }),
    );
  } catch (e) {
    debugPrint('❌ Kimi network error: $e');
    return AiResult.failure(
        'تعذّر الاتصال بالإنترنت. تحقّق من الشبكة وحاول مجدداً. ($e)');
  }

  // Always log the status + raw body so the exact failure is visible.
  final rawBody = utf8.decode(response.bodyBytes, allowMalformed: true);
  debugPrint('🤖 Kimi HTTP ${response.statusCode} body: $rawBody');

  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(rawBody);
      final content =
          data['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return AiResult.failure(
            'لم يصل رد من المساعد الذكي (200 بجسم غير متوقع). حاول مرة أخرى.');
      }
      return AiResult.success(content);
    } catch (e) {
      debugPrint('❌ Kimi 200 parse error: $e');
      return AiResult.failure('تعذّر قراءة رد المساعد الذكي (200).');
    }
  }

  // Non-200: surface the provider's message + status number on screen.
  String detail;
  try {
    final err = jsonDecode(rawBody);
    detail = (err['error']?['message'] ?? err['message'] ?? err['error'])
            ?.toString() ??
        rawBody;
  } catch (_) {
    detail = rawBody.isEmpty ? 'لا يوجد تفصيل' : rawBody;
  }
  if (detail.length > 200) detail = '${detail.substring(0, 200)}…';
  return AiResult.failure(
      'تعذّر الاتصال بالمساعد الذكي (${response.statusCode}): $detail');
}
