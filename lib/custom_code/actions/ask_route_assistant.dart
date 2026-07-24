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

const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');

const _campusContext = '''
معلومات إمكانية الوصول في الحرم الجامعي - جامعة الملك سعود:
- كلية الهندسة: مسار مهيأ للكراسي المتحركة، مدخل جانبي مع منحدر متاح
- المكتبة المركزية: مدخل منحدر متاح من الجهة الشرقية، مصعد يعمل
- المطعم الجامعي: المصعد تحت الصيانة حالياً، يُنصح باستخدام المدخل الأرضي المباشر
- مواقف ذوي الاحتياجات الخاصة: بجانب المدخل الرئيسي وكليات العلوم والآداب
- دورات المياه المخصصة: في جميع المباني الرئيسية بالطابق الأرضي
- مطوعون للمساعدة: متاحون من خلال زر "طلب مساعد" في التطبيق
- المنحدرات: متوفرة عند جميع المداخل الرئيسية
''';

Future<String> askRouteAssistant({
  required String question,
}) async {
  if (_apiKey.isEmpty) {
    return 'خطأ: مفتاح OPENAI_API_KEY غير موجود.';
  }

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
              'أنت مساعد تنقل ذكي للطلاب ذوي الإعاقة الحركية في الحرم الجامعي. '
                  'اعتمد على المعلومات التالية للإجابة:\n$_campusContext\n'
                  'أجب بإيجاز وبوضوح باللغة العربية. إذا لم تعرف الإجابة، اقترح التواصل مع إدارة الجامعة.',
        },
        {'role': 'user', 'content': question},
      ],
      'max_tokens': 400,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'] as String;
  } else {
    return 'خطأ ${response.statusCode}: فشل الاتصال بـ GPT-4o';
  }
}
