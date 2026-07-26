// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:syncfusion_flutter_pdf/pdf.dart';
import '/services/ai_client.dart';

// Document processing via the swappable AI provider (currently Kimi/Moonshot).
// Name kept for the existing callers; provider config lives in ai_client.dart.
Future<String> processDocumentWithGpt4o({
  Uint8List? fileBytes,
  required String mode, // 'summarize' | 'simplify' | 'quiz'
}) async {
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

  final result = await aiChatCompletion(
    maxTokens: 800,
    messages: [
      {
        'role': 'system',
        'content':
            'أنت مساعد تعليمي متخصص في دعم الطلاب ذوي صعوبات التعلم. ردودك دائماً بالعربية.',
      },
      {'role': 'user', 'content': prompt},
    ],
  );

  return result.ok ? result.content! : result.error!;
}
