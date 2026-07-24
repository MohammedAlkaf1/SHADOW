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
import 'package:syncfusion_flutter_pdf/pdf.dart';

const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');

Future<String> processDocumentWithGpt4o({
  Uint8List? fileBytes,
  required String mode, // 'summarize' | 'simplify' | 'quiz'
}) async {
  if (_apiKey.isEmpty) {
    return 'خطأ: مفتاح OPENAI_API_KEY غير موجود. يرجى تشغيل التطبيق بـ --dart-define=OPENAI_API_KEY=...';
  }

  if (fileBytes == null) {
    return 'يرجى اختيار ملف PDF أولاً';
  }
  final bytes = fileBytes;
  final document = PdfDocument(inputBytes: bytes);
  final extractedText = PdfTextExtractor(document).extractText();
  document.dispose();

  if (extractedText.trim().isEmpty) {
    return 'لم يتم العثور على نص قابل للقراءة في الملف.';
  }

  final text = extractedText.length > 8000
      ? extractedText.substring(0, 8000)
      : extractedText;

  final prompt = switch (mode) {
    'summarize' =>
      'لخص هذا المحتوى الأكاديمي في ٥-٧ نقاط رئيسية باللغة العربية:\n\n$text',
    'simplify' =>
      'اشرح هذا المحتوى بأسلوب مبسط ومناسب لطلاب ذوي صعوبات التعلم باللغة العربية. استخدم جملاً قصيرة ومثالاً واحداً لكل فكرة:\n\n$text',
    'quiz' =>
      'اقترح ٥ أسئلة مراجعة قصيرة مع إجاباتها بناءً على هذا المحتوى باللغة العربية:\n\n$text',
    _ => 'لخص هذا المحتوى باللغة العربية:\n\n$text',
  };

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
          'role': 'system',
          'content':
              'أنت مساعد تعليمي متخصص في دعم الطلاب ذوي صعوبات التعلم. ردودك دائماً بالعربية.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 800,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'] as String;
  } else {
    return 'خطأ ${response.statusCode}: فشل الاتصال بـ GPT-4o';
  }
}
