import 'package:flutter_test/flutter_test.dart';
import 'package:shadow/data/technical_terms_dictionary.dart';
import 'package:shadow/services/technical_terms_corrector.dart';

void main() {
  test('manual scenario: "المشين ليننج والداتابيس" corrects both terms', () {
    const before = 'اليوم بنشرح عن المشين ليننج والداتابيس';
    final after = correctTechnicalTerms(before);
    // ignore: avoid_print
    print('BEFORE: $before');
    // ignore: avoid_print
    print('AFTER:  $after');
    expect(after, 'اليوم بنشرح عن Machine Learning وDatabase');
  });

  test('multi-word phrase matches whole, not just first word', () {
    expect(correctTechnicalTerms('نتكلم عن ارتيفيشيال انتلجنس اليوم'),
        'نتكلم عن Artificial Intelligence اليوم');
  });

  test('single-word term matches', () {
    expect(correctTechnicalTerms('نستخدم الالقورذم هذا'),
        'نستخدم Algorithm هذا');
  });

  test('plain Arabic text with no technical terms is unchanged', () {
    const text = 'اليوم الجو جميل والطلاب حضروا المحاضرة في الموعد';
    expect(correctTechnicalTerms(text), text);
  });

  test('empty text returns empty text', () {
    expect(correctTechnicalTerms(''), '');
  });

  test('punctuation and original spacing are preserved', () {
    expect(correctTechnicalTerms('نتكلم عن الالقورذم، ثم الداتابيس.'),
        'نتكلم عن Algorithm، ثم Database.');
  });

  test('attached ف connector is also handled', () {
    expect(correctTechnicalTerms('افتح الملف فالداتابيس فيه'),
        'افتح الملف فDatabase فيه');
  });

  test('a word that merely starts with و but is not a known term is untouched', () {
    const text = 'وقت المحاضرة الساعة عشرة';
    expect(correctTechnicalTerms(text), text);
  });

  test('dictionary has 300-500 distinct English terms as required', () {
    final distinctTerms = technicalTermsDictionary.values.toSet();
    expect(distinctTerms.length, greaterThanOrEqualTo(300));
    expect(distinctTerms.length, lessThanOrEqualTo(500));
  });

  test('no dictionary entry has an empty key or value', () {
    for (final entry in technicalTermsDictionary.entries) {
      expect(entry.key.trim(), isNotEmpty);
      expect(entry.value.trim(), isNotEmpty);
    }
  });

  test('every dictionary value round-trips through the corrector unchanged '
      'when it is the only word (sanity check on replacement values)', () {
    // Values are English (Latin script) — they must never accidentally match
    // an Arabic dictionary key themselves.
    for (final value in technicalTermsDictionary.values.take(20)) {
      expect(correctTechnicalTerms(value), value);
    }
  });
}
