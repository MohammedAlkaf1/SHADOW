// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/services/ai_client.dart';

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
  final result = await aiChatCompletion(
    maxTokens: 400,
    messages: [
      {
        'role': 'system',
        'content':
            'أنت مساعد تنقل ذكي للطلاب ذوي الإعاقة الحركية في الحرم الجامعي. '
                'اعتمد على المعلومات التالية للإجابة:\n$_campusContext\n'
                'أجب بإيجاز وبوضوح باللغة العربية. إذا لم تعرف الإجابة، اقترح التواصل مع إدارة الجامعة.',
      },
      {'role': 'user', 'content': question},
    ],
  );

  return result.ok ? result.content! : result.error!;
}
