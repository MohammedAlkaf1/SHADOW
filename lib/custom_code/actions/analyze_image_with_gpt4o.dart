// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:http/http.dart' as http;

// API key passed at build time via: flutter run --dart-define=OPENAI_API_KEY=sk-...
const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');

Future<String> analyzeImageWithGpt4o({
  required Uint8List imageBytes,
  required String mode, // 'describe' | 'read_text'
}) async {
  if (_apiKey.isEmpty) {
    return 'خطأ: مفتاح OPENAI_API_KEY غير موجود. يرجى تشغيل التطبيق بـ --dart-define=OPENAI_API_KEY=...';
  }

  final base64Image = base64Encode(imageBytes);

  final prompt = mode == 'read_text'
      ? 'اقرأ واستخرج كل النصوص الموجودة في الصورة. قدم النص كما هو دون تعليق إضافي.'
      : 'صف ما تراه في هذه الصورة بشكل تفصيلي باللغة العربية. ركز على الأشياء والأشخاص والبيئة المحيطة.';

  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    },
    body: jsonEncode({
      'model': 'gpt-4o',
      'messages': [
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
      ],
      'max_tokens': 600,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'] as String;
  } else {
    final error = jsonDecode(response.body);
    return 'خطأ ${response.statusCode}: ${error['error']?['message'] ?? 'فشل الاتصال'}';
  }
}
