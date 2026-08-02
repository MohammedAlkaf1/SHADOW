// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import '/services/ai_client.dart';
import '/services/adaptive_prompts.dart';
import '/services/platform_client.dart';
import '/student/student_profile.dart';

// Vision analysis via the swappable AI provider (currently Kimi/Moonshot).
// Name kept for the existing callers; provider config lives in ai_client.dart.
//
// The describe/read_text choice (what to do) stays a plain user-message
// instruction, unchanged; the adaptive system prompt (how to say it — style
// for the active StudentProfile) is layered on top via withAdaptiveSystemPrompt.
Future<String> analyzeImageWithGpt4o({
  required Uint8List imageBytes,
  required String mode, // 'describe' | 'read_text'
}) async {
  final base64Image = base64Encode(imageBytes);

  final prompt = mode == 'read_text'
      ? 'اقرأ واستخرج كل النصوص الموجودة في الصورة. قدم النص كما هو دون تعليق إضافي.'
      : 'صف ما تراه في هذه الصورة بشكل تفصيلي باللغة العربية. ركز على الأشياء والأشخاص والبيئة المحيطة.';

  final systemPrompt = buildVisionPrompt(StudentProfile.current);

  final result = await aiChatCompletion(
    maxTokens: 600,
    messages: withAdaptiveSystemPrompt(systemPrompt, [
      {
        'role': 'user',
        'content': [
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,$base64Image',
              'detail': 'high',
            },
          },
          {
            'type': 'text',
            'text': prompt,
          },
        ],
      },
    ]),
  );

  if (!result.ok) {
    // Abstract metadata only — provider + a short error-type label, never
    // the request/response content itself.
    PlatformClient.queueUsageEvent('provider_error',
        payload: {'provider': 'gemini', 'errorType': 'vision_analysis_failed'});
  }
  return result.ok ? result.content! : result.error!;
}
