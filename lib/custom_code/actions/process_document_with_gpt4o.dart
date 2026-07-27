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
import '/services/adaptive_prompts.dart';
import '/student/student_profile.dart';

// Document processing via the swappable AI provider (currently Kimi/Moonshot).
// Name kept for the existing callers; provider config lives in ai_client.dart.
//
// The old hardcoded per-action instruction ("لخص هذا في 5-7 نقاط...", always
// the same regardless of student) is replaced by the adaptive system prompt,
// which already fully specifies format per action + support level — keeping
// both would conflict (e.g. a light-support "تلخيص" wants one short
// paragraph, but the old text always demanded bullet points). The user
// message now just states the action and hands over the document text.
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

  final action = switch (mode) {
    'summarize' => LearningAction.summarize,
    'simplify' => LearningAction.simplify,
    'quiz' => LearningAction.reviewQuestions,
    _ => LearningAction.summarize,
  };

  final systemPrompt = buildLearningPrompt(StudentProfile.current, action);
  final userMessage =
      'الإجراء المطلوب: ${action.arabicLabel}\n\nالمحتوى:\n$text';

  final result = await aiChatCompletion(
    maxTokens: 800,
    messages: withAdaptiveSystemPrompt(systemPrompt, [
      {'role': 'user', 'content': userMessage},
    ]),
  );

  return result.ok ? result.content! : result.error!;
}
